(* guardian.mli
 * Updated 151126 by Albert Zhang
 * For ATEXT text-editor project.
 *)

(* The guardian is the editor. It handles most of the algorithm work.
 * A functor may be made out of it before it talks to anything else,
 * because the algorithm and what it sends out is at the core,
 * and everything else is like an extension. *)

(* The file that is currently open as a state. *)
val opened : State.t ref

exception OpenedTaken

(* Pen basically updates the state using the instruction.
 * The bool at the end indicates whether a change was made. *)
val pen_check : State.t -> Instruction.t -> State.t * bool
val pen_filter : State.t -> Instruction.t list -> State.t * Instruction.t list

(* Receive a list of instructions and update state using them. *)
val dictate : State.t -> Instruction.t list Deferred.t -> State.t

(* Same as pen, but uses the open State.t ref. *)
val update_check : Instruction.t -> bool
val update_filter : Instruction.t list -> Instruction.t list

val dictate_open : Instruction.t list Deferred.t -> Instruction.t list Deferred.t

(* The changes that are of other files, waiting to be made. *)
val waiting : (File.name * (Instruction.t list)) list ref

(* Looks at a list of instructions. For all of them that have
 * the name passed in, we return. For all that do not, we
 * add to edits. *)
val filter : Instruction.t list -> name -> Instruction.t list

(* Process a file. If there are edits to be made, makes them now. *)
val load : File.t -> State.t

(* Opens the file with the name to the opened.
 * Raises OpenedTaken if the opened ref is taken. *)
val open : File.name -> unit

(* Uses File.open and load to open a file but not set it as the opened file. *)
val background_open : File.name -> State.t
val background_open_multi : unit -> State.t list

(* Looks at all of the files with changes in waiting.
 * Opens them in background, writes the changes. *)
val commit : unit -> File.t list

(* Same as commit, but writes each file to disk. *)
val close : unit -> unit