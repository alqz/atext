open Async.Std
open Gui
open Curses

(* let _ =
  match Unix.system "/bin/stty raw" with
  | _ -> ()
  | Unix.WEXITED code -> print_endline ("exit code "^(string_of_int code))
  | WSIGNALED code -> print_endline ("kill signal code "^(string_of_int code))
  | WSTOPPED code -> print_endline ("stop signal code "^(string_of_int code)) *)

let _ = init []

let testlines = ref []

let std = Lazy.force (Reader.stdin)

let rec check () =
  Reader.read_char std >>= fun x ->
  begin match x with
  | `Eof -> Pervasives.exit 0
  | `Ok chr ->
        testlines:=(string_of_int (Char.code chr)):: (!testlines);
        testlines:=(string_of_int (getch())) :: (!testlines);
        refreshscreen (!testlines) [] (Cursor.new_cursor()) end;
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