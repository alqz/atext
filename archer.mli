(* archer.mli
 * Updated 151109 by Albert Zhang
 * For ATEXT text-editor project.
 *)

type arrow = string * ihavenoidea

(* Packs instructions into an arrow. *)
val fletch : instruction -> arrow