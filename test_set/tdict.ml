module type TDICT = sig

  type key
  type value
  type dict

  (* An empty dictionary *)
  val empty : dict

  (* Reduce the dictionary using the provided function f and base case u.
   * Our reducing function f must have the type:
   *      key -> value -> 'a -> 'a
   * and our base case u has type 'a.
   *
   * If our dictionary is the (key,value) pairs (in any order)
   *      (k1,v1), (k2,v2), (k3,v3), ... (kn,vn)
   * then fold should return:
   *      f k1 v1 (f k2 v2 (f k3 v3 (f ... (f kn vn u))))
   *)
  val fold : (key -> value -> 'a -> 'a) -> 'a -> dict -> 'a

  (* Returns as an option the value associated with the provided key. If
   * the key is not in the dictionary, return None. *)
  val lookup : dict -> key -> value option

  (* Returns true if and only if the key is in the dictionary. *)
  val member : dict -> key -> bool

  (* Inserts a (key,value) pair into our dictionary. If the key is already
   * in our dictionary, update the key to have the new value. *)
  val insert : dict -> key -> value -> dict

  (* Removes the given key from the dictionary. If the key is not present,
   * return the original dictionary. *)
  val remove : dict -> key -> dict

  (* Return an arbitrary key, value pair along with a new dict with that
   * pair removed. Return None if the input dict is empty *)
  val choose : dict -> (key * value * dict) option

  (* functions to convert our types to strings for debugging and logging *)
  val string_of_key: key -> string
  val string_of_value : value -> string
  val string_of_dict : dict -> string

end

module type DICTARG = sig

  type key
  type value

  val compare : key -> key -> Order.order

  val string_of_key : key -> string
  val string_of_value : value -> string

end

module TwoThreeDict (D : DICTARG)
  : (TDICT with type key = D.key with type value = D.value) = struct

  open Order

  type key = D.key
  type value = D.value
  type pair = key * value

  type dict =
    | Leaf
    | Two of dict * pair * dict
    | Three of dict * pair * dict * pair * dict

  type kicked =
    | Up of dict * pair * dict
    | Done of dict

  type hole =
    | Hole of pair option * dict
    | Absorbed of pair option * dict

  type direction2 = Left2 | Right2
  type direction3 = Left3 | Mid3 | Right3

  let empty : dict = Leaf

  let rec fold (f : key -> value -> 'a -> 'a) (u : 'a) (d : dict) : 'a =
    match d with
    | Leaf -> u
    | Two (dl, (pk, pv), dr) -> fold f (f pk pv (fold f u dl)) dr
    | Three (dl, (pk, pv), dm, (qk, qv), dr) ->
      fold f (f qk qv (fold f (f pk pv (fold f u dl)) dm)) dr

  let string_of_key : key -> string = D.string_of_key

  let string_of_value : value -> string = D.string_of_value

  let string_of_pair ((k, v) : pair) : string =
    "key: " ^ string_of_key k ^
    "; value: (" ^ string_of_value v ^ ")"

  let string_of_dict (d : dict) : string = fold (fun k v str ->
      str ^ "\n " ^ string_of_pair (k, v)) "" d

  let rec string_of_tree (d : dict) : string =
    match d with
      | Leaf -> "Leaf"
      | Two (left, (k, v), right) -> "Two(" ^ (string_of_tree left)
        ^ ",(" ^ (string_of_key k) ^ "," ^ (string_of_value v) ^ "),"
        ^ (string_of_tree right) ^ ")"
      | Three (left, (k1, v1), middle, (k2, v2), right) ->
        "Three(" ^ (string_of_tree left)
        ^ ",(" ^ (string_of_key k1) ^ "," ^ (string_of_value v1) ^ "),"
        ^ (string_of_tree middle) ^ ",(" ^ (string_of_key k2) ^ ","
        ^ (string_of_value v2) ^ ")," ^ (string_of_tree right) ^ ")"

  let rec string_of_tree_keys (d : dict) : string =
    match d with
    | Leaf -> "<0>"
    | Two (left, (k, v), right) ->
      "<2[" ^ string_of_tree_keys left ^
      "|" ^ string_of_key k ^
      "|" ^ string_of_tree_keys right ^ "]>"
    | Three (left, (k1, v1), middle, (k2, v2), right) ->
      "<3[" ^ string_of_tree_keys left ^
      "|" ^ string_of_key k1 ^
      "|" ^ string_of_tree_keys middle ^
      "|" ^ string_of_key k2 ^
      "|" ^ string_of_tree_keys right ^ "]>"

  let insert_upward_two (w : pair) (wl : dict) (wr : dict)
      (x : pair) (other : dict) : kicked =
    match D.compare (fst w) (fst x) with
    | Less -> Done (Three (wl, w, wr, x, other))
    | Greater -> Done (Three (other, x, wl, w, wr))
    | Eq -> failwith "<FATAL> insert_upward_two!"

  let insert_upward_three (w : pair) (wl : dict) (wr : dict)
      (x : pair) (y : pair) (otherl : dict) (otherr : dict) : kicked =
    match D.compare (fst w) (fst x), D.compare (fst w) (fst y) with
    | Less, Less ->
      Up (Two (wl, w, wr), x, Two (otherl, y, otherr))
    | Greater, Less ->
      Up (Two (otherl, x, wl), w, Two (wr, y, otherr))
    | Greater, Greater ->
      Up (Two (otherl, x, otherr), y, Two (wl, w, wr))
    | _, _ ->
      failwith "<FATAL> insert_upward_three!"

  let rec insert_downward (d : dict) (k : key) (v : value) : kicked =
    match d with
    | Leaf -> (* Base case! See handout. *)
      Up (Leaf, (k, v), Leaf)
    | Two (left, n, right) -> (* Mutual recursion call on two. *)
      insert_downward_two (k, v) n left right
    | Three (left, n1, middle, n2, right) -> (* Mutual recursion on three. *)
      insert_downward_three (k, v) n1 n2 left middle right
  and insert_downward_two ((k, v) : pair) ((k1, v1) : pair)
      (left : dict) (right : dict) : kicked =
    match D.compare k k1 with
    | Less -> (match insert_downward left k v with
      | Up (l, (k, v), r) -> insert_upward_two (k, v) l r (k1, v1) right
      | Done d -> Done (Two (d, (k1, v1), right)))
    | Greater -> (match insert_downward right k v with
      | Up (l, (k, v), r) -> insert_upward_two (k, v) l r (k1, v1) left
      | Done d -> Done (Two (left, (k1, v1), d)))
    | Eq -> Done (Two (left, (k, v), right))
  and insert_downward_three ((k, v) : pair) ((k1, v1) : pair) ((k2, v2) : pair)
      (left : dict) (middle : dict) (right : dict) : kicked =
    match D.compare k k1, D.compare k k2 with
    | Less, Less -> (match insert_downward left k v with
      | Up (l, (k, v), r) ->
        insert_upward_three (k, v) l r (k1, v1) (k2, v2) middle right
      | Done d -> Done (Three (d, (k1, v1), middle, (k2, v2), right)))
    | Eq, Less -> Done (Three (left, (k, v), middle, (k2, v2), right))
    | Greater, Less -> (match insert_downward middle k v with
      | Up (l, (k, v), r) ->
        insert_upward_three (k, v) l r (k1, v1) (k2, v2) left right
      | Done d -> Done (Three (left, (k1, v1), d, (k2, v2), right)))
    | Greater, Eq -> Done (Three (left, (k1, v1), middle, (k, v), right))
    | Greater, Greater -> (match insert_downward right k v with
      | Up (l, (k, v), r) ->
        insert_upward_three (k, v) l r (k1, v1) (k2, v2) left middle
      | Done d -> Done (Three (left, (k1, v1), middle, (k2, v2), d)))
    | _, _ -> failwith "<FATAL> insert_downward_three!"

  let insert (d : dict) (k : key) (v : value) : dict =
    match insert_downward d k v with
    | Up (l, (k1, v1), r) -> Two (l, (k1, v1), r)
    | Done x -> x

  let remove_upward_two (n : pair) (rem : pair option)
      (left : dict) (right : dict) (dir : direction2) : hole =
    match dir, n, left, right with
    | Left2, x, l, Two (m, y, r) | Right2, y, Two (l, x, m), r ->
      Hole (rem, Three (l, x, m, y, r)) (* Case 1 *)
    | Left2, x, a, Three (b, y, c, z, d)
    | Right2, z, Three (a, x, b, y, c), d ->
      Absorbed (rem, Two (Two (a, x, b), y, Two (c, z, d))) (* Case 2 *)
    | Left2, _, _, _ | Right2, _, _, _ ->
      Absorbed (rem, Two (Leaf, n, Leaf))

  let remove_upward_three (n1 : pair) (n2 : pair) (rem : pair option)
      (left : dict) (middle : dict) (right : dict) (dir : direction3) : hole =
    match dir, n1, n2, left, middle, right with
    | Left3, x, z, a, Two (b, y, c), d | Mid3, y, z, Two (a, x, b), c, d ->
      Absorbed (rem, Two (Three (a, x, b, y, c), z, d)) (* Case 3a. *)
    | Mid3, x, y, a, b, Two (c, z, d) | Right3, x, z, a, Two (b, y, c), d ->
      Absorbed (rem, Two (a, x, Three (b, y, c, z, d))) (* Case 3b. *)
    | Left3, w, z, a, Three (b, x, c, y, d), e (* Case 4a1. *)
    | Mid3, y, z, Three (a, w, b, x, c), d, e (* Case 4a2. *) ->
      Absorbed (rem, Three (Two (a, w, b), x, Two (c, y, d), z, e))
    | Mid3, w, x, a, b, Three (c, y, d, z, e) (* Case 4b1. *)
    | Right3, w, z, a, Three (b, x, c, y, d), e (* Case 4b1. *) ->
      Absorbed (rem, Three (a, w, Two (b, x, c), y, Two (d, z, e)))
    | Left3, _, _, _, _, _
    | Mid3, _, _, _, _, _
    | Right3, _, _, _, _, _ ->
      Absorbed (rem, Three (Leaf, n1, Leaf, n2, Leaf))

  let rec remove_downward (d : dict) (k : key) : hole =
    match d with
    | Leaf -> Absorbed (None, d)
    | Two (Leaf, (k1, v1), Leaf) -> begin
        match D.compare k k1 with
        | Eq -> Hole (Some (k1, v1), Leaf)
        | Less | Greater -> Absorbed (None, d)
      end
    | Three(Leaf,(k1,v1),Leaf,(k2,v2),Leaf) -> begin
        match D.compare k k1, D.compare k k2 with
        | Eq, _ -> Absorbed (Some (k1, v1), Two (Leaf, (k2, v2), Leaf))
        | _, Eq -> Absorbed (Some (k2, v2), Two (Leaf, (k1, v1), Leaf))
        | _, _ -> Absorbed (None, d)
      end
    | Two (l, n, r) -> remove_downward_two k n l r
    | Three (l, n1, m, n2, r) -> remove_downward_three k n1 n2 l m r
  and remove_downward_two (k : key) ((k1, v1) : pair)
                          (left : dict) (right : dict) : hole =
    match D.compare k k1 with
    | Eq ->
      (match remove_min right with
        | Hole(None,_) -> Hole(None,left)
        | Hole(Some n,new_right) ->
          remove_upward_two n None left new_right Right2
        | Absorbed(None,_) -> Hole(None,left)
        | Absorbed(Some n,new_right) -> Absorbed(None,Two(left,n,new_right))
      )
    | Less ->
      (match remove_downward left k with
        | Hole(rem,t) -> remove_upward_two (k1,v1) rem t right Left2
        | Absorbed(rem,t) -> Absorbed(rem,Two(t,(k1,v1),right))
      )
    | Greater ->
      (match remove_downward right k with
        | Hole(rem,t) -> remove_upward_two (k1,v1) rem left t Right2
        | Absorbed(rem,t) -> Absorbed(rem,Two(left,(k1,v1),t))
      )
  and remove_downward_three (k : key) ((k1, v1) : pair) ((k2, v2) : pair)
                            (left : dict) (middle : dict) (right : dict)
                            : hole =
    match D.compare k k1, D.compare k k2 with
    | Eq, _ -> begin
        match remove_min middle with
        | Hole(None,_) -> Hole(None,Two(left,(k2,v2),right))
        | Hole(Some n,new_middle) ->
          remove_upward_three n (k2,v2) None left new_middle right Mid3
        | Absorbed(None,_) -> Absorbed(None,Two(left,(k1,v1),right))
        | Absorbed(Some n,new_middle) ->
          Absorbed(None,Three(left,n,new_middle,(k2,v2),right))
      end
    | _, Eq -> begin
        match remove_min right with
        | Hole(None,_) -> Hole(None,Two(left,(k1,v1),middle))
        | Hole(Some n,new_right) ->
          remove_upward_three (k1,v1) n None left middle new_right Right3
        | Absorbed(None,_) -> Absorbed(None,Two(left,(k1,v1),middle))
        | Absorbed(Some n,new_right) ->
          Absorbed(None,Three(left,(k1,v1),middle,n,new_right))
      end
    | Less, _ -> begin
        match remove_downward left k with
        | Hole(rem,t) ->
          remove_upward_three (k1,v1) (k2,v2) rem t middle right Left3
        | Absorbed(rem,t) ->
          Absorbed(rem,Three(t,(k1,v1),middle,(k2,v2),right))
      end
    | _, Greater -> begin
        match remove_downward right k with
        | Hole(rem,t) ->
          remove_upward_three (k1,v1) (k2,v2) rem left middle t Right3
        | Absorbed(rem,t) ->
          Absorbed(rem,Three(left,(k1,v1),middle,(k2,v2),t))
      end
    | Greater, Less -> begin
        match remove_downward middle k with
        | Hole(rem,t) ->
          remove_upward_three (k1,v1) (k2,v2) rem left t right Mid3
        | Absorbed(rem,t) ->
          Absorbed(rem,Three(left,(k1,v1),t,(k2,v2),right))
      end
  and remove_min (d : dict) : hole =
    match d with
    | Leaf -> Hole(None,Leaf)
    | Two(Leaf,n,_) -> Hole(Some n,Leaf)
    | Three(Leaf,n1,middle,n2,right) -> Absorbed(Some n1,Two(middle,n2,right))
    | Two(left,n,right) -> begin
        match remove_min left with
        | Hole(rem,t) -> remove_upward_two n rem t right Left2
        | Absorbed(rem,t) -> Absorbed(rem,Two(t,n,right))
      end
    | Three(left,n1,middle,n2,right) -> begin
        match remove_min left with
        | Hole(rem,t) -> remove_upward_three n1 n2 rem t middle right Left3
        | Absorbed(rem,t) -> Absorbed(rem,Three(t,n1,middle,n2,right))
      end

  let remove (d : dict) (k : key) : dict =
    match remove_downward d k with
    | Hole(_,d') -> d'
    | Absorbed(_,d') -> d'

  let rec lookup (d : dict) (k : key) : value option =
    match d with
    | Leaf -> None
    | Two (l, (x, v), r) -> begin
        match D.compare k x with
        | Less -> lookup l k
        | Eq -> Some v
        | Greater -> lookup r k
      end
    | Three (l, (x, vx), m, (y, vy), r) -> begin
        match D.compare k x, D.compare k y with
        | Less, Less -> lookup l k
        | Eq, Less -> Some vx
        | Greater, Less -> lookup m k
        | Greater, Eq -> Some vy
        | Greater, Greater -> lookup r k
        | _, _ ->
          failwith "<FATAL> lookup!"
      end

  let member (d : dict) (k : key) : bool =
    match lookup d k with
    | Some _ -> true
    | None -> false

  let rec min_pair (d : dict) : pair option = match d with
    | Two (Leaf, p, Leaf) -> Some p
    | Three (Leaf, p, Leaf, _, Leaf) -> Some p
    | Two (l, p, r) -> min_pair l
    | Three (l, p, m, q, r) -> min_pair l
    | Leaf -> None

  let choose (d : dict) : (key * value * dict) option =
    match min_pair d with
    | Some (k, v) -> Some (k, v, remove d k)
    | None -> None

  let rec _balanced (d : dict) : int = match d with
    | Leaf -> 0
    | Two (l, p, r) -> _balanced_two l r
    | Three (l, p, m, q, r) -> _balanced_three l m r
  and _balanced_two (l : dict) (r : dict) : int =
    let lheight = _balanced l in
    let rheight = _balanced r in
    if (lheight = rheight &&
      lheight <> -1 && rheight <> -1)
    then lheight + 1 else -1
  and _balanced_three (l : dict) (m : dict) (r : dict) : int =
    let lheight = _balanced l in
    let mheight = _balanced m in
    let rheight = _balanced r in
    if (lheight = mheight && mheight = rheight &&
      lheight <> -1 && mheight <> -1 && rheight <> -1)
    then lheight + 1 else -1

  let rec balanced (d : dict) : bool =
    (_balanced d <> -1)

end

module Make (D : DICTARG)
  : (TDICT with type key = D.key with type value = D.value) =
  TwoThreeDict(D)