(* Set to false to no prints. *)
let debug : bool = false

let pd (s : string) : unit =
  if not debug then () else print_endline ("[D> " ^ s ^ "]")

let pdx (whether : bool) (s : string) : unit =
  if not debug then () else
  if whether then print_endline ("[D> " ^ s ^ "]") else ()

let pdi (il : int list) : unit =
  if not debug then () else
  let istring : string = List.fold_left (fun acc i ->
      acc ^ (string_of_int i) ^ "; ") "" il in
  pd istring

let fstop () = Pervasives.exit 0

let print_and_exit str =
  ignore (Unix.system "stty sane");
  print_endline ("");
  print_endline ("");
  print_endline (str);
  ignore (Pervasives.exit 0)