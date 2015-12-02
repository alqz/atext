(* state.ml
 * Updated 151129 by Albert Zhang
 * For ATEXT text-editor project.
 *)

open Auxiliary

type row = string

type t = {
  mutable cursors : Cursor.t list;
  mutable text    : row list;
  origin          : File.name;
}

(* TO STRING FUNCTION FOR DEBUG AND TRANSMIT *)
let string_of_t (st : t) : string =
  let cl : Cursor.t list = st.cursors in
  let sl : string list = st.text in
  let f : File.name = st.origin in
  let cs : string = List.fold_left (fun acc c ->
      (Cursor.string_of_t c) ^ "; " ^ acc
    ) "" cl in
  let ss : string = List.fold_left (fun acc s ->
      s ^ "\\n\n" ^ acc
    ) "" sl in
  let fs : string = File.string_of_file f in
  "[State object with cursors [" ^ cs ^
  "] and text [\n" ^ ss ^
  "] and file name [" ^ fs ^ "]]"

(* CURSOR GETTERS AND SETTERS *)

(* Verified *)
let get_name (st : t) : File.name = st.origin

(* Verified *)
let get_cursors (st : t) : Cursor.t list = st.cursors

(* Verified *)
let get_cursor (st : t) (cid : Cursor.id) : Cursor.t option =
  let cs : Cursor.t list = st.cursors in
  let idmatch (c : Cursor.t) : bool = (Cursor.get_id c = cid) in
  if List.exists idmatch cs then Some (List.find idmatch cs) else None

(* Verified *)
let get_other_cursors (st : t) (cid : Cursor.id) : Cursor.t list =
  let cs : Cursor.t list = st.cursors in
  let idnotmatch (c : Cursor.t) : bool = not (Cursor.get_id c = cid) in
  List.filter idnotmatch cs

(* Verified *)
let add_cursor (st : t) (cid : Cursor.id) : bool =
  match get_cursor st cid with
  | None ->
    st.cursors <- (Cursor.new_cursor_from_id cid) :: st.cursors; true
  | Some _ -> false

(* Verified *)
let del_cursor (st : t) (cid : Cursor.id) : bool =
  match get_cursor st cid with
  | None -> false
  | Some c ->
    st.cursors <- get_other_cursors st cid; true

(* Verified *)
let new_cursor_get (st : t) : Cursor.id =
  let cid : Cursor.id = Cursor.gen_id () in
  let c : Cursor.t = Cursor.new_cursor_from_id cid in
  st.cursors <- c :: st.cursors; cid

(* Verified *)
let new_cursor (st : t) : unit =
  let _ = new_cursor_get st in ()

(* FUNCTIONS TO GET ROWS *)

(* Should only be used in this module if you are sure that None
 * will never occur. *)
let coerce (ao : 'a option) : 'a =
  match ao with
  | Some a -> a
  | None -> failwith "Bad coercion!"

(* Verified *)
let ith (state : t) (i : int) : row option = let t = state.text in
  if i < List.length t then Some (List.nth t i) else None

(* Verified *)
let jth (r : row) (i : int) : char option =
  if i < String.length r then Some (String.get r i) else None

(* Verified *)
let rows (state : t) : row list = state.text

(* Verified *)
let string_of_row (r : row) : string = r

(* Verified *)
let rec char_list_of_row (r : row) : char list =
  let len : int = String.length r in
  if len = 0 then [] else
  r.[0] :: char_list_of_row (String.sub r 1 (len - 1))

(* Tail-recursive. *)
(* Verified *)
let (@) (l1 : 'a list) (l2 : 'a list) : 'a list =
  let l1r : 'a list = List.rev_append l1 [] in
  List.rev_append l1r l2

(* FUNCTIONS TO HANDLE MOVEMENT *)

(* Verified *)
let replace_cursor (st : t)
                   (this : Cursor.id) (using : Cursor.t option)
                   : bool =
  match using with
  | None -> false
  | Some new_c ->
    st.cursors <- new_c :: (get_other_cursors st this); true

(* Verified *)
let inc (st : t) (cid : Cursor.id) : bool =
  match get_cursor st cid with
  | None -> false
  | Some c ->
    let x, y = Cursor.x c, Cursor.y c in
    let cur_len : int = y |> ith st |> coerce |> String.length in
    let new_c : Cursor.t option =
      if x <= cur_len - 1 then (* within line *)
        Some (Cursor.r c)
      else if y <= List.length st.text - 1 - 1 then (* within bottom *)
        Some (Cursor.move c (0 - x) 1)
      else None
    in replace_cursor st cid new_c

(* Verified *)
let dec (st : t) (cid : Cursor.id) : bool =
  match get_cursor st cid with
  | None -> false
  | Some c ->
    let x, y = Cursor.x c, Cursor.y c in
    let new_c : Cursor.t option =
      if x >= 1 then (* within line *)
        Some (Cursor.l c)
      else if y >= 1 then (* within top *)
        let prev_len : int = y - 1 |> ith st |> coerce |> String.length in
        Some (Cursor.move c prev_len (-1))
      else None
    in replace_cursor st cid new_c

(* Verified *)
let up (st : t) (cid : Cursor.id) : bool =
  match get_cursor st cid with
  | None -> false
  | Some c ->
    let x, y = Cursor.x c, Cursor.y c in
    let new_c : Cursor.t option =
      if y >= 1 then (* within top *)
        let prev_len : int = y - 1 |> ith st |> coerce |> String.length in
        if x < prev_len then (* within prev line *)
          Some (Cursor.u c)
        else Some (Cursor.move c prev_len (-1))
      else None
    in replace_cursor st cid new_c

(* Verified *)
let down (st : t) (cid : Cursor.id) : bool =
  match get_cursor st cid with
  | None -> false
  | Some c ->
    let x, y = Cursor.x c, Cursor.y c in
    let new_c : Cursor.t option =
      if y <= List.length st.text - 1 - 1 then (* within bottom *)
        let next_len : int = y + 1 |> ith st |> coerce |> String.length in
        if x < next_len then (* within next line *)
          Some (Cursor.u c)
        else Some (Cursor.move c next_len 1)
      else None
    in replace_cursor st cid new_c

(* FUNCTIONS TO HANDLE ADDING *)

(* Gets all cursors whose position is after the current cursor.
 * Raises exception if cid is not in st. *)
(* Verified *)
let get_cursors_after (st : t) (cid : Cursor.id)
                      : Cursor.t list * Cursor.t list =
  let c : Cursor.t = get_cursor st cid |> coerce in
  let x, y = Cursor.x c, Cursor.y c in
  let after (some : Cursor.t) : bool =
    let sx, sy = Cursor.x some, Cursor.y some in
    (sy = y && sx >= x) || (sy > y) in
  List.partition after st.cursors

(* Same as above, but limits to same row. *)
(* Verified *)
let get_cursors_after_on_row (st : t) (cid : Cursor.id)
                             : Cursor.t list * Cursor.t list =
  let c : Cursor.t = get_cursor st cid |> coerce in
  let x, y = Cursor.x c, Cursor.y c in
  let after_on_row (some : Cursor.t) : bool =
    let sx, sy = Cursor.x some, Cursor.y some in
    sy = y && sx >= x in
  List.partition after_on_row st.cursors

(* Same as above, but not on the same row. *)
(* Verified *)
let get_cursors_after_row (st : t) (cid : Cursor.id)
                             : Cursor.t list * Cursor.t list =
  let c : Cursor.t = get_cursor st cid |> coerce in
  let x, y = Cursor.x c, Cursor.y c in
  let after_row (some : Cursor.t) : bool =
    let sx, sy = Cursor.x some, Cursor.y some in
    sy > y in
  List.partition after_row st.cursors

(* Warning: throws errors if [i] is not a valid index.
 * Should only be used when [i] is definitely valid. *)
let cut_at (r : row) (i : int) : string * string =
  String.sub r 0 i, String.sub r i (String.length r - i)
let break_at (rl : row list) (i : int) : row list * row list =
  let rec _break_at rl i acc =
    match i, rl with
    | 0, _ -> (List.rev_append acc [], rl)
    | _, [] -> failwith "Out of list range!"
    | _, h :: t -> _break_at t (i - 1) (h :: acc)
  in _break_at rl i []
let triptych (rl : row list) (i : int) (width : int)
             : row list * row list * row list =
  let (chunk1, chunk2) : row list * row list = break_at rl i in
  let (chunk3, chunk4) : row list * row list = break_at chunk2 width in
  chunk1, chunk3, chunk4

let add_backspace (st : t) (cid : Cursor.id) : bool =
  match get_cursor st cid with
  | None -> false
  | Some c -> let x, y = Cursor.x c, Cursor.y c in
    if x = 0 then (* head of line *)
      if y = 0 then false (* head of doc *)
      else (* merge rows up *)
        let (prev, cur) : row * row =
          coerce (ith st (y - 1)), coerce (ith st y) in
        let (before, _, after) : row list * row list * row list =
          triptych st.text (y - 1) 2 in
        st.text <- before @ [prev ^ cur] @ after;
        let (_, unaffected) : Cursor.t list * Cursor.t list =
          get_cursors_after st cid in
        let (after_on_row, _) : Cursor.t list * Cursor.t list =
          get_cursors_after_on_row st cid in
        let (after_row, _) : Cursor.t list * Cursor.t list =
          get_cursors_after_on_row st cid in
        st.cursors <- unaffected @ (Cursor.ship after_row 0 (-1)) @
                      (Cursor.ship after_on_row (String.length prev) (-1));
        true
    else (* shift one left *)
      let cur : row = coerce (ith st y) in
      let (safe, behead) : string * string = cut_at cur (x - 1) in
      let beheaded : string = String.sub behead 1 (String.length behead - 1) in
      let (before, _, after) : row list * row list * row list =
        triptych st.text (y) 1 in
      st.text <- before @ [safe ^ beheaded] @ after;
      let (after_on_row, unaffected) : Cursor.t list * Cursor.t list =
        get_cursors_after_on_row st cid in
      st.cursors <- unaffected @ (List.map Cursor.l after_on_row);
      true

let add_return (st : t) (cid : Cursor.id) : bool =
  match get_cursor st cid with
  | None -> false
  | Some c -> let x, y = Cursor.x c, Cursor.y c in
    let cur : row = coerce (ith st y) in
    let (safe, pushed) : string * string = cut_at cur x in
    let (before, _, after) : row list * row list * row list =
        triptych st.text y 1 in
    st.text <- before @ [safe; pushed] @ after;
    let (_, unaffected) : Cursor.t list * Cursor.t list =
      get_cursors_after st cid in
    let (after_on_row, _) : Cursor.t list * Cursor.t list =
      get_cursors_after_on_row st cid in
    let (after_row, _) : Cursor.t list * Cursor.t list =
      get_cursors_after_on_row st cid in
    st.cursors <- unaffected @ (Cursor.ship after_row 0 1) @
                  (Cursor.ship after_on_row (0 - (String.length safe)) 1);
    true

let add_delete (st : t) (cid : Cursor.id) : bool =
  match inc st cid with
  | false -> false
  | true -> add_backspace st cid

(* [add st c ch] inserts in [st] the char [ch] at cursor [c].
 * false if no changed occured, for example because of backspace at start. *)
let add (st : t) (cid : Cursor.id) (ch : char) : bool =
  pd "State.add: Starting add on";
  pd (string_of_t st);
  let ci : int = Char.code ch in
  if ci = 8 then add_backspace st cid else
  if ci = 10 then add_return st cid else
  if ci = 127 then add_delete st cid else
  if ci >= 32 && ci <= 126 then
    begin
      pd "State.add: Adding standard character";
      match get_cursor st cid with
      | None -> false
      | Some c -> let x, y = Cursor.x c, Cursor.y c in
        pd "State.add: Using coordinates: ";
        pdi [x; y];
        let cur : row = coerce (ith st y) in
        let (safe, nudged) : string * string = cut_at cur x in
        let (before, _, after) : row list * row list * row list =
            triptych st.text y 1 in
        st.text <- before @ [safe ^ (Char.escaped ch) ^ nudged] @ after;
        let (after_on_row, unaffected) : Cursor.t list * Cursor.t list =
          get_cursors_after_on_row st cid in
        st.cursors <- unaffected @ (List.map Cursor.r after_on_row);
        pd "State.add: Finished adding standard character; state changed to";
        pd (string_of_t st);
        true
    end
  else
    false

(* FUNCTIONS TO CREATE STATE *)

let rec read (s : string) : row list =
  if String.contains s '\n' then
    let i : int = String.index s '\n' in
    let cut : string = String.sub s 0 i in
    let len : int = String.length s in
    let remainder : string = String.sub s (i + 1) (len - (i + 1)) in
    cut :: read remainder
  else [s]

let blank : unit -> t = fun _ ->
  {cursors = []; text = [""]; origin = File.default ()}

let instantiate (cid  : Cursor.id)
                (data : string list)
                (fn   : File.name) : t =
  {cursors = [Cursor.new_cursor_from_id cid]; text = begin
    match data with
    | [] -> [""] (* We basically disallow empty states *)
    | h :: t -> h :: t
  end; origin = fn}