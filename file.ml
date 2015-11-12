(* file.mli
 * Updated 151109 by Albert Zhang
 * For ATEXT text-editor project.
 *)

(* File name. *)
type name

(* A file. *)
type t = {
  n : name;
  data : string
}

(* The designated folder that we synchronize. *)
val folder : string ref

exception FileNotFound

(* Creates a file using name.
 * Remember to put the file in the folder as well as return it. *)
val create : name -> t

(* Opens the file with name. Raise FileNotFound if no file file. *)
val open : name -> t

(* Opens all in folder. *)
val open_all : unit -> t list

(* Calls open on a list of names. Also, may raise FileNotFound. *)
val open_batch : name list -> t list

(* Overwrite t on the drive. *)
val save : t -> unit