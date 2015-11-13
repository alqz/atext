(* server *)

type t

(**
 * Used by the file host. The returned value is guaranteed to be determined
 * immediately.
 *)
val init_server : unit -> Server.t Deferred.t

(**
 * Used by a visitor. The returned value is determined either when a conneciton
 * with the given host address has been established or when the connection
 * initialization has failed.
 *)
val init_client : Socket.Address.t -> Server.t Deferred.t

(**
 * Gets determined with incoming instructions when they arrive. New
 * instructions may occumulate after this deferred value is determined, and
 * to access them this function should be called again.
 *)
val occumulated_instructions : unit -> intruction list Deferred.t

