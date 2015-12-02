let pd (s : string) : unit = print_endline ("[D> " ^ s ^ "]")

let pdi (il : int list) : unit =
  let istring : string = List.fold_left (fun acc i ->
      acc ^ (string_of_int i) ^ "; ") "" il in
  pd istring

let fstop : unit -> unit = fun _ -> ignore (Pervasives.exit 0)