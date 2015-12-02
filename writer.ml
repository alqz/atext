(* writer.ml
 * Updated 151126 by Albert Zhang
 * For ATEXT text-editor project.
 *)

open Async.Std
open Auxiliary

exception FileFailedToOpen

(* Unused for now. *)
(* type mode = Offline | Host | Client | Inert *)

(* Interpret a raw user input. *)
let interpret (gi : Gui.input) : Instruction.t option =
  let open Gui in
  let open Instruction in
  let fn =
    match !Guardian.opened with
    | None -> raise FileFailedToOpen
    | Some st -> State.get_name st in
  let me = !Guardian.me in
  let op : Instruction.operation option =
    match gi with
    | Leave -> Some Leave
    | Up -> Some (Move Up) | Down -> Some (Move Down)
    | Left -> Some (Move Left) | Right -> Some (Move Right)
    | Backspace -> Some (Add '\b')
    | Delete -> Some (Add '\127')
    | Enter -> Some (Add '\n')
    | Character c -> Some (Add c)
    | Nothing -> None in
  match op with
  | Some op' ->
      let open Instruction in
      Some {op = op'; cursor = me; file = fn}
  | None -> None

let rec share (it : Instruction.t) : unit =
  ignore (Server.send it)

and listen_key () =
  let _ = Gui.poll_keyboard () >>= process_key_input in
  return ()

and listen_ext () =
  let _ =
    Server.occumulated_instruction () >>= process_ext_input in
  return ()

(* Processes the input from GUI.
 * Returns an instruction, that should be sent depending on
 * whether it was accepted, Some, or rejected, None. *)
and process_key_input (ki : Gui.input) : unit Deferred.t =
  let open Gui in
  let stop_listen () =
    () |> Guardian.close |> ignore;
    Pervasives.exit 0 in
  if ki = Leave then stop_listen () else
  pd "W.process_key: key input detected";
  match interpret ki with
  (* Is a valid thing typed at all? If not, just don't bother. *)
  | None ->
      pd "W.process_key: Interpretation result is not a valid key";
      listen_key()
  | Some it' when Guardian.update_check it' <> `NothingOpened ->
      pd "W.process_key: Either instruction accepted or ignored invalid inst";
      listen_key()
  | _ ->
      pd "W.process_key: Tried to update state but no state was open";
      ignore (fstop ());
      return ()

and process_ext_input (it : Instruction.t) : unit Deferred.t =
  pd "W.process_key: key input detected";
  ignore (Guardian.update_check it);
  listen_ext ()

let uncap (arg_list : string list) : unit =
  pd "W.uncap: Start of program";
  begin match arg_list with
  | [] ->
      pd "W.uncap: with no arguments";
      Guardian.unfold None |> ignore
  | h::t ->
      pd ("W.uncap: with argument " ^ h);
      Guardian.unfold (Some (File.file_of_string h)) |> ignore end;
  pd "W.uncap: finished initialization; going to listen"

let _ = listen_key()
let _ = listen_ext()

(* To run with new file, use: *)
let _ = uncap (List.tl (Array.to_list Sys.argv))

(* To run with command line arguments, use the following: *)
(* uncap (Array.to_list Sys.argv);; *)

let _ = Scheduler.go ()