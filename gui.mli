(* gui *)

(* This module stores a hidden mutable state within it, changing with the
 * functions as they are called.
 *)

val init : string list -> unit

val scroll_up : unit -> unit

val scroll_down : unit -> unit

(* y coordinate before x coordinate *)
val add_char_at : int -> int -> unit

