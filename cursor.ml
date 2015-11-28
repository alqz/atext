(* cursor.ml
 * Updated 151125 by Albert Zhang
 * For ATEXT text-editor project.
 *)

(* YYYY, MO, DD, HH, MI, SS, numbers; for example:
 *   2015, 11, 9, 21, 5, 22, 9999999
 *)
type id = int * int * int * int * int * int * int

(* Padded string_of_int conversion.
 * Truncates if too big. Adds 0 if too small.
 * Negates negative values *)
let rec p_string_of_int (padded_length : int) (input : int) : string =
  if padded_length < 0 then failwith "Can't have negative padding!" else
  match padded_length with
  | 0 -> ""
  | _ -> let digit : int = (abs input) mod 10 in
    (p_string_of_int (padded_length - 1) (input / 10)) ^ (string_of_int digit)

let string_of_id (yyyy, mo, dd, hh, mi, ss, numbers : id) : string =
  (p_string_of_int 4 yyyy) ^ (p_string_of_int 2 mo) ^ (p_string_of_int 2 dd) ^
  (p_string_of_int 2 hh) ^ (p_string_of_int 2 mi) ^ (p_string_of_int 2 ss) ^
  (p_string_of_int 7 numbers)

type t = id * (int * int)

let unpack ((id, (x, y)) : t) : id * (int * int) = id, (x, y)

let gen_id : unit -> id = fun _ ->
  let open Unix in
  let t : Unix.tm = () |> Unix.time |> Unix.localtime in
  let rand : int = Random.int 10000000 in
  (t.tm_year, t.tm_mon, t.tm_mday, t.tm_hour, t.tm_min, t.tm_sec, rand)

let new_cursor_from_id (id : id) : t = (id, (0, 0))

let new_cursor : unit -> t = fun _ -> () |> gen_id |> new_cursor_from_id

let u ((id, (x, y)) : t) : t = id, (x, y - 1)
let d ((id, (x, y)) : t) : t = id, (x, y + 1)
let l ((id, (x, y)) : t) : t = id, (x - 1, y)
let r ((id, (x, y)) : t) : t = id, (x + 1, y)

let move ((id, (x, y)) : t) (i : int) (j : int) : t =
  (id, (x + i, y + j))

let zero ((id, (_, _)) : t) : t =
  (id, (0, 0))

let get_id ((id, (_, _)) : t) : id = id

let string_of_t ((id, (x, y)) : t) : string =
  (string_of_id id) ^ "-" ^ (string_of_int x) ^ "-" ^ (string_of_int y)