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
(* The window as 24 rows and 80 columns *)
let y_max = 23
let x_max = 79
let y_prev = ref 0
let x_prev = ref 0
let max_colors = 6
let init (args : string list) : unit =
  let _ = (keypad win true) in ();
  let _ = (nodelay win true) in ();
  let _ = noecho() in ();
  let _ = start_color() in ();
  let _ = init_pair 1 Color.black Color.red in ();
  let _ = init_pair 2 Color.black Color.yellow in ();
  let _ = init_pair 3 Color.black Color.green in ();
  let _ = init_pair 4 Color.black Color.blue in ();
  let _ = init_pair 5 Color.black Color.cyan in ();
  let _ = init_pair 6 Color.black Color.magenta in ()

(*
Helper function to determine whether a coord (relative) is on screen
*)
let visible (y : int) (x : int) : bool =
  (0 <= y) && (y <= y_max) && (0 <= x) && (x <= x_max)
(*
Helper function to display one line.
Called by refreshcreen
TODO: support horizontal scrolling (discard parts of the line that is offscreen)
*)
let displayline (line : string) : unit =
  ignore (addstr (line ^ "\n"))


let colorcount : int ref = ref 1
(*
Helper function to generate the next color available
*)
let next_color () : int =
  let new_color = A.color_pair(!colorcount) in
  (
  if (!colorcount = max_colors) then
    colorcount := 1
  else
    incr colorcount
  );
  new_color
let colordict : (string * int) list ref = ref []
(*
Helper function to retrieve the color associated with the cursor id
*)
let getcolor (id : Cursor.id) : int =
  let id_str = Cursor.string_of_id id in
  (
  if (List.mem_assoc id_str !colordict) then
    ()
  else
  begin
    let new_color = next_color() in
    Printf.printf "Created new color %i for cursor id %s\n" new_color id_str;
    colordict := (id_str, new_color)::!colordict
  end
  ); (* create new entry in colordict if needed *)
  List.assoc id_str !colordict

(*
Helper function to display all the cursors on the screen.
*)
let rec displaycursors (cursors : Cursor.t list) : unit =
  match cursors with
  | [] -> ()
  | cur::t ->
    begin
      let id, y, x = Cursor.id cur, Cursor.y cur, Cursor.x cur in
      let y' = y - !offset in
      if (visible y' x) then
      begin
        let i = mvinch y' x in
        let color = getcolor(id) in
        attron(color);
        ignore(delch()); (* delete the original character *)
        ignore(insch(i)); (* replace with a highlighted character *)
        attroff(color);
      end
      else
        ()
    end
  ;
  displaycursors t

let scroll (y_new : int) (x_new : int) : unit =
  (* scroll up *)
  let at_top = ((!y_prev - !offset) = 0) in
  let moved_up = (y_new < !y_prev) in
  (
  if (at_top && moved_up) then
    offset := !offset - 1
  else
    ()
  );

  (* scroll down *)
  let at_bottom = ((!y_prev - !offset) = y_max) in
  let moved_down = (y_new > !y_prev) in
  (
  if (at_bottom && moved_down) then
    offset := !offset + 1
  else
    ()
  )

(* 24 rows and 80 columns *)
(* completely redraws the whole screen *)
(* takes into consideration the vertical scrolling *)
let refreshscreen (alllines : string list) (othercursors : Cursor.t list)
                  (thiscursor : Cursor.t) : unit =
  let y_new, x_new = Cursor.y thiscursor, Cursor.x thiscursor in

  (* vertical scrolling *)
  scroll y_new x_new;




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
  displaycursors othercursors;
  (* move cursor to user's cursor position *)
  let y_new' = y_new - !offset in
  if (visible y_new' x_new) then
  begin
    ignore(move y_new' x_new);
    attron(WA.underline);
    let i = inch() in
    ignore(delch()); (* delete the original character *)
    ignore(insch(i)); (* replace with a colored character *)
    attroff(WA.underline);
  end
  else
    ();

  y_prev := y_new; (* should probably move this after display cursor *)
  ignore(refresh())


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