(* writer.ml
 * Updated 151126 by Albert Zhang
 * For ATEXT text-editor project.
 *)

open Async.Std
open Auxiliary

exception FileFailedToOpen

(* Unused for now. *)
type mode = Offline | Host | Guest

let is : mode ref = ref Offline

(* HELPERS *)

(* Interpret a raw user input. *)
let interpret (gi : Gui.input) : Instruction.t option =
  let open Gui in let open Instruction in
  let fn = match Guardian.get_opened () with
    | None -> raise FileFailedToOpen
    | Some st -> State.get_name st in
  let me = Guardian.get_my_cursor_id () in
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
    let open Instruction in
    Some {op = op'; cursor = me; file = fn}
  | None -> None

let share (it : Instruction.t) : unit =
  ignore (Server.send it)

(* THE MAIN LOOP *)

let rec listen : unit -> unit Deferred.t = fun _ ->
  pd "W.listen: starting to listen";
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
  pd "W.process_key: key input detected";
  if ki = Gui.Leave then stop_listen () else
  let it : Instruction.t option =
    interpret ki in
  match it with
  (* Is a valid thing typed at all? If not, just don't bother. *)
  | None ->
    pd "W.process_key: Interpretation result is not a valid key";
    listen_key ()
  | Some it' ->
    pd "W.process_key: Interpretation gave valid result";
    begin
      match Guardian.update_check it' with
      | `NothingOpened ->
        pd "W.process_key: Tried to update state but no state was open";
        fstop ();
        raise FileFailedToOpen
      | `Success -> pd "W.process_key: Successfully updated state";
        (* share it' *)
        ()
      | `Invalid ->
        pd "W.process_key: Either file name mismatch or invalid ins";
        () (* Proceed as usual *)
    end;
    listen_key ()

and process_ext_input (it : Instruction.t) : unit Deferred.t =
  pd "W.process_key: key input detected";
  ignore (Guardian.update_check it);
  listen_ext ()

and stop_listen : unit -> unit Deferred.t = fun _ ->
  (* Clear the GUI *)
  Gui.terminate ();
  (* What to do depending on whether online or offline. *)
  begin match !is with
  | Offline -> ()
  | Guest ->
    let open Instruction in
    let leave_it : Instruction.t = {
        op = Leave;
        cursor = Guardian.get_my_cursor_id ();
        file = State.get_name (match Guardian.get_opened () with
          | Some st -> st
          | None -> raise FileFailedToOpen)
      } in
    share leave_it
  | Host ->
    let open Instruction in
    let leave_it : Instruction.t = {
        op = Leave;
        cursor = Guardian.get_my_cursor_id ();
        file = State.get_name (match Guardian.get_opened () with
          | Some st -> st
          | None -> raise FileFailedToOpen)
      } in
    share leave_it
  end;
  Guardian.close () |> ignore;
  print_endline "Exiting from program...";
  Pervasives.exit 0

(* THE INIT FUNCTION *)

let uncap (arg_list : string list) : unit =
  pd "W.uncap: Start of program";
  let start_delay : Core.Std.Time.Span.t = Core.Std.sec 1.2 in
  let default_collaborator_limit : int = 7 in

  begin (* examine user input arguments *)
    match arg_list with

    | [] -> is := Offline;
      print_endline "Initializing new file in offline mode...";

      after start_delay >>= fun _ ->
      Guardian.unfold None |> ignore;
      return ()

    | filename :: [] -> is := Offline;
      print_endline (
        "Initializing in offline mode using file " ^
        filename ^ "...");

      after start_delay >>= fun _ ->
      Guardian.unfold (
        Some (File.file_of_string filename)
      ) |> ignore;
      return ()

    | "host" :: port :: filename :: [] -> is := Host;
      print_endline (
        "Initializing in host mode using file " ^ filename ^
        " at port " ^ port ^ "...");
      let port' : int = int_of_string port in
      let server_result : int Deferred.t =
        Server.init_server port' default_collaborator_limit in

      server_result >>= fun i ->
      if i = 0 (* success *) then begin
        print_endline (
          "Host server successfully started at port " ^ port ^ "...");
        after start_delay >>= fun _ ->
        Guardian.unfold (
          Some (File.file_of_string filename)
        ) |> ignore;
        return ()
      end else (* failed to start server *)
      let _ = List.map print_endline [
        "Host server could not be started.";
        "Please check your port number. Choose a number greater than 6000.";
        "Exiting..."] in
      after start_delay >>= fun _ ->
        Pervasives.exit 0

    | "guest" :: address :: port :: [] -> is := Guest;
      print_endline (
        "Initializing in guest mode using address " ^ address ^
        " at port " ^ port ^ "...");
      let port' : int = int_of_string port in
      let server_result : (State.t * int) Deferred.t =
        Server.init_client address port' in
      server_result >>= fun (st, i) ->
      if i = 0 (* success *) then begin
        print_endline (
          "Guest connection successfully made...");
        after start_delay >>= fun _ ->
        (* unpackage incoming state *)
        Guardian.unpackage st |> ignore;
        (* send out my cursor *)
        let open Instruction in
        let add_it : Instruction.t = {
            op = New;
            cursor = Guardian.get_my_cursor_id ();
            file = State.get_name st
          } in
        share add_it;
        return ()
      end else (* failed to start server *)
      let _ = List.map print_endline [
        "Guest connection could not be made.";
        "Please check your address and port numbers.";
        "Exiting..."] in
      after start_delay >>= fun _ ->
        Pervasives.exit 0

    | _ ->
      let _ = List.map print_endline [
          "You have entered invalid arguments.";
          "Use one of the following:";
          "  cs3110 run writer -- [filename]";
          "  cs3110 run writer -- host [port] [filename]";
          "  cs3110 run writer -- guest [ip or dns address]";
          "Exiting..."
        ] in
      after start_delay >>= fun _ ->
        Pervasives.exit 0 (* not debug! *)

  end >>> begin fun _ ->
    pd "W.uncap: finished initialization; going to listen";
    let _ = listen () in
    ()
  end

(* BEGIN EXECUTION *)

(* To run with new file, use: *)
let _ = uncap (List.tl (Array.to_list Sys.argv))

let _ = Scheduler.go ()