open Auxiliary

let me : Cursor.id ref =
  ref (Cursor.gen_id ())

(* The file that is currently open as a state. *)
let opened : State.t option ref =
  ref None

let get_opened : unit -> State.t option = fun _ ->
  !opened

let get_my_cursor_id : unit -> Cursor.id = fun _ ->
  !me

let pen_check (st : State.t) (it : Instruction.t) : bool =
  pd "G.pen_check: Penning on a state";
  let open Instruction in
  if it.file = State.get_name st then
    match it.op with
    | Add ch -> pd "G.pen_check: Matched add operation";
      State.add st it.cursor ch
    | Move d -> pd "G.pen_check: Matched move operation";
      begin match d with
      	| Up -> State.up st it.cursor
      	| Down -> State.down st it.cursor
      	| Left -> State.dec st it.cursor
      	| Right -> State.inc st it.cursor
      end
    | New -> pd "G.pen_check: Matched new operation";
      State.add_cursor st it.cursor
    | Leave -> pd "G.pen_check: Matched leaves operation";
      State.del_cursor st it.cursor
  else false

let pen_filter (st : State.t) (itl : Instruction.t list) : Instruction.t list =
  let itl' = List.fold_left (fun passed it ->
      match pen_check st it with
  	  | true -> it :: passed
  	  | false -> passed
    ) [] itl in
  List.rev_append itl' []

(* Should only be used in this module if you are sure that None
 * will never occur. *)
let coerce (ao : 'a option) : 'a =
  match ao with
  | Some a -> a
  | None -> failwith "Bad coercion!"

let update_counter : int ref = ref 0
let log_file : File.name =
  let name = Cursor.string_of_id !me in
  let file = File.file_of_string ("exlog/log_" ^ name) in
  if not Auxiliary.log then file else File.create file
let log_data : string list ref = ref []

(* Writes in the log, using output_counter. *)
let logger (st : State.t) (it : Instruction.t) (valid : bool) : unit =
  if not Auxiliary.log then () else
  let st_string : string =
    st |> State.encode |> Yojson.Basic.pretty_to_string in
  let it_string : string =
    it |> Instruction.encode |> Yojson.Basic.pretty_to_string in
  let entry_info : string =
    "\n\nEntry " ^ (string_of_int !update_counter) ^ "\n" ^
    (if valid then "State updated" else "State not updated") ^ "\n" in
  let this_entry : string =
    entry_info ^ it_string ^ st_string in
  let new_log = this_entry :: !log_data in
  log_data := new_log;
  File.save_lines log_file new_log

let output : unit -> [> `NothingOpened | `Success] = fun _ ->
  match !opened with
  | None -> `NothingOpened
  | Some st -> pd "G.output: Found open state";
    let my_cursor : Cursor.t = coerce (State.get_cursor st !me) in
    let other_cursors : Cursor.t list = State.get_other_cursors st !me in
    let rows_as_strings : string list =
      List.map State.string_of_row (State.rows st) in
    Gui.refreshscreen rows_as_strings other_cursors my_cursor;
    pd "G.update_check: Finished call of Gui.refreshscreen";
    pd "G.update_check: Number of cursors on board is one plus";
    pd (string_of_int (List.length other_cursors));
    `Success

let update_check (it : Instruction.t)
                 : [> `NothingOpened | `Invalid | `Success] =
  pd "G.update_check: Starting update of state";
  match !opened with
  | Some st ->
    let updated : bool = pen_check st it in
    update_counter := (!update_counter + 1);
    (* Log it. For debugging. *)
    if log then logger st it updated else ();
    if updated then begin
      output () |> ignore; (* should always `Success *)
      `Success
    end else `Invalid
  | None -> `NothingOpened

let unpackage (st : State.t) : [> `OpenedTaken | `Success] =
  pd "G.unpackage";
  match !opened with
  | None -> pd "G.unpackage: Currently nothing opened";
    (* Generate our new cursor ID *)
    let cid : Cursor.id = Cursor.gen_id () in
    me := cid; opened := Some (State.add_cursor st cid |> ignore; st);
    pd (State.string_of_t st);
    (* Starting the GUI *)
    Gui.init [];
    output () |> ignore; (* should always `Success *)
    `Success
  | Some _ -> pd "G.unpackage: opened is taken"; `OpenedTaken

(* Opens from file name. Inits a new cursor. Basically, inits everything. *)
let unfold (fn : File.name option) : [> `OpenedTaken | `Success] =
  pd "G.unfold: Unfolding from Some file or from None";
  match !opened with
  | None -> pd "G.unfold: Currently nothing opened";
    let cid : Cursor.id = Cursor.gen_id () in
    let (file, data) : File.name * string list = match fn with
      | None -> File.default (), [""]
      | Some fn -> pd "G.unfold: Generating state from file";
        fn, try
          File.open_lines fn
        with File.FileNotFound _ ->
          pd "G.unfold: No file with name; creating new";
          (ignore (File.create fn); [""])
    in let new_state : State.t = State.instantiate cid data file in
    pd "G.unfold: successfully initialized state to";
    me := cid; opened := Some new_state;
    pd (State.string_of_t new_state);
    (* Starting the GUI *)
    Gui.init [];
    output () |> ignore; (* should always `Success *)
    `Success
  | Some _ -> pd "G.unfold: opened is taken"; `OpenedTaken

(* Note that the cid in me is ignored. *)
let close : unit -> [> `NothingOpened | `Success] = fun _ ->
  match !opened with
  | Some st ->
    let file : File.name = State.get_name st in
    let rows_as_strings : string list =
      List.map State.string_of_row (State.rows st) in
    File.save_lines file rows_as_strings;
    opened := None; `Success
  | None -> `NothingOpened