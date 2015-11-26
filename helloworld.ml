open Curses

let _ = initscr () in ();
ignore (addstr  "Helloworld!!!");
ignore (refresh ());
ignore (getch ());
endwin ()