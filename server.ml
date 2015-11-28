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
  let open Instruction in
  let str_id = Cursor.string_of_id instruction.cursor in
  str_id ^ " -> " ^
  begin match instruction.op with
  | Add c -> "add " ^ (Char.escaped c)
  | Move dir -> "move " ^
    begin match dir with
    | Up -> "up"
    | Down -> "down"
    | Left -> "left"
    | Right -> "right" end
  | New -> "new" end ^ "\n"

let instruction_of_line line =
  let open Instruction in

  let info_list = Str.split (Str.regexp " -> ") line in
  match info_list with
  | [id; cmd] ->
      let id_str = Cursor.id_of_string id in
      let file_slot = failwith "What do with file initailization?" in
      begin match Str.split (Str.regexp " ") cmd with
      | ["add"; c] when String.length c = 1 -> {
            op = Add (String.get c 0);
            cursor = id_str;
            file = file_slot;
          }
      | ["move"; "up"] -> {
            op = Move Up;
            cursor = id_str;
            file = file_slot;
          }
      | ["move"; "down"] -> {
            op = Move Down;
            cursor = id_str;
            file = file_slot;
          }
      | ["move"; "left"] -> {
            op = Move Left;
            cursor = id_str;
            file = file_slot;
          }
      | ["move"; "right"] -> {
            op = Move Right;
            cursor = id_str;
            file = file_slot;
          }
      | ["new"; id2] -> {
            op = New;
            cursor = id_str;
            file = file_slot;
          }
      | _ -> failwith "badly formatted instruction" end
  | _ -> failwith "badly formatted instruction"

let send instruction =
  match !status with
  | Empty -> failwith "server/client not intialized"
  | Waiting_server -> failwith "server is not ready yet"
  | Waiting_client -> failwith "client is not ready yet"
  | _ ->
      let send w =
        let line = line_of_instruction instruction in
        Async.Std.Writer.write_line w line in
      List.iter send (!destinations);
      0

let rec client_loop reader =
  Reader.read_line reader >>= function
  | `Eof -> failwith "connection with host has ended"
  | `Ok str ->
      AQueue.push pending (instruction_of_line str);
      client_loop reader

let init_client addr port_num =
  if !status <> Empty then failwith "tried to init server/client twice" else
  let open Tcp in
  status := Waiting_client;
  connect(to_host_and_port addr port_num) >>= fun (socket, read, write) ->
  destinations := write :: (!destinations);
  ignore (client_loop read);
  status := Client;
  return 0

let rec server_loop reader =
  Reader.read_line reader >>= function
  | `Eof -> failwith "client disconnected, this handling is unimplemented"
  | `Ok str ->
      let instruction = instruction_of_line str in
      AQueue.push pending instruction;
      ignore (send instruction);
      server_loop reader

let init_server port collab_num =
  if !status <> Empty then failwith "tried to init server/client twice" else
  status := Waiting_server;
  let handle_new_connection _ r w =
    destinations := w :: (!destinations);
    server_loop r in
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

