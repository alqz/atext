(* writer.ml
 * Updated 151126 by Albert Zhang
 * For ATEXT text-editor project.
 *)

open Async.Std

type mode = Offline | Host | Client | Off
val is : mode ref

let uncap (arg_list : string list) : unit =
  listen ()

(* Interpret a raw user input. *)
let interpret (gi : Gui.input) : Instruction.t =
  let fn = State.get_name !State.opened in
  let me = !State.me in
  match gi with
  | _ ->
    {cursor = me; file = fn; op =
      match gi with
      | Leave -> Leave
      | Up -> Move Up | Down -> Move Down
      | Left -> Move Left | Right -> Move Right
      | Backspace -> Add '\b'
      | Delete -> Add '\127'
      | Enter -> Add '\n'
      | Character c -> Add c
    }

let rec share (it : Instruction.t) : unit =
  Server.send it

let rec listen = fun _ ->
  (* Poll keyboard *)
  let key_input_d : Gui.input Deferred.t =
    Gui.poll_keyboard () in
  (* Understand keyboard *)
  let key_result : unit =
    key_input_d >>= process_key_input in
  (* Poll server *)
  let ext_input_d : Instruction.t Deferred.t =
    Server.occumulated_instruction () in
  (* Try processing it and ignore results *)
  let ext_result : unit =
    ext_input_d >>= process_ext_input in
  ()
(* Processes the input from GUI.
 * Returns an instruction, that should be sent depending on
 * whether it was accepted, Some, or rejected, None. *)
and process_key_input (ki : Gui.input) : unit =
  let it : Instruction.t = interpret ki in
  begin
    match Guardian.update_check it with
    | `NothingOpened -> (* probably should not be here, if opened on startup *)
      () |> File.default |> Guardian.unfold |> ignore; (* open *)
      process_key_input ki (* retry *)
    | `Success -> (* Proceed *) share it
    | `InvalidInstruction -> ()
  end;
  if key_input = Leave then end () else refrain ()
and process_ext_input (it : Instruction.t) : unit =
  ignore (Guardian.update_check);
  refrain ()
(* Basically, this makes the above code more readable.
 * Rather than evaluating to a recursive call or just (),
 * we call functions with names. *)
and refrain : unit -> unit = listen ()
and end : unit -> unit = ()


(* To run with new file, use: *)
uncap [];;

(* To run with command line arguments, use the following: *)
(* uncap (Array.to_list Sys.argv);; *)

let _ = Scheduler.go ()