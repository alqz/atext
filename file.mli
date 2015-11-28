(* file.mli
 * Updated 151127 by Albert Zhang
 * For ATEXT text-editor project.
 *)

(* File name. *)
type name
type path

exception FileNotFound

val open_lines : name -> string list

val save_to : name -> string -> unit
val save_lines : name -> string list -> unit

val create : string -> name
val untitled: unit -> name