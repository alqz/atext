(* File name. *)
type name
type path

exception FileNotFound of string

(* FileNotFound if doesn't exist! *)
val open_lines : name -> string list

(* File with name is created if doesn't exist. *)
val save_to : name -> string -> unit
val save_lines : name -> string list -> unit

val file_of_string : string -> name
val string_of_file : name -> string

val create : name -> name
val default : unit -> name

val designated : path ref