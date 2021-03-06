open Auxiliary
open Async.Std
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
let voffset = ref 0
let hoffset = ref 0
let std = Lazy.force (Reader.stdin)
(* By default, the window as 24 rows and 80 columns *)
let y_max = ref (fst (getmaxyx win) - 1)
let x_max = ref (snd (getmaxyx win) - 1)
let y_prev = ref 0
let x_prev = ref 0
let max_colors = 6

let init (args : string list) : unit =
  let _ = start_color () in ();
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
  (0 <= y) && (y <= !y_max) && (0 <= x) && (x <= !x_max)

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
    (* Printf.printf "Created new color %i for cursor id %s\n" new_color id_str; *)
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
      let y' = y - !voffset in
      let x' = x - !hoffset in
      if (visible y' x') then
      begin
        let i = mvinch y' x' in
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
  let at_top = ((!y_prev - !voffset) = 0) in
  let moved_up = (y_new < !y_prev) in
  (
  if (at_top && moved_up) then
    voffset := !voffset - 1
  else
    ()
  );

  (* scroll down *)
  let at_bottom = ((!y_prev - !voffset) = !y_max) in
  let moved_down = (y_new > !y_prev) in
  (
  if (at_bottom && moved_down) then
    voffset := !voffset + 1
  else
    ()
  );

  (* new scroll right *)
  while (x_new > (!hoffset + !x_max - 1)) do
    hoffset := !hoffset + !x_max + 1
  done;

  (* new scroll left *)
  while (x_new < !hoffset) do
    hoffset := !hoffset - !x_max - 1
  done

(*
Helper function to display one line.
Called by refreshcreen
*)
let displayline (line : string) : unit =
  let l = String.length line in
  if (l > !hoffset) then
  begin
    if (l >= (!hoffset + !x_max + 1)) then

    begin
      (* The line has characters to the right of the current view *)
      ignore(addstr (String.sub line (!hoffset) (!x_max + 1)))
    end
    else
    begin
      (* The line fits within the screen after hoffset *)
      ignore(addstr (String.sub line !hoffset (l - !hoffset)));
      ignore(addstr "\n")
    end
  end
  else
    (* the line entirely to the left of the current view *)
    ignore(addstr "\n")

  (* ignore (addstr (line ^ "\n")) *)

(* 24 rows and 80 columns *)
(* completely redraws the whole screen *)
(* takes into consideration the vertical scrolling and horizontal scrolling *)
let refreshscreen (alllines : string list) (othercursors : Cursor.t list)
                  (thiscursor : Cursor.t) : unit =
  let y_new, x_new = Cursor.y thiscursor, Cursor.x thiscursor in
  (* handle scrolling *)
  scroll y_new x_new;
  (* clear the whole screen *)
  clear();
  let lines = ref alllines in
  (* discard lines above the current view *)
  for i = 1 to !voffset do
    match !lines with
      | [] -> () (* run out of lines - shouldn't happen *)
      | h::t -> lines := t
  done;
  (* display the 24 lines in view *)
  for i = 1 to (!y_max+1) do
    match !lines with
    | [] -> () (* no more lines to display *)
    | h::t ->
      begin
        displayline h;
        (* ignore(addstr "\n"); *)
        lines := t
      end
  done;
  (* display the cursors in view *)
  displaycursors othercursors;
  (* move cursor to user's cursor position *)
  let y_new' = y_new - !voffset in
  let x_new' = x_new - !hoffset in
  if (visible y_new' x_new') then
  begin
    ignore(move y_new' x_new');
    attron(WA.underline);
    let i = inch() in
    ignore(delch()); (* delete the original character *)
    ignore(insch(i)); (* replace with a colored character *)
    attroff(WA.underline);
  end
  else
    ();

  y_prev := y_new;
  x_prev := x_new;

  let _ = refresh () in

  let other_c_coords : string = List.fold_left (fun acc c ->
      acc ^ (Cursor.string_of_t c) ^ "; "
    ) "" othercursors in
  pd (string_of_int (List.length othercursors));
  pd other_c_coords;
  ()

(* Uncomment this to disable GUI. *)
(* let refreshscreen a b c : unit = () *)

let string_to_clist str =
  let rec aux inx str lst =
    if inx < 0 then lst else
    aux (inx - 1) str ((String.get str inx) :: lst) in
  aux (String.length str - 1) str []

let poll_keyboard () : input Deferred.t =
  let buf = String.make 3 '_' in
  Reader.read std buf >>= fun status ->
  if status = `Eof then failwith "stdin disconnected" else
  let info = List.map Char.code (string_to_clist buf) in
  let result =
    match info with
    | [  8; 95; 95] -> return Backspace
    | [ 13; 95; 95] -> return Enter
    | [127; 95; 95] -> if Sys.os_type = "Win32" then return Delete
                       else return Backspace
    | [ 27; 91; 65] -> return Up
    | [ 27; 91; 66] -> return Down
    | [ 27; 91; 68] -> return Left
    | [ 27; 91; 67] -> return Right
    | [ 27; 95; 95] -> return Leave
    | [ id; 95; 95] -> return (Character(Char.chr id))
    | _ -> return Nothing in
  result

let update_winsize () : unit =
  y_max := fst (getmaxyx win) - 1;
  x_max := snd (getmaxyx win) - 1

let terminate () : unit =
  endwin()

(* For testing only *)

let init_old () : unit =
  let _ = (keypad win true) in ();
  let _ = (nodelay win true) in ();
  let _ = noecho () in ()

let pausescreen () : unit =
  let _ = nodelay win false in
  ignore (getch())

(* For testing only *)
let setvoffset (i : int) : unit =
  voffset := i

(* For testing only *)
let sethoffset (i : int) : unit =
  hoffset := i

(* For testing only *)
let setdelay () : unit =
  ignore(nodelay win false)