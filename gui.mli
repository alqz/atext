(* gui *)

(* This module stores a hidden mutable state within it, changing with the
 * functions as they are called.
 *)

val init : string list -> unit

val refreshscreen : string list -> (int * int) list -> unit


(*
non-blocking get the key typed by the user.
pass in the coordinates of the user's cursor (y,x)
'\r' if nothing is typed
*)
val poll_keyboard : int -> int -> char

(* functions below are for debugging *)

(* pause the screen after a call to refreshcreen to see the results *)
val pausescreen : unit -> unit

(* adjust the offset (vertical scrolling) *)
val setoffset : int -> unit
