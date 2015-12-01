(* guardian.ml
 * Updated 151126 by Albert Zhang
 * For ATEXT text-editor project.
 *)

let me : Cursor.id ref =
  ref (Cursor.gen_id ())

(* The file that is currently open as a state. *)
let opened : State.t option ref =
  ref None

let pen_check (st : State.t) (it : Instruction.t) : bool =
  let open Instruction in
  if it.file = State.get_name st then
    match it.op with
    | Add ch -> State.add st it.cursor ch
    | Move d -> begin match d with
      	| Up -> State.up st it.cursor
      	| Down -> State.down st it.cursor
      	| Left -> State.dec st it.cursor
      	| Right -> State.inc st it.cursor
      end
    | New -> State.add_cursor st it.cursor
    | Leave -> State.del_cursor st it.cursor
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
                : [> `NothingOpened | `InvalidInstruction | `Success] =
  match !opened with
  | Some st -> begin match pen_check st it with
      | false -> `InvalidInstruction
      | true -> (* update the GUI *)
        let my_cursor : Cursor.t = coerce (State.get_cursor st !me) in
        (* let my_coords : int * int =
          Cursor.x my_cursor, Cursor.y my_cursor in *)
        let other_cursors : Cursor.t list = State.get_other_cursors st !me in
        (* let other_coords : (int * int) list = List.fold_left (fun cl c ->
          (Cursor.x c, Cursor.y c) :: cl) [] other_cursors in *)
        let rows_as_strings : string list =
          List.map State.string_of_row (State.rows st) in
        Gui.refreshscreen rows_as_strings other_cursors my_cursor; `Success
    end
  | None -> `NothingOpened

(* Opens from file name. Inits a new cursor. Basically, inits everything. *)
let unfold (fn : File.name option) : [> `OpenedTaken | `Success] =
  match !opened with
  | None ->
    let cid : Cursor.id = Cursor.gen_id () in
    let (file, data) : File.name * string list = match fn with
      | None -> File.default (), [""]
      | Some fn -> fn, File.open_lines fn
    in me := cid; opened := Some (State.instantiate cid data file); `Success
  | Some _ -> `OpenedTaken

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