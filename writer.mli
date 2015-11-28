(* writer.mli
 * Updated 151126 by Albert Zhang
 * For ATEXT text-editor project.
 *)

(* This is the top level module and contains the main loop. *)

type mode = Offline | Host | Client | Off
val is : mode ref

val uncap : string list -> unit