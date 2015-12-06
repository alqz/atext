(* writer.mli
 * Updated 151126 by Albert Zhang
 * For ATEXT text-editor project.
 *)

(* This is the top level module and contains the main loop. *)

(* Starts the program.
 * Should never be called outside this module.
 * This is only here for referece. *)
val uncap : string list -> unit

(* Exits cleanly. *)
val force_end : unit -> unit

exception FileFailedToOpen