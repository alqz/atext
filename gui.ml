open Curses

type input =
  | Leave
  | Backspace
  | Delete
  | Enter
  | Up | Down | Left | Right
  | Character of char
  | Nothing

let win = initscr()
let offset = ref 0
let y_prev = ref 0
let x_prev = ref 0
let init (args : string list) : unit =
  let _ = (keypad win true) in ();
  let _ = (nodelay win true) in ();
  let _ = noecho() in ();
  let _ = start_color() in ();
  let _ = init_pair 1 Color.red Color.black in ()

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
let refreshscreen (alllines : string list) (allcursors : (int*int) list)
                  (y_new, x_new : int * int) : unit =
  (* vertical scrolling *)

  (* scroll up *)
  let at_top = ((!y_prev - !offset) = 0) in
  (
  if (at_top && (y_new < !y_prev)) then
    offset := !offset - 1
  else
    ()
  );

  (* scroll down *)
  let at_bottom = ((!y_prev - !offset) = 23) in
  (
  if (at_bottom && (y_new > !y_prev)) then
    offset := !offset + 1
  else
    ()
  );



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
  (* move cursor to user's cursor position *)
  ignore(move y_new x_new);
  attron(A.color_pair(1));
  let i = inch() in
  ignore(delch()); (* delete the original character *)
  ignore(insch(i)); (* replace with a colored character *)
  attroff(A.color_pair(1));
  y_prev := y_new (* should probably move this after display cursor *)

let poll_keyboard () : input =
  let i = getch() in
  if (i = Key.backspace) then
    Backspace
  else if (i = Key.enter) then
    Enter
  else if (i = 330) then (* delete key *)
    Delete
  else if (i = Key.up) then
    Up
  else if (i = Key.down) then
    Down
  else if (i = Key.left) then
    Left
  else if (i = Key.right) then
    Right
  else if (i = 27) (* the Escape key *) then
    Leave
  else if ((i >= 0) && (i <= 255)) then (* forward all other characters *)
    Character(Char.chr i)
  else (* Reject everything else, including -1 which is no key typed *)
    Nothing

(* For testing only *)
let pausescreen () : unit =
  let _ = nodelay win false in
  ignore (getch())

(* For testing only *)
let setoffset (i : int) : unit =
  offset := i