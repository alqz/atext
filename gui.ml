open Curses
let win = initscr()
let offset = ref 0

let init (args : string list) : unit =
  let _ = (keypad win true) in ();
  let _ = (nodelay win true) in ();
  let _ = noecho () in ()

(*
Helper function to display one line.
Called by refreshcreen
TODO: support horizontal scrolling (discard parts of the line that is offscreen)
*)
let displayline (line : string) : unit =
  ignore (addstr (line ^ "\n"))
(*
Helper function to display all the cursors on the screen.
*)
let rec displaycursors (cursors : (int*int) list) : unit =
  match cursors with
  | [] -> ()
  | (y,x)::t ->
    begin
      let y' = y - !offset in
      if ((0 <= y') && (y' <= 23) && (0 <= x) && (x <= 79)) then
      begin
        let i = mvinch y' x in
        ignore(delch()); (* delete the original character *)
        ignore(insch(i)); (* replace with a highlighted character *)
      end
      else
        ()
    end
  ;
  displaycursors t


(* 24 rows and 80 columns *)
(* completely redraws the whole screen *)
(* takes into consideration the vertical scrolling *)
let refreshscreen (alllines : string list) (allcursors : (int*int) list) : unit =
  clear();
  let lines = ref alllines in
  (* discard lines above the current view *)
  for i = 1 to !offset do
    match !lines with
      | [] -> () (* run out of lines - shouldn't happen *)
      | h::t -> lines := t
  done;
  (* display the 24 lines in view *)
  for i = 1 to 24 do
    match !lines with
    | [] -> () (* no more lines to display *)
    | h::t ->
      begin
        displayline h;
        lines := t
      end
  done;
  (* display the cursors in view *)
  attron(WA.standout);
  displaycursors allcursors;
  attroff(WA.standout);
  (* TODO: move cursor to suitable location *)
  ignore(move 23 79)


let scroll_up () : unit =
  ()

let scroll_down () : unit =
  ()

let poll_keyboard (y : int) (x : int) : char =
  let i = getch() in
  let y' = y - !offset in
  if (i = Key.up) then
    begin
      (* catch scrolling up *)
      (
        if (y' = 0) then
          offset := !offset - 1
        else
          ()
      );
      Char.chr i (* forward the up key *)
    end
  else if (i = Key.down) then
    begin
      (* catch scrolling down *)
      (
        if (y' = 23) then
          offset := !offset + 1
        else
          ()
      );
      Char.chr i (* forward the up key *)
    end
  else if (i = Key.backspace) then
    '\b'
  else if (i = Key.enter) then
    '\n'
  else if (i = 330) then (* delete key *)
    Char.chr 127 (* ASCII for delete *)
  else if ((i >= 0) && (i <= 255)) then (* forward all other characters *)
    Char.chr i
  else (* Reject everything else, including -1 which is no key typed *)
    '\r'

(* For testing only *)
let pausescreen () : unit =
  let _ = nodelay win false in
  ignore (getch())

(* For testing only *)
let setoffset (i : int) : unit =
  offset := i