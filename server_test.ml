open Server
open Async.Std

let _ =
  init_server 8080 1 >>= fun _ ->
  return (print_endline "server started!")

let _ = Scheduler.go()