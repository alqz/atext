type dir = Up | Down | Left | Right

type operation =
  | Add of char
  | Move of dir
  | New
  | Leave

(* Instruction is an operation and the string ID of the cursor. *)
type t = {
  op     : operation;
  cursor : Cursor.id;
  file   : File.name;
}

exception JsonCorrupted of string

let encode (it : t) : Yojson.Basic.json =
  let open Yojson.Basic in
  `Assoc [
    ("o",
      match it.op with
      | Add c -> `Int (Char.code c)
      | Move Up -> `String "u"
      | Move Down -> `String "d"
      | Move Left -> `String "l"
      | Move Right -> `String "r"
      | New -> `String "n"
      | Leave -> `String "x"
    );
    ("c",
      `String (Cursor.string_of_id it.cursor)
    );
    ("f",
      `String (File.string_of_file it.file)
    )
  ]

let decode_op (j : Yojson.Basic.json) : operation =
  let open Yojson.Basic in
  match j with
  | `Int i -> Add (Char.chr i)
  | `String "u" ->  Move Up
  | `String "d" -> Move Down
  | `String "l" -> Move Left
  | `String "r" -> Move Right
  | `String "n" -> New
  | `String "x" -> Leave
  | _ -> raise (JsonCorrupted "Invalid operation!")

let decode (j : Yojson.Basic.json) : t =
  let open Yojson.Basic in
  match j with
  | `Assoc [("o", o);
            ("c", `String c);
            ("f", `String f)] -> {
      op = decode_op o;
      cursor = Cursor.id_of_string c;
      file = File.file_of_string f
    }
  | _ -> raise (JsonCorrupted "Structure is not correct!")