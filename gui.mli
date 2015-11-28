(* gui *)

(* This module stores a hidden mutable state within it, changing with the
 * functions as they are called.
 *)

type input =
  | Leave
  | Backspace
  | Delete
  | Enter
  | Up | Down | Left | Right
  | Character of char
  | Nothing

val init : string list -> unit

(*
Takes in all lines
all cursors (absolute)
user's cursor position (absolute) y first and then x
*)
val refreshscreen : string list -> (int * int) list -> (int * int) -> unit


(*
non-blocking get the key typed by the user.

*)
val poll_keyboard : unit -> input

(* functions below are for debugging *)

(* pause the screen after a call to refreshcreen to see the results *)
val pausescreen : unit -> unit

(* adjust the offset (vertical scrolling) *)
val setoffset : int -> unit
