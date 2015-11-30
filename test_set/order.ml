(* The type order is used for comparison operations *)
type order = Less | Eq | Greater

let string_compare x y =
  let i = String.compare x y in
    if i = 0 then Eq else if i < 0 then Less else Greater

let int_compare x y =
  let i = x - y in
    if i = 0 then Eq else if i < 0 then Less else Greater