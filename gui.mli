(* gui *)
open Async.Std
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
val poll_keyboard : unit -> input Deferred.t

val terminate: unit -> unit

(* functions below are for debugging *)

(* pause the screen after a call to refreshcreen to see the results *)
val pausescreen : unit -> unit

(* adjust the voffset (vertical scrolling) *)
val setvoffset : int -> unit

(* adjust the hoffset (horizontal scrolling) *)
val sethoffset : int -> unit