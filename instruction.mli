(* instruction.mli
 * Updated 151109 by Albert Zhang
 * For ATEXT text-editor project.
 *)

type operation =
  | Add of string
  | Del of int
  | Move of int * int
  | New of int * int

(* Instruction is an operation and the string ID of the cursor. *)
type t = operation * string