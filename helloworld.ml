open Curses
let win = initscr()
let _ = (keypad win true) in ();
let _ = (nodelay win true) in ();
let _ = noecho () in ();


ignore (refresh ());
while true do
  ignore(
    let c : int = getch () in
    let (y,x) = getyx win in
    if (c = -1) then
      false
    else if (c = Key.up) then
      move (y-1) x
    else if (c = Key.down) then
      move (y+1) x
    else if (c = Key.left) then
      move y (x-1)
    else if (c = Key.right) then
      move y (x+1)
    else if (c = Key.enter) then
      addch c
    else
      begin
        ignore (insch c);
        move y (x+1)
      end
  )
done;
endwin ()