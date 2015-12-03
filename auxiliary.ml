let pd (s : string) : unit = print_endline ("[D> " ^ s ^ "]")
let pdx (whether : bool) (s : string) : unit =
  if whether then print_endline ("[D> " ^ s ^ "]") else ()
let pdi (il : int list) : unit =
  let istring : string = List.fold_left (fun acc i ->
      acc ^ (string_of_int i) ^ "; ") "" il in
  pd istring

(* Uncomment these to no print. *)
(* let pd (s : string) : unit = () *)
(* let pdx (whether : bool) (s : string) : unit = () *)
(* let pdi (il : int list) : unit = () *)

let fstop () = Pervasives.exit 0

let print_and_exit str =
  ignore (Unix.system "stty sane");
  print_endline ("");
  print_endline ("");
  print_endline (str);
  ignore (Pervasives.exit 0)