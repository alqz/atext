(* instruction.mli
 * Updated 151109 by Albert Zhang
 * For ATEXT text-editor project.
 *)

type operation =
  | Add of char
  | Move of dir
  | New of string

(* Instruction is an operation and the string ID of the cursor. *)
type t = operation * string

type dir = Up | Down | Left | Right