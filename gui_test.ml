open Gui
open Curses
init [];
let testlines = ref [] in
for i=30 downto 1 do
  let s = "This is line number "
          ^ (string_of_int i)
          ^ ". Press any key to continue"
  in
  testlines := s::!testlines
done;
setoffset 0;
refreshscreen !testlines [(0,0);(1,1);(2,2);(3,3)];

pausescreen();
endwin ()