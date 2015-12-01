open Gui
open Curses

let no_of_lines = 24 in
let testlines = ref [] in
for i=no_of_lines downto 0 do
  let s = "This is line number "
          ^ (string_of_int i)
          ^ " of " ^ (string_of_int no_of_lines)
          ^ ". Press any key to continue"
  in
  testlines := s::!testlines
done;
let testcursors : Cursor.t list ref = ref [] in
let rec diagmovecursor (c : Cursor.t) (n : int) : Cursor.t =
  if (n = 0) then
    c
  else
    diagmovecursor (Cursor.move c 1 1) (n-1)
in
for i = 0 to no_of_lines do
  let c = Cursor.new_cursor() in
  testcursors := (diagmovecursor c i)::!testcursors
done;
init [];
let mycursor = Cursor.new_cursor() in
refreshscreen !testlines [] mycursor;
pausescreen();
for i=0 to no_of_lines do
  setvoffset i;
  refreshscreen !testlines !testcursors mycursor;
  pausescreen();
done;
endwin()
