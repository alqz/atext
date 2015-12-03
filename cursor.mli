(* cursor.mli
 * Updated 151125 by Albert Zhang
 * For ATEXT text-editor project.
 *)

(* In this module, we keep track of the cursor. *)

(* The id of the cursor. *)
type id

(* Representation of a cursor. *)
type t
val id : t -> id
val x : t -> int
val y : t -> int

(* Generates a random ID for the cursor. Each machine instantiates
 * its own cursor. For the ID to be unique, we use
 * year, month, day, hour, min, second, random numbers; for example:
 *   2015, 11, 9, 21, 5, 22, 9999999 *)
val gen_id : unit -> id
val new_cursor_from_id : id -> t
val new_cursor : unit -> t
(* Instantiate does the same as new_cursor but takes in info. *)
val instantiate : id -> int -> int -> t

(* Mainly for transmission purposes. *)
val string_of_id : id -> string

exception FaultyId of string

val id_of_string : string -> id

(* Move one unit in the directions. *)
val u : t -> t
val d : t -> t
val l : t -> t
val r : t -> t
(* [move c i j] increases the horizontal coordinate by i and the
 * vertical coordinate by j.
 * Note that this does not care about state, it only adjusts the
 * coordinates. *)
val move : t -> int -> int -> t
val ship : t list -> int -> int -> t list
val zero : t -> t

val get_id : t -> id

val string_of_t : t -> string