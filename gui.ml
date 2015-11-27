open Curses
let win = initscr()
let offset = ref 0

let init (args : string list) : unit =
  let _ = (keypad win true) in ();
  let _ = (nodelay win true) in ();
  let _ = noecho () in ()

let displayline (line : string) : unit =
  ignore (addstr (line ^ "\n"))

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
        ignore(insch(i)); (*replace with a highlighted character *)
        displaycursors t
      end
      else
        ()
    end

(* 24 rows and 80 columns *)
let refreshscreen (alllines : string list) (allcursors : (int*int) list) : unit =
  let lines = ref alllines in
  for i = 1 to !offset do (* discard lines above the current view *)
    match !lines with
      | [] -> () (* run out of lines - shouldn't happen *)
      | h::t -> lines := t
  done;
  for i = 1 to 24 do (* display the 24 lines in view *)
    match !lines with
    | [] -> () (* no more lines to display *)
    | h::t ->
      begin
        displayline h;
        lines := t
      end
  done;
  attron(WA.standout);
  displaycursors allcursors;
  attroff(WA.standout);
  ignore(move 23 79) (* TODO: move cursor to suitable location *)


let scroll_up () : unit =
  ()

let scroll_down () : unit =
  ()

let poll_keyboard () : char =
  let i = getch() in
  if (i = Key.backspace) then
    '\b'
  else if (i = Key.enter) then
    '\n'
  else if (i = 330) then (* delete key *)
    Char.chr 127 (* ASCII for delete *)
  else if ((i >= 0) && (i <= 255)) then (* forward all other characters *)
    Char.chr i
  else (* Reject everything else, including -1 which is no key typed *)
    '\r'

let pausescreen () : unit =
  let _ = nodelay win false in
  ignore (getch())

let setoffset (i : int) : unit =
  offset := i