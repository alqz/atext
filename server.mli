(* server *)

(* Stores whether this server acts as a host or a visitor
 * Stores reading/writing buffers as part of the TCP connections
 * Keeps track of current connections
 *)
type t

(* Contains an internal mutable data structure including writing and
 * reading buffers
 *)

(**
 * Used by the file host. The returned value is guaranteed to be determined
 * immediately.
 * returns 0 if success, 1 otherwise
 *)
val init_server : unit -> int Deferred.t

(**
 * Used by a visitor. The returned value is determined either when a conneciton
 * with the given host address has been established or when the connection
 * initialization has failed.
 * returns 0 if success, 1 otherwise
 *)
val init_client : Socket.Address.t -> int Deferred.t

(**
 * Gets determined with incoming instructions when they arrive. New
 * instructions may occumulate after this deferred value is determined, and
 * to access them this function should be called again.
 *)
val occumulated_instructions : unit -> Instruction.t Deferred.t

(* returns 0 if success, 1 otherwise
 * If host then sends to all visitors server is currently connected to
 * If client then send to the host
val send : Instruction.t -> int

