open Gui
open Curses
init [];
let testlines = ref [] in
for i=30 downto 1 do
  testlines := ("This is line number " ^ (string_of_int i))::!testlines
done;
setoffset 0;
refreshscreen !testlines [(0,0);(1,1);(2,2);(3,3)];
pausescreen();
endwin ()