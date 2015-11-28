(* gui *)

(* This module stores a hidden mutable state within it, changing with the
 * functions as they are called.
 *)

val init : string list -> unit

(*
Takes in all lines
all cursors (absolute)
user's cursor position (absolute)
*)
val refreshscreen : string list -> (int * int) list -> int -> int -> unit


(*
non-blocking get the key typed by the user.
'\r' if nothing is typed
*)
val poll_keyboard : unit -> char

(* functions below are for debugging *)

(* pause the screen after a call to refreshcreen to see the results *)
val pausescreen : unit -> unit

(* adjust the offset (vertical scrolling) *)
val setoffset : int -> unit
