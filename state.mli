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

val get_name : t -> File.name

(* [new_cursor st] creates a new cursor in state [st]. *)
val new_cursor : t -> t
(* Also gives the cursor itself. *)
val new_cursor_get : t -> t * Cursor.id

(* Adds a cursor to the state. None if id already exists. *)
val add_cursor : t -> Cursor.id -> t option

(* [get_cursor st id] returns the cursor with [id], if it exists in [st].
 * Returns None if no cursor with [id] in [st] *)
val get_cursor : t -> Cursor.id -> Cursor.t option
val get_cursors : t -> Cursor.t list
(* Returns all the cursors that don't match the id.
 * Does not require id to be in state. *)
val get_other_cursors : t -> Cursor.id -> Cursor.t list

(* ith row. *)
val ith : t -> int -> row option
(* jth column of row. *)
val jth : row -> int -> char option
(* Gets all rows. *)
val rows : t -> row list

val string_of_row : row -> string
val char_list_of_row : row -> char list

(* [add st c ch] inserts in [st] the char [ch] at cursor [c].
 * None if no changed occured, for example because of backspace at start. *)
val add : t -> Cursor.id -> char -> t option

(* Moves cursor one character right, left, down, or up.
 * Right and left may change lines.
 * None if no change occured. *)
val inc : t -> Cursor.id -> t option
val dec : t -> Cursor.id -> t option
val up : t -> Cursor.id -> t option
val down : t -> Cursor.id -> t option

(* Creating a new state. *)
val blank : t
val instantiate : Cursor.id -> File.name option -> t

(* For debug and for transmission. *)
(* val string_of_t : t -> string *)
(* val decode : string -> t *)