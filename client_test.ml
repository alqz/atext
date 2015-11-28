open Server
open Async.Std

let _ =
  init_client "localhost" 8080 >>= fun _ ->
  return (print_endline "client connected!")

let _ = Scheduler.go()