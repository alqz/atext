(* writer.mli
 * Updated 151109 by Albert Zhang
 * For ATEXT text-editor project.
 *)

(* This is the top level module and the lowest "ranked" module
 * in our system. Basically, it handles the IO, and listens like the
 * editor equivalent of a REPL.
 * This calls functions that would call functions that eventually
 * leads to instructions being sent between servers in the backend. *)

(* Uncap takes in a list of arguments as strings
 * and evaluates to a unit when the user closes the program.
 * How this works is that in the module that we designate the "run" module,
 * which may well be this one,
 * we include this line at the bottom:
 *   uncap (Array.to_list Sys.argv)
 * This would begin our read, eval, update loop. *)
val uncap : string list -> unit

(* This is not done, because we haven't thought about what arguments
 * the user may decide to run. In fact, we may have several of these,
 * to process each of the possible input arguments. *)
val process_inputs : unit -> unit

(* Again, listen should not take unit, but probably should take something that
 * uncap decides to pass in. *)
val listen : unit -> unit

(* Interpret a raw user input. *)
val interpret : keyinput -> Instruction.t

(* We expect catch to be called over and over, and attempts
 * to catch instructions sent from other servers. *)
val catch : unit -> Instruction.t

(* Listen calls this function, it should probably take the state and
 * put it on the screen. *)
val update : State.t -> unit