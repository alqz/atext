open Gui
open Curses

let no_of_lines = 50 in
let testlines = ref [] in
for i=no_of_lines downto 0 do
  let s = "This is line number "
          ^ (string_of_int i)
          ^ " of " ^ (string_of_int no_of_lines)
          ^ ". The screen stays here"
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
refreshscreen !testlines !testcursors mycursor;
while true do
  testlines := !testlines
done;
endwin()
