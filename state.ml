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

let get_name (st : t) : File.name = st.name

let get_cursors (st : t) : Cursor.t list = st.cursors

let add_cursor (st : t) (cid : Cursor.id) : t option =
  match get_cursor st cid with
  | None -> let new_cursors = (Cursor.new_cursor_from_id cid) :: st.cursors in
    {cursors = new_cursors; text = st.text; origin = st.origin}
  | Some _ -> None

let new_cursor_get (st : t) : t * Cursor.id =
  let cid : Cursor.id = Cursor.gen_id () in
  let c : Cursor.t = Cursor.new_cursor_from_id cid in
  {cursors = c :: st.cursors; text = st.text; origin = st.origin}, cid

let new_cursor (st : t) : t =
  let (nst, cid) = new_cursor_get st in nst

let get_cursor (st : t) (cid : Cursor.id) : Cursor.t option =
  let cs : Cursor.t list = st.cursors in
  let idmatch (c : Cursor.t) : bool = (Cursor.get_id c = cid) in
  if List.exists idmatch cs then Some (List.find idmatch cs) else None

let get_other_cursors (st : t) (cid : Cursor.id) : Cursor.t list =
  let cs : Cursor.t list = st.cursors in
  let idnotmatch (c : Cursor.t) : bool = not (Cursor.get_id c = cid) in
  List.filter idnotmatch cs

(* Should only be used in this module if you are sure that None
 * will never occur. *)
let coerce (ao : 'a option) : 'a =
  match ao with
  | Some a -> a
  | None -> failwith "Bad coercion!"

let ith (state : t) (i : int) : row option = let t = state.text in
  if i < List.length t then Some (List.nth t i) else None

let jth (r : row) (i : int) : char option =
  if i < String.length r then Some (String.get r i) else None

let rows (state : t) : row list = state.text

let string_of_row (r : row) : string = r

let rec char_list_of_row (r : row) : char list =
  let len : int = String.length r in
  if len = 0 then [] else
  r.[0] :: char_list_of_row (String.sub r 1 (len - 1))

(* Tail-recursive. *)
let (@) (l1 : 'a list) (l2 : 'a list) : 'a list =
  let l1' : 'a list = List.rev_append l1 [] in
  List.rev_append l1' l2

let replace_cursor (st : t) (old_cid : Cursor.id) (new_c : Cursor.t option)
                   : t option =
  match new_c with
  | None -> None
  | Some new_c' ->
    let new_cursors : Cursor.t list =
      new_c' :: (get_other_cursors st id) in
    Some {cursors = new_cursors; text = st.text; origin = st.origin}

let inc (st : t) (cid : Cursor.id) : t option =
  match get_cursor st cid with
  | Some c ->
    let id, x, y = Cursor.id c, Cursor.x c, Cursor.y c in
    let cur_len : int = y |> ith st |> coerce |> String.length in
    let new_c : Cursor.t option =
      if x <= cur_len - 1 then Some (Cursor.r c) else
      if y <= List.length st.text - 1 - 1 then
        Some (Cursor.move c (0 - x) 1)
      else None in
    replace_cursor st id new_c
  | None -> None

let dec (st : t) (cid : Cursor.id) : t option =
  match get_cursor st cid with
  | Some c ->
    let id, x, y = Cursor.id c, Cursor.x c, Cursor.y c in
    let new_c : Cursor.t option =
      if x >= 1 then Some (Cursor.l c) else
      if y >= 1 then
        let prev_len : int = y - 1 |> ith st |> coerce |> String.length in
        Some (Cursor.move c prev_len (-1))
      else None in
    replace_cursor st id new_c
  | None -> None

let up (st : t) (cid : Cursor.id) : t option =
  match get_cursor st cid with
  | Some c ->
    let id, x, y = Cursor.id c, Cursor.x c, Cursor.y c in
    let new_c : Cursor.t option =
      if y >= 1 then
        let prev_len : int = y - 1 |> ith st |> coerce |> String.length in
        if x < prev_len then Some (Cursor.u c)
        else Some (Cursor.move c prev_len (-1))
      else None in
    replace_cursor st id new_c
  | None -> None

let down (st : t) (cid : Cursor.id) : t option =
  match get_cursor st cid with
  | Some c ->
    let id, x, y = Cursor.id c, Cursor.x c, Cursor.y c in
    let new_c : Cursor.t option =
      if y <= List.length st.text - 1 - 1 then
        let next_len : int = y + 1 |> ith st |> coerce |> String.length in
        if x < next_len then Some (Cursor.u c)
        else Some (Cursor.move c next_len 1)
      else None in
    replace_cursor st id new_c
  | None -> None

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

let add_backspace (st : t) (cid : Cursor.id) : t option =
  match get_cursor st cid with
  | Some c -> begin
      let id, x, y = Cursor.id c, Cursor.x c, Cursor.y c in
      match x, y with
      | 0, 0 -> None
      | 0, _ -> (* combine rows *)
        let (prev, cur) : row * row =
          coerce (ith st (y - 1)), coerce (ith st y) in
        let joined : row = prev ^ cur in
        let (chunk1, chunk2, chunk3) : row list * row list * row list =
          triptych st.text (y - 1) 2 in
        let new_text : row list = chunk1 @ [(prev ^ cur)] @ chunk3 in
        let new_cursors : Cursor.t list =
          (Cursor.move c (String.length joined) (-1)) ::
          (get_other_cursors st id) in
        Some {cursors = new_cursors; text = new_text; origin = st.origin}
      | _, _ -> (* backspace a char *)
        let cur : row = coerce (ith st y) in
        let (r1, r2) : string * string = cut_at cur (x - 1) in
        let joined : row = r1 ^ (String.sub r2 1 (String.length r2 - 1)) in
        let (chunk1, chunk2, chunk3) : row list * row list * row list =
          triptych st.text y 1 in
        let new_text : row list = chunk1 @ [joined] @ chunk3 in
        let new_cursors : Cursor.t list =
          (Cursor.l c) :: (get_other_cursors st id) in
        Some {cursors = new_cursors; text = new_text; origin = st.origin}
    end
  | None -> None

let add_return (st : t) (cid : Cursor.id) : t option =
  match get_cursor st cid with
  | Some c -> 
    let id, x, y = Cursor.id c, Cursor.x c, Cursor.y c in
    let cur : row = coerce (ith st y) in
    let (cur1, cur2) : string * string = cut_at cur x in
    let (chunk1, chunk2, chunk3) : row list * row list * row list =
        triptych st.text y 1 in
    let new_text : row list = chunk1 @ [cur1; cur2] @ chunk3 in
    let new_cursors : Cursor.t list =
        (Cursor.move c (0 - x) 1) :: (get_other_cursors st id) in
    Some {cursors = new_cursors; text = new_text; origin = st.origin}
  | None -> None

let add_delete (st : t) (cid : Cursor.id) : t option =
  match get_cursor st cid with
  | Some c -> begin
      match inc st c with
      | None -> None
      | Some st' -> add_backspace st' c
    end
  | None -> None

(* [add st c ch] inserts in [st] the char [ch] at cursor [c].
 * None if no changed occured, for example because of backspace at start. *)
let add (st : t) (cid : Cursor.id) (ch : char) : t option =
  let ci : int = Char.code ch in
  if ci = 8 then add_backspace st cid else
  if ci = 10 then add_return st cid else
  if ci = 127 then add_delete st cid else
  if ci >= 32 && ci <= 126 then
    match get_cursor st cid with
    | Some c ->
      let id, x, y = Cursor.id c, Cursor.x c, Cursor.y c in
      let cur : row = coerce (ith st y) in
      let (cur1, cur2) : string * string = cut_at cur x in
      let (chunk1, chunk2, chunk3) : row list * row list * row list =
          triptych st.text y 1 in
      let new_text : row list =
        chunk1 @ [cur1 ^ (Char.escaped ch) ^ cur2] @ chunk3 in
      let new_cursors : Cursor.t list =
        (Cursor.r c) :: (get_other_cursors st id) in
      Some {cursors = new_cursors; text = new_text; origin = st.origin}
    | None -> None
  else
    None

let blank : t = {cursors = []; text = [""]; origin = "untitled"}

let instantiate (cid  : Cursor.id)
                (text : string)
                (fn   : File.name) : t =
  
let instantiate_from_cursor_id (cid : Cursor.id) : t = fun _ ->
  {cursors = [Cursor.new_cursor_from_id cid]; text = [""]; origin = "untitled"}

(* Logically not needed. How would you tell other editors to do the same? *)
let zero_cursors (st : t) : t =
  let new_cursors : Cursor.t list = List.fold_left (fun cl c ->
    Cursor.zero c :: cl) [] st.cursors in
  {cursors = new_cursors; text = st.text; origin = st.origin}