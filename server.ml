open Async.Std

type client_info = {
  server  : string;
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
  match instruction.op with
  | Add c -> "add"^(Char.escaped c)
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
  if !instance = None then failwith "server/client not intialized" else
  failwith "unimplemented"

