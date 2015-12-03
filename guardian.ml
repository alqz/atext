(* guardian.ml
 * Updated 151126 by Albert Zhang
 * For ATEXT text-editor project.
 *)

open Auxiliary

let me : Cursor.id ref =
  ref (Cursor.gen_id ())

(* The file that is currently open as a state. *)
let opened : State.t option ref =
  ref None

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

let update_check (it : Instruction.t)
                : [> `NothingOpened | `Invalid | `Success] =
  pd "G.update_check: Starting update of state";
  match !opened with
  | Some st -> begin match pen_check st it with
      | false -> `Invalid
      | true ->
        pd "G.update_check: Change opened state";
        (* update the GUI *)
        let my_cursor : Cursor.t = coerce (State.get_cursor st !me) in
        (* let my_coords : int * int =
          Cursor.x my_cursor, Cursor.y my_cursor in *)
        let other_cursors : Cursor.t list = State.get_other_cursors st !me in
        (* let other_coords : (int * int) list = List.fold_left (fun cl c ->
          (Cursor.x c, Cursor.y c) :: cl) [] other_cursors in *)
        let rows_as_strings : string list =
          List.map State.string_of_row (State.rows st) in
        pd "G.update_check: About to call Gui.refreshscreen";
        Gui.refreshscreen rows_as_strings other_cursors my_cursor;
        pd "G.update_check: Finished call to Gui.refreshscreen";
        `Success
    end
  | None -> `NothingOpened

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
    let my_cursor : Cursor.t = coerce (State.get_cursor new_state cid) in
    let other_cursors : Cursor.t list = State.get_other_cursors new_state cid in
    let rows_as_strings : string list =
      List.map State.string_of_row (State.rows new_state) in
    (* Gui.init []; *)
    Gui.refreshscreen rows_as_strings other_cursors my_cursor;
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