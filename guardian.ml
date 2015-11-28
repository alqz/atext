(* guardian.ml
 * Updated 151126 by Albert Zhang
 * For ATEXT text-editor project.
 *)

let pen_check (st : State.t) (it : Instruction.t) : bool =
  if it.file = st.get_name then
    match it.op with
    | Add ch -> begin match State.add st it.cursor ch with
    	| Some st' -> (st', true)
    	| None -> (st, false)
      end
    | Move d -> begin match d with
    	| Up -> begin match State.up st it.cursor with
    	    | Some st' -> (st', true)
    	    | None -> (st, false) end
    	| Down -> begin match State.down st it.cursor with
    	    | Some st' -> (st', true)
    	    | None -> (st, false) end
    	| Left -> begin match State.dec st it.cursor with
    	    | Some st' -> (st', true)
    	    | None -> (st, false) end
    	| Right -> begin match State.inc st it.cursor with
    	    | Some st' -> (st', true)
    	    | None -> (st, false) end
      end
    | New -> begin match State.add_cursor st it.cursor with
        | Some st' -> (st', true)
        | None -> (st, false)
  else (st, false)

let pen_filter (st : State.t) (itl : Instruction.t list) =
  let (st', itl') = List.fold_left (fun (st, passed) it ->
      match pen_check st it with
  	  | Some st' -> (st', it :: passed)
  	  | None -> (st, passed)
    ) (st, []) itl in
  st', List.rev_append itl' []