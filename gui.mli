(* gui *)

(* This module stores a hidden mutable state within it, changing with the
 * functions as they are called.
 *)

val init : string list -> unit

val cursor_movement : 

val scroll_up : t -> t

val scroll_down : unit -> unit

val add_char_at : int -> int -> unit

