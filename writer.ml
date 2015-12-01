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
  let open Gui in let open Instruction in
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

let rec listen : unit -> unit Deferred.t = fun _ ->
  (* Poll keyboard *)
  let key_input_d : Gui.input Deferred.t =
    Gui.poll_keyboard () in
  (* Understand keyboard *)
  let _ : unit Deferred.t =
    key_input_d >>= process_key_input in
  (* Poll server *)
  let ext_input_d : Instruction.t Deferred.t =
    Server.occumulated_instruction () in
  (* Try processing it and ignore results *)
  let _ : unit Deferred.t =
    ext_input_d >>= process_ext_input in
  return ()
and listen_key : unit -> unit Deferred.t = fun _ ->
  let key_input_d : Gui.input Deferred.t =
    Gui.poll_keyboard () in
  let _ : unit Deferred.t =
    key_input_d >>= process_key_input in
  return ()
and listen_ext : unit -> unit Deferred.t = fun _ ->
  let ext_input_d : Instruction.t Deferred.t =
    Server.occumulated_instruction () in
  let _ : unit Deferred.t =
    ext_input_d >>= process_ext_input in
  return ()
(* Processes the input from GUI.
 * Returns an instruction, that should be sent depending on
 * whether it was accepted, Some, or rejected, None. *)
and process_key_input (ki : Gui.input) : unit Deferred.t =
  let it : Instruction.t option = interpret ki in
  match it with
  (* Is a valid thing typed at all? If not, just don't bother. *)
  | None -> listen ()
  | Some it' ->
    begin
      match Guardian.update_check it' with
      | `NothingOpened -> raise FileFailedToOpen
      | `Success -> (* Proceed *) share it'
      | `InvalidInstruction -> ()
    end;
    let open Gui in
    if ki = Leave then stop_listen () else listen_key ()
and process_ext_input (it : Instruction.t) : unit Deferred.t =
  ignore (Guardian.update_check it);
  listen_ext ()
and stop_listen : unit -> unit Deferred.t = fun _ ->
  return (() |> Guardian.close |> ignore)

let uncap (arg_list : string list) : unit =
  match arg_list with
  | [] -> Guardian.unfold None |> ignore
  | h::t -> Guardian.unfold (Some (File.file_of_string h)) |> ignore;
  listen () >>> fun _ -> ()

let _ = Scheduler.go ();;

(* To run with new file, use: *)
uncap [];;

(* To run with command line arguments, use the following: *)
(* uncap (Array.to_list Sys.argv);; *)