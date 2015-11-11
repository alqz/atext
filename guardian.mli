(* guardian.mli
 * Updated 151109 by Albert Zhang
 * For ATEXT text-editor project.
 *)

(* The guardian is the editor. It handles most of the algorithm work.
 * A functor may be made out of it before it talks to anything else,
 * because the algorithm and what it sends out is at the core,
 * and everything else is like an extension. *)

(* Pen basically updates the state using the instruction. *)
val pen : State.t -> Instruction.t -> State.t

(* [add st id c] inserts char [c] using cursor of [id] in the state. *)
val add : State.t -> string -> char -> State.t

val del : State.t -> string -> State.t

val move : State.t -> string -> Instruction.dir -> State.t

val enter : State.t -> string -> State.t

(* Creates a cursor using id in the state. *)
val create_cursor : State.t -> string -> State.t

(* [move_all st idir] moves all of the cursors in direction [idir]. *)
val move_all : State.t -> Instruction.dir -> State.t