(* gui.mli *)

open Async.Std

(* This module stores a hidden mutable state within it, changing with the
 * functions as they are called. *)

type input =
  | Leave
  | Backspace
  | Delete
  | Enter
  | Up | Down | Left | Right
  | Character of char
  | Nothing

val init : string list -> unit

(* Takes in all lines as strings
 * all other cursors
 * this cursor
 *)
val refreshscreen : string list -> Cursor.t list -> Cursor.t -> unit

(* Non-blocking get the key typed by the user. *)
val poll_keyboard : unit -> input Deferred.t

(* Updates the screen size parameters used in Gui.
Call refresh screen afterwards to see chanes on the screen *)
val update_winsize: unit -> unit

(* ends the Curses interface *)
val terminate: unit -> unit

(* functions below are for debugging *)

(* initialization to support getch() for use in debugging *)
val init_old : unit -> unit

(* pause the screen after a call to refreshcreen to see the results *)
val pausescreen : unit -> unit

(* adjust the voffset (vertical scrolling) *)
val setvoffset : int -> unit

(* adjust the hoffset (horizontal scrolling) *)
val sethoffset : int -> unit

(* switch to blocking getch mode *)
val setdelay : unit -> unit