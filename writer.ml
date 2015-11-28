(* writer.ml
 * Updated 151126 by Albert Zhang
 * For ATEXT text-editor project.
 *)

open Async.Std

type mode = Offline | Host | Client | Off
val is : mode ref

let uncap (arg_list : string list) : unit =
  listen ()

let rec listen : unit -> unit = fun _ ->
  let key_input : Gui.input = Gui.poll_keyboard () in
  (* Leave, or no? *)
  if key_input = Leave then () else
  let self_ito : Instruction.t option = interpret key_input in
  let self_updated : bool = match self_ito with
    | None -> false
    | Some it -> Guardian.update_check it in
  (* Receive *)
  (* Update *)
  (* Send *)
  listen ()

(* Interpret a raw user input. *)
let interpret (gi : Gui.input) : Instruction.t option =
  let fn = State.get_name !State.opened in
  let me = !State.me in
  match gi with
  | Nothing -> None
  | _ ->
    {cursor = me; file = fn; op =
      match gi with
  	  | Leave -> failwith "Uncaught quit!"
      | Up -> Move Up | Down -> Move Down
      | Left -> Move Left | Right -> Move Right
      | Backspace -> Add '\b'
      | Delete -> Add '\127'
      | Enter -> Add '\n'
      | Character c -> Add c
      | Nothing -> failwith "Uncaught nothing!"
    }

(* To run with new file, use: *)
uncap [];;

(* To run with command line arguments, use the following: *)
(* uncap (Array.to_list Sys.argv);; *)