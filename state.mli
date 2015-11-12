(* state.mli
 * Updated 151109 by Albert Zhang
 * For ATEXT text-editor project.
 *)

(* This module creates the type that stores the state.
 * Basically, state.t is how we can maintain a state in
 * a functional, non-imperative language. *)

(* After some discussion about whether to represent rows as strings
 * or char lists. We decided that it doesn't really matter
 * and strings edge out char lists just slightly. *)

type row

type t
(* For example,
 * t = {
 *   cursors : Cursor.t list;
 *   text : row list
 * }
 *)

(* ith row. *)
val ith : t -> int -> row
(* jth column of row. *)
val jth : row -> int -> char
(* Gets all rows. *)
val rows : t -> row list

val row_to_string : row -> string
val row_to_char_list : row -> char list

(* [insert st c ch] inserts in [st] the char [ch] at cursor [c].
 * None if no changed occured, for example because of backspace at start. *)
val add : t -> Cursor.t -> char -> t option

(* Moves cursor one character right, left, down, or up.
 * Right and left may change lines.
 * None if no change occured. *)
val inc : t -> Cursor.t -> t option
val dec : t -> Cursor.t -> t option
val up : t -> Cursor.t -> t option
val down : t -> Cursor.t -> t option

(* [new_cursor st id] creates a new cursor with [id] in state [st]. *)
val new_cursor : t -> Cursor.id -> t

(* [get_cursor st id] returns the cursor with [id], if it exists in [st].
 * Returns None if no cursor with [id] in [st] *)
val get_cursor : t -> Cursor.id -> Cursor.t option