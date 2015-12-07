(* The guardian is the editor. It handles most of the algorithm work.
 * Also keeps track of the open state, and processes instructions. *)

(* Currently opened state and id of my cursor. *)
(* val opened : State.t option ref *)
(* val me : Cursor.id ref *)
val get_opened : unit -> State.t option
val get_my_cursor_id : unit -> Cursor.id

(* Sets the file as the currently open state.
 * Inits everything from scratch. *)
val unfold : File.name option -> [> `OpenedTaken | `Success]

(* Sets the input state as the currently open state. *)
val unpackage : State.t -> [> `OpenedTaken | `Success]

(* Closes opened. *)
val close : unit -> [> `NothingOpened | `Success]

(* Pen basically updates the state using the instruction.
 * The bool at the end indicates whether a change was made. *)
val pen_check : State.t -> Instruction.t -> bool
val pen_filter : State.t -> Instruction.t list -> Instruction.t list

(* Same as pen, but uses the open State.t ref. *)
val update_check : Instruction.t ->
  [> `NothingOpened | `Invalid | `Success]

val output : unit -> [> `NothingOpened | `Success]

(* DISABLED FUNCTIONS

val dictate_open : Instruction.t list Deferred.t -> Instruction.t list Deferred.t

(* The changes that are of other files, waiting to be made. *)
val waiting : (File.name * (Instruction.t list)) list ref

(* Looks at a list of instructions. For all of them that have
 * the name passed in, we return. For all that do not, we
 * add to edits. *)
val filter : Instruction.t list -> File.name -> Instruction.t list

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

*)