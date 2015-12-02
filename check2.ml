open Gui
open Async.Std

let rec check () =
  poll_keyboard () >>= fun x ->
  begin match x with
  | Backspace -> print_endline "Backspace"
  | Enter -> print_endline "Enter"
  | Delete -> print_endline "Delete"
  | Up -> print_endline "Up"
  | Down -> print_endline "Down"
  | Left -> print_endline "Left"
  | Right -> print_endline "Right"
  | Leave -> print_endline "Leave"
  | Character c -> print_endline ("Character "^Char.escaped c)
  | Nothing -> print_endline "Nothing" end;
  check ()

let _ = check ()

let _ = Scheduler.go()