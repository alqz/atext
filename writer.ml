(* writer.ml
 * Updated 151126 by Albert Zhang
 * For ATEXT text-editor project.
 *)

open Async.Std

exception FileFailedToOpen

(* Unused for now. *)
(* type mode = Offline | Host | Client | Inert *)

(* Interpret a raw user input. *)
let interpret (gi : Gui.input) : Instruction.t option =
  let fn = match !Guardian.opened with
    | None -> raise FileFailedToOpen
    | Some st -> State.get_name st in
  let me = !Guardian.me in
  let op : Instruction.operation option = match gi with
    | Leave -> Some Leave
    | Up -> Some (Move Up) | Down -> Some (Move Down)
    | Left -> Some (Move Left) | Right -> Some (Move Right)
    | Backspace -> Some (Add '\b')
    | Delete -> Some (Add '\127')
    | Enter -> Some (Add '\n')
    | Character c -> Some (Add c)
    | Nothing -> None
  in match op with
  | Some op' ->
    let open Instruction in Some {op = op'; cursor = me; file = fn}
  | None -> None

let rec share (it : Instruction.t) : unit =
  ignore (Server.send it)

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
  let it : Instruction.t option = interpret ki in
  match it with
  (* Is a valid thing typed at all? If not, just don't bother. *)
  | None -> refrain ()
  | Some _ ->
    begin
      match Guardian.update_check it with
      | `NothingOpened -> raise FileFailedToOpen
      | `Success -> (* Proceed *) share it
      | `InvalidInstruction -> ()
    end;
    if ki = Leave then finish () else refrain ()
and process_ext_input (it : Instruction.t) : unit =
  ignore (Guardian.update_check);
  refrain ()
(* Basically, this makes the above code more readable.
 * Rather than evaluating to a recursive call or just (),
 * we call functions with names. *)
and refrain : unit -> unit = listen
and finish : unit -> unit = fun _ -> ()

let uncap (arg_list : string list) : unit =
  listen ()

let _ = Scheduler.go ();;

(* To run with new file, use: *)
uncap [];;

(* To run with command line arguments, use the following: *)
(* uncap (Array.to_list Sys.argv);; *)