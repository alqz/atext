open Curses
let win = initscr()
let _ = (keypad win true) in ();
(* let _ = (nodelay win true) in (); *)
let _ = noecho () in ();


ignore (refresh ());
while true do
  let c : int = getch () in
  ignore(addstr ((string_of_int c) ^ "\n"));
done;
endwin ()