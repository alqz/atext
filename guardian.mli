(* guardian.mli
 * Updated 151109 by Albert Zhang
 * For ATEXT text-editor project.
 *)

(* The guardian is the editor. It handles most of the algorithm work.
 * A functor may be made out of it before it talks to anything else,
 * because the algorithm and what it sends out is at the core,
 * and everything else is like an extension. *)