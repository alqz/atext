(* To make a dict, define
 * key type, value type, compare function, and string_of functions.
 * For example, here is a dict with int keys and string values: *)
module IntStringDict = Tdict.Make (
  struct
    open Order
    type key = int
    type value = string
    let compare x y = if x < y then Less else if x > y then Greater else Eq
    let string_of_key : key -> string = string_of_int
    let string_of_value (v : value) : string = v
  end
)

(* To make a set, define
 * element type, compare function, and string_of function.
 * For example, here is a set of ints: *)
module IntSet = Tset.Make (
  struct
    open Order
    type elt = int
    let compare x y = if x < y then Less else if x > y then Greater else Eq
    let string_of_t : elt -> string = string_of_int
  end
)