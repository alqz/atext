(* writer.mli
 * Updated 151126 by Albert Zhang
 * For ATEXT text-editor project.
 *)

(* This is the top level module and contains the main loop. *)

val uncap : string list -> unit

exception FileFailedToOpen