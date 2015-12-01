open Async.Std

(* This function lets me change what print function is used later on,
 * if necessary. *)
let po s : unit = print_endline s
(* Print function for debugging. *)
let pd s : unit = ()
  (* print_endline ("<!> " ^ s) *)

let job (name : string) (t : float) : string Deferred.t =
  po ("starting " ^ name);
  after (Core.Std.sec t) >>= fun _ ->
  po ("finished " ^ name);
  return name

let both (d1 : 'a Deferred.t) (d2 : 'b Deferred.t) : ('a * 'b) Deferred.t =
  d1 >>= fun det1 ->
  d2 >>= fun det2 ->
  return (det1, det2)

(* [draw] draws [drawing] onto [page] if the [page] is blank.
 * Of course, this is a metaphor for Ivar fill if empty. *)
let draw (page : 'a Ivar.t) (drawing : 'a) : unit =
  if Ivar.is_empty page then Ivar.fill page drawing else ()

(* For reference only. *)
let either (d1 : 'a Deferred.t) (d2 : 'a Deferred.t) : 'a Deferred.t =
  let page : 'a Ivar.t = Ivar.create () in
  d1 >>> draw page; d2 >>> draw page;
  Ivar.read page

let fork (d : 'a Deferred.t) (f1 : 'a -> 'b Deferred.t)
                             (f2 : 'a -> 'c Deferred.t) : unit =
  d >>> fun d -> ignore (f1 d); ignore (f2 d); ()

let all_sequential (f : 'a -> 'b Deferred.t) (l : 'a list)
                   : 'b list Deferred.t =
  (List.fold_left (fun bld a ->
    bld >>= fun bl ->
    f a >>= fun b ->
    return (b :: bl)
  ) (return []) l) >>= fun bld' ->
  return (List.rev_append bld' [])

(* Reverses twice, mainly because this implementation is tail-recursive. *)
let all_parallel (f : 'a -> 'b Deferred.t) (l : 'a list)
                 : 'b list Deferred.t =
  List.fold_left (fun bld bd ->
    bld >>= fun bl ->
    bd >>= fun b ->
    return (b :: bl)
  ) (return []) (List.rev_map f l)

let any (ds : 'a Deferred.t list) : 'a Deferred.t =
  let page : 'a Ivar.t = Ivar.create () in
  List.fold_left (fun _ d -> d >>> draw page) () ds;
  Ivar.read page