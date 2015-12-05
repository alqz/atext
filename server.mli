open Async.Std

(* server *)

(* Contains an internal mutable data structure including writing and
 * reading buffers
 *)

(**
 * Used by the file host. The returned value is guaranteed to be determined
 * immediately.
 * Arg1: port number on which the file is hosted. Make this number high
 * Arg2: max number of collaborators, not including host
 * (> 6000). The more obscure the number is the less likely it is currently
 * used. If you get an error it may mean that the port is currently in use,
 * so you should try changing it.
 * returns 0 if success, 1 otherwise
 *)
val init_server : int -> int -> int Deferred.t

(**
 * Used by a visitor. The returned value is determined either when a conneciton
 * with the given host address has been established or when the connection
 * initialization has failed.
 * Arg1: the address of the host. Can be in IP form "1.2.3.4" or DNS form
 * "www.example.com" ('www' is important)
 * Arg2: destination port number (the port the host uses)
 * returns 0 if success, 1 otherwise
 *)
val init_client : string -> int -> int Deferred.t
(* CONSIDER : change to
 * val init_client : string -> int -> (int * Yojson.Basic.json) Deferred.t
 *)

(**
 * Gets determined with incoming instructions when they arrive. New
 * instructions may occumulate after this deferred value is determined, and
 * to access them this function should be called again.
 *)
val occumulated_instruction : unit -> Instruction.t Deferred.t

(* returns 0 if success, 1 otherwise
 * If host then sends to all visitors server is currently connected to
 * If client then send to the host
 *)
val send : Instruction.t -> int
(* CONSIDER: change to
 * val send : Yojson.Basic.json -> int
 *)

(* CONSIDER: add
 * val send_state : Yojson.Basic.json -> int
 *)