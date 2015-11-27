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

(* Whether either server or client have been intialized *)
let initialized = ref false

(* A queue of incoming instructions pending to be processed by the editor *)
let pending = AQueue.create()

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

let rec client_loop client =
  Reader.read_line client.reader >>= function
  | `Eof -> failwith "connection with host has ended"
  | `Ok str ->
      AQueue.push pending (instruction_of_line str);
      client_loop client

let init_client addr port_num =
  if !initialized then failwith "tried to init server/client twice" else
  let open Tcp in
  connect(to_host_and_port addr port_num) >>= fun (socket, read, write) ->
  let client = {
    server = addr;
    port = port_num;
    reader = read;
    writer = write;
  } in
  ignore (client_loop client);
  initialized := true;
  return 0

let init_server port collab_num =
  if !initialized then failwith "tried to init server/client twice" else
  initialized := true;
  failwith "unimplemented"

let occumulated_instruction () =
  AQueue.pop pending

let send instruction =
  if not (!initialized) then failwith "server/client not intialized" else
  failwith "unimplemented"

