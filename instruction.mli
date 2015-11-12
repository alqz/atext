(* instruction.mli
 * Updated 151109 by Albert Zhang
 * For ATEXT text-editor project.
 *)

type dir = Up | Down | Left | Right

type operation =
  | Add of char
  | Move of dir
  | New of Cursor.id

(* Instruction is an operation and the string ID of the cursor. *)
type t = {
  op     : operation;
  cursor : Cursor.id;
  file   : File.name;
}