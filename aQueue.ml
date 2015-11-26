open Async.Std

type 'a node = {
  content : 'a Ivar.t;
  mutable next : 'a node option;
}

(* Invariant: read = write <=> head = None <=> tail = None => queue empty *)
type 'a t = {
  mutable head : 'a node option;
  mutable tail : 'a node option;
  mutable read  : int;
  mutable write : int;
}

let deoption_and_if_None_failwith item msg =
  match item with
  | None -> failwith msg
  | Some t -> t

let create () = {
  head = None;
  tail = None;
  read  = 0;
  write = 0;
}

let push q x =
  (* empty queue *)
  if q.read = q.write then
    begin assert (q.head = None && q.tail = None);
    let new_node = {content = Ivar.create(); next = None} in
    Ivar.fill new_node.content x;
    q.head <- Some new_node;
    q.tail <- Some new_node;
    q.write <- q.write + 1 end
  (* queue has excess items, append new value at tail *)
  else if q.write > q.read then
    begin assert (q.head <> None && q.tail <> None);
    let new_node = {content = Ivar.create(); next = None} in
    Ivar.fill new_node.content x;
    let tl_item = deoption_and_if_None_failwith q.tail "Violates invariant" in
    assert (tl_item.next = None);
    tl_item.next <- Some new_node;
    q.tail <- tl_item.next;
    q.write <- q.write + 1 end
  (* queue has excess read requests, feed and remove the earliest one
     (head node) *)
  else
    begin assert (q.head <> None && q.tail <> None);
    let hd_item = deoption_and_if_None_failwith q.head "Violates invariant" in
    assert (Ivar.is_empty hd_item.content);
    Ivar.fill hd_item.content x;
    q.head <- hd_item.next;
    if q.head = None then q.tail <- None else ();
    q.write <- q.write + 1 end


let pop q =
  (* empty queue *)
  if q.read = q.write then
    begin assert (q.head = None && q.tail = None);
    let new_node = {content = Ivar.create(); next = None} in
    q.head <- Some new_node;
    q.tail <- Some new_node;
    q.read <- q.read + 1;
    Ivar.read new_node.content end
  (* queue has excess read requests, append new read at tail *)
  else if q.read > q.write then
    begin assert (q.head <> None && q.tail <> None);
    let new_node = {content = Ivar.create(); next = None} in
    let tl_item = deoption_and_if_None_failwith q.tail "Violates invariant" in
    assert (tl_item.next = None);
    tl_item.next <- Some new_node;
    q.tail <- tl_item.next;
    q.read <- q.read + 1;
    Ivar.read new_node.content end
  else (* if q.read < q.write *)
    begin assert (q.head <> None && q.tail <> None);
    let hd_item = deoption_and_if_None_failwith q.head "Violates invariant" in
    assert (Ivar.is_full hd_item.content);
    q.head <- hd_item.next;
    if q.head = None then q.tail <- None else ();
    q.read <- q.read + 1;
    Ivar.read hd_item.content end

(* either if queue really is empty or if there are pending read requests *)
let is_empty q = q.read >= q.write

