open Async.Std
open Gui
open Curses

(* let _ =
  match Unix.system "/bin/stty raw" with
  | _ -> ()
  | Unix.WEXITED code -> print_endline ("exit code "^(string_of_int code))
  | WSIGNALED code -> print_endline ("kill signal code "^(string_of_int code))
  | WSTOPPED code -> print_endline ("stop signal code "^(string_of_int code)) *)


let string_to_clist str =
  let rec aux inx str lst =
    if inx < 0 then lst else
    aux (inx - 1) str ((String.get str inx) :: lst) in
  aux (String.length str - 1) str []

let code_str lst =
  let rec aux str = function
  | [] -> str
  | h :: t -> aux (str ^ " " ^(string_of_int (Char.code h))) t in
  aux "" lst

let _ = init []

let testlines = ref []

let std = Lazy.force (Reader.stdin)

let buf = ref "___"

let rec check () =
  Reader.read std (!buf) >>= fun _ ->
  testlines:=((!buf) |> string_to_clist |> code_str):: (!testlines);
  refreshscreen (!testlines) [] (Cursor.new_cursor());
  check ()

let _ = check ()

let _ =
  refreshscreen (["asdfasdfasdf"]) [] (Cursor.new_cursor())

let _ =
  refreshscreen (["abc123"]) [] (Cursor.new_cursor())



(*
let _ =
  refreshscreen ["process terminating press any key"] [] (0,0);
  pausescreen();
  endwin()
*)

let _ = Scheduler.go()