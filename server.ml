open Async.Std

type client_info = {
  server  : string;
  port    : int;
  reader  : Async.Std.Reader.t;
  writer  : Async.Std.Writer.t;
}
type server_info = {
  port : int;
  mutable clients : (string * Async.Std.Reader.t * Async.Std.Writer.t) list;
}

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
let destinations = ref []

let line_of_instruction instruction =
  let open Instruction in
  Cursor.string_of_id instruction.cursor ^ " -> " ^
  begin match instruction.op with
  | Add c -> "add " ^ (Char.escaped c)
  | Move dir -> "move " ^
    begin match dir with
    | Up -> "up"
    | Down -> "down"
    | Left -> "left"
    | Right -> "right" end
  | New id -> "new " ^ Cursor.string_of_id id end ^ "\n"

let instruction_of_line line =
  let open Str in
(*  let info_list = split (regexp " -> " line) in
  match info_list with
  | [id; cmd] ->
      begin match split (regexp " " cmd) with
      | ["add"; c] when String.length c = 1 -> {
            op = Add (String.get c 0);
            cursor = ;

          }
      | ["move"; "up"] -> {}
      | ["move"; "down"] -> {}
      | ["move"; "left"] -> {}
      | ["move"; "right"] -> {}
      | ["new"; id2] -> {op = New } end

  | _ -> failwith "badly formatted instruction"
  let cmd_list = split (regexp " " )
  {

  } *)
  failwith "unimplemented"

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

