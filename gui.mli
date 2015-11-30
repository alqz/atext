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
Takes in all lines as strings
all other cursors
this cursor
*)
val refreshscreen : string list -> Cursor.t list -> Cursor.t -> unit


(*
non-blocking get the key typed by the user.

*)
val poll_keyboard : unit -> input

(* functions below are for debugging *)

(* pause the screen after a call to refreshcreen to see the results *)
val pausescreen : unit -> unit

(* adjust the offset (vertical scrolling) *)
val setoffset : int -> unit
