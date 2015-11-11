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

(* ith row. *)
val ith : t -> int -> row
(* jth column of row. *)
val jth : row -> int -> char
(* Gets all rows. *)
val rows : t -> row list

val row_to_string : row -> string
val row_to_char_list : row -> char list

(* [insert st c i j] inserts in [st] the char [c] at row [i] and col [j]. *)
val insert_char : t -> char -> int -> int -> t

(* I wrote some ideas for functions below.
 * Since we are not implementing select,
 * we probably will not use the below functions.
 * If we were, we'd have to change how t is maintained anyway. *)

(* A substring of the ith row between two indices. *)
val ithsub : t -> int -> int -> int -> string

(* The string between the cursor
 * when the cursor moves down. *)
val downsub : t -> int -> int -> string * string