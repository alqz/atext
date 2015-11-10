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

type t = (Cursor.t list) * (string list)

(* ith row. *)
val ith : t -> int -> string

(* ith row and jth column. *)
val ijth : t -> int -> int -> char

(* I wrote some ideas for functions below.
 * Since we are not implementing select,
 * we probably will not use the below functions.
 * If we were, we'd have to change how t is maintained anyway. *)

(* A substring of the ith row between two indices. *)
val ithsub : t -> int -> int -> int -> string

(* The string between the cursor
 * when the cursor moves down. *)
val downsub : t -> int -> int -> string * string