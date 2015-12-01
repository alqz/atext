open Async.Std

val both : 'a Deferred.t -> 'b Deferred.t -> ('a * 'b) Deferred.t

val either : 'a Deferred.t -> 'a Deferred.t -> 'a Deferred.t

val fork : 'a Deferred.t -> ('a -> 'b Deferred.t)
                         -> ('a -> 'c Deferred.t) -> unit

val all_sequential : ('a -> 'b Deferred.t) -> 'a list -> 'b list Deferred.t

val all_parallel : ('a -> 'b Deferred.t) -> 'a list -> 'b list Deferred.t

val any : 'a Deferred.t list -> 'a Deferred.t