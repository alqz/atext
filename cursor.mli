(* cursor.mli
 * Updated 151109 by Albert Zhang
 * For ATEXT text-editor project.
 *)

(* In this module, we keep track of the cursor.
 * All we really need is a unique ID, a generator function,
 * and a pair of ints that we use for the row and col.
 * We probably need the ID for different servers to talk to each other. *)

type id

(* A Cursor.t is (cursor_id, (row_num, col_num)).
 * The reason I use a nested tuple is this way we can do fst and snd
 * and still be able to reach all of the terms of the tuple. *)
type t

(* Generates a random ID for the cursor. Each machine instantiates
 * its own cursor, I think. For the hash code to be unique, we can just
 * use year, month, day, hour, min, second, random letters; for example:
 *   20151109210522xnwuc *)
val gen_id : unit -> id
val cursor_using_id : id -> t

(* Move one unit in the directions. *)
val u : t -> t
val d : t -> t
val l : t -> t
val r : t -> t

(* [move c i j] increases the horizontal coordinate by i and the
 * vertical coordinate by j.
 * Note that this does not care about state, it only adjusts the
 * coordinates. For a move that is conscious of the state
 * and the line lengths, see Guardian. *)
val move : t -> int -> int -> t

val string_of_id : id -> string

(* A question: do we want to be able to manage the
 * cursor's relative position to state in here?
 * My answer, for now, is no, because we want to
 * reduce coupling, and the update_state function,
 * or whatever it may be called,
 * should handle that using the tools we provide here. *)