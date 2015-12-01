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

(* [get_cursor st id] returns the cursor with [id], if it exists in [st].
 * Returns None if no cursor with [id] in [st] *)
val get_cursor : t -> Cursor.id -> Cursor.t option
val get_cursors : t -> Cursor.t list
(* Returns all the cursors that don't match the id.
 * Does not require id to be in state. *)
val get_other_cursors : t -> Cursor.id -> Cursor.t list
(* [new_cursor st] creates a new cursor in state [st]. *)
val new_cursor : t -> unit
(* Also gives the cursor itself. *)
val new_cursor_get : t -> Cursor.id
(* Adds a cursor to the state. false if id already exists. *)
val add_cursor : t -> Cursor.id -> bool
(* Removes a cursor from the state. false if doesn't exist. *)
val del_cursor : t -> Cursor.id -> bool

(* ith row. *)
val ith : t -> int -> row option
(* jth column of row. *)
val jth : row -> int -> char option
(* Gets all rows. *)
val rows : t -> row list
(* Turns rows into something readable. *)
val string_of_row : row -> string
val char_list_of_row : row -> char list

(* [add st c ch] inserts in [st] the char [ch] at cursor [c].
 * false if no changed occured, for example because of backspace at start. *)
val add : t -> Cursor.id -> char -> bool

(* Moves cursor one character right, left, down, or up.
 * Right and left may change lines.
 * false if no change occured. *)
val inc : t -> Cursor.id -> bool
val dec : t -> Cursor.id -> bool
val up : t -> Cursor.id -> bool
val down : t -> Cursor.id -> bool

(* Creating a new state. *)
val blank : unit -> t
val instantiate : Cursor.id -> string list -> File.name -> t

(* For debug and for transmission. *)
(* val string_of_t : t -> string *)
(* val decode : string -> t *)