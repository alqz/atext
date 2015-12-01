open Gui
open Curses

let no_of_lines = 30 in
let testlines = ref [] in
for i=no_of_lines downto 0 do
  let s = "This is line number "
          ^ (string_of_int i)
          ^ " of " ^ (string_of_int no_of_lines)
          ^ ". Press any key to continue 123456789012345678901234567890"
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
for i=0 to (no_of_lines-23) do
  setvoffset i;
  refreshscreen !testlines !testcursors mycursor;
  pausescreen();
done;

for i=1 to 8 do
  sethoffset i;
  refreshscreen !testlines !testcursors mycursor;
  pausescreen();
done;

for i=7 downto 0 do
  sethoffset i;
  refreshscreen !testlines !testcursors mycursor;
  pausescreen();
done;

for i=(no_of_lines-24) downto 0  do
  setvoffset i;
  refreshscreen !testlines !testcursors mycursor;
  pausescreen();
done;

(* sethoffset 80;
refreshscreen !testlines !testcursors mycursor;
pausescreen();

sethoffset 0;
refreshscreen !testlines !testcursors mycursor;
pausescreen(); *)

endwin()
