(* state.ml
 * Updated 151125 by Albert Zhang
 * For ATEXT text-editor project.
 *)

type row = string

type t = {
  cursors : Cursor.t list;
  text    : row list;
  origin  : File.name;
}

let ith (state : t) (i : int) : row option = let t = state.text in
  if i < List.length t then Some (List.nth t i) else None

let jth (r : row) (i : int) : char option =
  if i < String.length r then Some (String.get r i) else None

let rows (state : t) : row list = t.text

let string_of_row (r : row) : string = r

let rec char_list_of_row (r : row) : char list =
  let len : int = String.length r in
  if len = 0 then [] else r.[0] :: (String.sub r 1 (len - 1))

(* Tail-recursive. *)
let (@) (l1 : 'a list) (l2 : 'a list) : 'a list =
  let l1' : 'a list = List.rev_append li [] in
  List.rev_append l1' l2

let inc (st : t) (c : Cursor.t) : t option =
  let (id (x, y)) : Cursor.t = c in
  let cur : row = ith st y in
  let new_c : Cursor.t option =
    if x < String.length cur then Some (Cursor.r c) else
    if y < List.length st.text then Some (Cursor.move c (0 - x) 1) else None
  match new_c with
  | None -> None
  | Some _ ->
    let new_cursors : Cursor.t list =
      new_c :: (get_other_cursors st id) in
    Some {cursors = new_cursors; text = st.text; origin = st.origin}
let dec (st : t) (c : Cursor.t) : t option =
  let (id (x, y)) : Cursor.t = c in
  let cur : row = ith st y in
  let new_c : Cursor.t option =
    if x > 0 then Some (Cursor.l c) else
    if y > 0 then
      Some (Cursor.move (y - 1 |> ith st |> String.length) (-1)) else None
  match new_c with
  | None -> None
  | Some _ ->
    let new_cursors : Cursor.t list =
      new_c :: (get_other_cursors st id) in
    Some {cursors = new_cursors; text = st.text; origin = st.origin}
val up : t -> Cursor.t -> t option
val down : t -> Cursor.t -> t option

(* Warning: throws errors if [i] is not a valid index.
 * Should only be used when [i] is definitely valid. *)
let cut_at (r : row) (i : int) : string * string =
  String.sub r 0 i, String.sub r i (String.length r - i) in
let break_at (rl : row list) (i : int) : row list * row list =
  let rec _break_at rl i acc =
    match i, rl with
    | 0, _ -> List.rev_append acc [], rl
    | _, [] -> failwith "Out of list range!"
    | _, h :: t -> _break_at t (i - 1) (h :: acc)
  _break_at rl i []
let triptych (rl : row list) (i : int) (width : int)
             : row list * row list * row list =
  let (chunk1, chunk2) : row list * row list = break_at rl i in
  let (chunk3, chunk4) : row list * row list = break_at chunk2 width in
  chunk1, chunk3, chunk4

let add_backspace (st : t) (c : Cursor.t) : t option =
  let (id (x, y)) : Cursor.t = c in
  match x, y with
  | 0, 0 -> None
  | 0, _ -> (* combine rows *)
    let (prev, cur) : row * row = ith st (y - 1), ith st y in
    let joined : row = prev ^ cur in
    let (chunk1, chunk2, chunk3) : row list * row list * row list =
      triptych st.text (y - 1) 2 in
    let new_text : row list = chunk1 @ [(prev ^ cur)] @ chunk3 in
    let new_cursors : Cursor.t list =
      (Cursor.move c (String.length joined) (-1)) ::
      (get_other_cursors st id) in
    Some {cursors = new_cursors; text = new_text; origin = st.origin}
  | _, _ -> (* backspace a char *)
    let cur : row = ith st y in
    let (r1, r2) : string * string = cut_at cur (x - 1) in
    let joined : row = r1 ^ (String.sub r2 1 (String.length r2 - 1)) in
    let (chunk1, chunk2, chunk3) : row list * row list * row list =
      triptych st.text y 1 in
    let new_text : row list = chunk1 @ [joined] @ chunk3 in
    let new_cursors : Cursor.t list =
      (Cursor.l c) :: (get_other_cursors st id) in
    Some {cursors = new_cursors; text = new_text; origin = st.origin}

let add_new_line (st : t) (c : Cursor.t) : t option =
  let (id (x, y)) : Cursor.t = c in
  let cur : row = ith st y in
  let (cur1, cur2) : string * string = cut_at cur x in
  let (chunk1, chunk2, chunk3) : row list * row list * row list =
      triptych st.text y 1 in
  let new_text : row list = chunk1 @ [cur1; cur2] @ chunk3 in
  let new_cursors : Cursor.t list =
      (Cursor.move c (0 - x) 1) :: (get_other_cursors st id) in
  Some {cursors = new_cursors; text = new_text; origin = st.origin}

let add_delete (st : t) (c : Cursor.t) : t option =
  match inc st c with
  | None -> None
  | Some st' -> add_backspace st' c

(* [add st c ch] inserts in [st] the char [ch] at cursor [c].
 * None if no changed occured, for example because of backspace at start. *)
let add (st : t) (c : Cursor.t) (ch : char) : t option =
  let ci : int = Char.code ch in
  if ci = 8 then add_backspace st c else
  if ci = 10 then add_newline st c else
  if ci = 127 then add_delete st c else
  if ci >= 32 && ci <= 126 then
    let (id (x, y)) : Cursor.t = c in
    let cur : row = ith st y in
    let (cur1, cur2) : string * string = cut_at cur x in
    let (chunk1, chunk2, chunk3) : row list * row list * row list =
        triptych st.text y 1 in
    let new_text : row list =
      chunk1 @ [cur1 ^ (string_of_char ch) ^ cur2] @ chunk3 in
    let new_cursors : Cursor.t list =
      (Cursor.r c) :: (get_other_cursors st id) in
    Some {cursors = new_cursors; text = new_text; origin = st.origin}
  else
    None

let new_cursor_get (st : t) : t * Cursor.t =
  let c : Cursor.t = Cursor.new_cursor () in
  {cursors = c :: st.cursors; text = st.text; origin = st.origin}, c

let new_cursor (st : t) : t =
  let (nst, c) = new_cursor_get st in
  nst

let get_cursor (st : t) (cid : Cursor.id) : Cursor.t option =
  let cs : Cursor.t list = st.cursors in
  let idmatch (c : Cursor.t) : bool = (Cursor.get_id c = cid) in
  if List.exists idmatch cs then Some (List.find idmatch cs) else None

let get_other_cursors (st : t) (cid : Cursor.id) : Cursor.t list =
  let cs : Cursor.t list = st.cursors in
  let idnomatch (c : Cursor.t) : bool = not (Cursor.get_id c = cid) in
  List.filter idnomatch cs