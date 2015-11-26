open Async.Std

type client_info = {
  server  : string;
  port    : int;
  pending : Instruction.t AQueue.t;
  reader  : Async.Std.Reader.t;
  writer  : Async.Std.Writer.t;
}
type server_info = {
  port : int;
  mutable clients : (string * Async.Std.Reader.t * Async.Std.Writer.t) list;
  pending : Instruction.t AQueue.t;
}
type t =
  | Client of client_info
  | Server of server_info

let instance = ref None

let line_of_instruction instruction =
  let open Instruction in
  begin match instruction.op with
  | Add c -> "add "^(Char.escaped c)
  | Move dir -> "move "^
    begin match dir with
    | Up -> "up"
    | Down -> "down"
    | Left -> "left"
    | Right -> "right" end
  | New id -> "new " ^ Cursor.string_of_id id end ^ "\n"


let instruction_of_line line =
  let open Str in
  failwith "unimplemented"


let init_client addr port_num =
  let open Async.Std.Tcp in
  connect(to_host_and_port addr port_num) >>= fun (socket, read, write) ->
  let client = {
    server = addr;
    port = port_num;
    pending = AQueue.create();
    reader = read;
    writer = write;
  } in
  instance := Some client;
  return 0


let init_server port collab_num =
  failwith "unimplemented"

let occumulated_instruction () =
  failwith "unimplemented"

let send instruction =
  if !instance = None then failwith "server/client not intialized" else
  failwith "unimplemented"

