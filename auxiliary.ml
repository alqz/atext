let pd (s : string) : unit = print_endline ("[D> " ^ s ^ "]")
let fstop : unit -> unit = fun _ -> ignore (Pervasives.exit 0)