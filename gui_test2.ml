open Gui
open Curses

let no_of_lines = 50 in
let testlines = ref [] in
for i=no_of_lines downto 0 do
  let s = "This is line number "
          ^ (string_of_int i)
          ^ " of " ^ (string_of_int no_of_lines)
          ^ ". Press any key to continue"
  in
  testlines := s::!testlines
done;
let testcursors = ref [] in
for i = 0 to no_of_lines do
  testcursors := (i,i)::!testcursors
done;
init [];
refreshscreen !testlines !testcursors (0,0);
while true do
  testlines := !testlines
done;
endwin()
