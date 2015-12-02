(* auxiliary.mli *)

(* Print function for debugging. *)
val pd : string -> unit
val pdx : bool -> string -> unit
val pdi : int list -> unit
val pdx : bool -> string -> unit

(* Force exit. *)
val fstop : unit -> unit