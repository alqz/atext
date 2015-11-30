module type TSET = sig

  type elt
  type t

  val empty : t

  val is_empty : t -> bool

  val insert : elt -> t -> t

  (* Same as insert x empty. *)
  val singleton : elt -> t

  val union : t -> t -> t
  val intersect : t -> t -> t

  (* Remove an element from the set. If the
   * element isn't present, does nothing. *)
  val remove : elt -> t -> t

  (* Returns true iff the element is in the set. *)
  val member : t -> elt -> bool

  (* Chooses some member from the set, removes it
   * and returns that element plus the new set.
   * If the set is empty, returns None. *)
  val choose : t -> (elt * t) option

  (* Fold a function across the elements of the set
   * in some unspecified order. *)
  val fold : (elt -> 'a -> 'a) -> 'a -> t -> 'a

  (* Functions to convert our types to a string. useful for debugging. *)
  val string_of_set : t -> string
  val string_of_elt : elt -> string

end

module type SETARG = sig

  type elt

  val compare : elt -> elt -> Order.order

  val string_of_t : elt -> string

end

module TwoThreeSet (C : SETARG) : (TSET with type elt = C.elt) = struct

  module D = Tdict.Make (struct

    type key = C.elt
    type value = unit

    let compare = C.compare
    let string_of_key k : string = C.string_of_t k
    let string_of_value v : string = "<FATAL> no value to print!"

  end)

  type elt = D.key
  type t = D.dict

  let empty : t = D.empty

  let is_empty (s : t) : bool = match D.choose s with
    | None -> true
    | _ -> false

  let insert e s : t = D.insert s e ()

  let singleton e : t = D.insert D.empty e ()

  let union s1 s2 : t = D.fold (fun k v d -> D.insert d k v) s1 s2

  let rec intersect (s1 : t) (s2 : t) : t =
    match D.choose s2 with
    | None -> D.empty
    | Some (k, v, d) ->
      if D.member s1 k then D.insert (intersect s1 d) k v
      else intersect s1 d

  let remove e s : t = D.remove s e

  let member : t -> elt -> bool = D.member

  let choose s : (elt * t) option = match D.choose s with
    | None -> None
    | Some (k, v, d) -> Some (k, d)

  let fold (f : elt -> 'a -> 'a) : 'a -> t -> 'a =
    D.fold (fun k v a -> f k a)

  let string_of_set s : string =
    let string_of_elements = D.fold (fun k v str ->
      str ^ "; " ^ D.string_of_key k) "" s in
    "set([" ^ string_of_elements ^ "])"

  let string_of_elt : elt -> string = D.string_of_key

end

module Make (C : SETARG) : (TSET with type elt = C.elt) =
  TwoThreeSet (C)