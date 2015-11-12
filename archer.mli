(* archer.mli
 * Updated 151109 by Albert Zhang
 * For ATEXT text-editor project.
 *)

type arrow

type partner
(* For example
 * type partner = ('a Socket.t * Reader.t * Writer.t) Deferred.t
 *)

type partners = Master of partner | Slaves of partner list

type t

exception CannotInitializeSelf
exception CannotReach

(* Initialize this server. *)
val init : unit -> t

(* Packs instructions into a message. *)
val envelop : Instruction.t -> arrow

(* Extract the instructions on the reader buffer. *)
val hear : t -> Instruction.t list Deferred.t

(* Write instructions onto the writer buffer for one partner. *)
val send : t -> partner -> arrow -> unit

(* Write instructions onto the writer buffer for all partners. *)
val broadcast : partners -> arrow -> unit