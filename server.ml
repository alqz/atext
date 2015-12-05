open Async.Std

type stat =
  | Empty
  | Waiting_client
  | Waiting_server
  | Client
  | Server

(* Whether either server or client have been intialized *)
let status = ref Empty

(* A queue of incoming instructions pending to be processed by the editor *)
let pending = AQueue.create()

(*
 * client: destinations = [server writing buffer]
 * server: destinations = [client#1 writing buffer; client#2 writing buffer...]
 *)
let destinations = ref []

let line_of_instruction instruction =
  Yojson.Basic.to_string (Instruction.encode instruction)

let instruction_of_line line =
  Instruction.decode (Yojson.Basic.from_string line)

let string_of_json js = js |> Yojson.Basic.to_string |> Yojson.Basic.compact

let extract err = function
| `Eof -> failwith err
| `Ok str -> str

let send inst =
  match !status with
  | Empty -> failwith "server/client not intialized"
  | Waiting_server -> failwith "server is not ready yet"
  | Waiting_client -> failwith "client is not ready yet"
  | _ ->
      let send (_, w) =
        let line = line_of_instruction inst in
        Async.Std.Writer.write_line w line in
      List.iter send (!destinations);
      0

let rec client_loop addr reader =
  Reader.read_line reader >>= fun line ->
  let str = extract "connection with host has ended" line in
  AQueue.push pending (instruction_of_line str);
  client_loop addr reader

let init_client addr port_num =
  if !status <> Empty then failwith "tried to init server/client twice" else
  let open Tcp in
  status := Waiting_client;
  connect(to_host_and_port addr port_num) >>= fun (socket, read, write) ->
  destinations := (addr, write) :: (!destinations);
  Reader.read_line read >>= fun first ->
  let str_state = extract "connection with host was not established" first in
  let state = State.decode (Yojson.Basic.from_string str_state) in
  ignore (client_loop addr read);
  status := Client;
  return (state, 0)

let get_sender str_inst =
  let open Instruction in
  Cursor.string_of_id ((instruction_of_line str_inst).cursor)

let rec server_loop addr reader =
  let open Instruction in
  Reader.read_line reader >>= function
  | `Eof ->
      destinations := List.remove_assoc addr (!destinations);
      (* need to get file name to send Leave instruction *)
      let current_state =
        match Guardian.get_opened () with
          | Some st -> st
          | None -> failwith "could not get file" in
      let leave_inst = {
        op = Leave;
        cursor = Cursor.id_of_string addr;
        file = State.get_name current_state;
      } in
      ignore (send leave_inst);
      return ()
  | `Ok str ->
      let instruction = instruction_of_line str in
      AQueue.push pending instruction;
      ignore (send instruction);
      if instruction.op = New then
        let new_name = get_sender str in
        let new_matching = List.assoc addr (!destinations) in
        let new_list =
          (new_name, new_matching) :: List.remove_assoc addr (!destinations) in
        destinations := new_list;
        server_loop new_name reader
      else if instruction.op = Leave then begin
        destinations := List.remove_assoc addr (!destinations);
        return ()
      end else
        server_loop addr reader

let init_server port collab_num =
  if !status <> Empty then failwith "tried to init server/client twice" else
  status := Waiting_server;
  let handle_new_connection a r w =
    let addr = Socket.Address.Inet.to_string a in
    destinations := (addr, w) :: (!destinations);
    let st_json : Yojson.Basic.json = match Guardian.get_opened () with
      | None -> failwith "could not get file"
      | Some st -> st |> State.encode in
    Async.Std.Writer.write_line w (string_of_json st_json);
    server_loop addr r in
  let server =
    Async.Std.Tcp.Server.create
      ~max_connections:collab_num
      ~on_handler_error:`Raise
      (Async.Std.Tcp.on_port port)
      handle_new_connection in
  server >>= fun _ ->
  status := Server;
  return 0


let occumulated_instruction () =
  AQueue.pop pending

