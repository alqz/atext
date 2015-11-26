open Async.Std
type client_info = {
  server  : string;
  pending : Instruction.t AQueue.t;
  socket  : Async.Std.Socket.t;
  reader  : Async.Std.Reader;
  writer  : Async.Std.Writer;
}
type server_info = {
  port : int;
  mutable clients : (string * Async.Std.Reader.t * Async.Std.Writer.t) list;
  pending : Instruction.t AQueue.t;
}
type instance =
  | Client of client_info
  | Server of server_info

let line_of_instruction instruction =
  match instruction.op with
  | Add c -> "add"^(string_of_char c)
  | Move dir -> "move "^
    begin match dir with
    | Up -> "up"
    | Down -> "down"
    | Left -> "left"
    | Right -> "right" end
  | New id -> "new" ^ failwith "need string of Cursor.id"

let init_client addr =
  failwith "unimplemented"

let init_server addr =
  failwith "unimplemented"

let occumulated_instruction () =
  failwith "unimplemented"

let send instruction =
  if !server_instance = None then failwith "server/client not intialized" else
