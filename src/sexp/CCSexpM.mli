(*
Copyright (c) 2013, Simon Cruanes
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.  Redistributions in binary
form must reproduce the above copyright notice, this list of conditions and the
following disclaimer in the documentation and/or other materials provided with
the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)

(** {1 Simple and efficient S-expression parsing/printing}

@since 0.7 *)

type 'a or_error = [ `Ok of 'a | `Error of string ]
type 'a sequence = ('a -> unit) -> unit
type 'a gen = unit -> 'a option

(** {2 Basics} *)

type t = [
  | `Atom of string
  | `List of t list
  ]
type sexp = t

(** {2 Serialization (encoding)} *)

val to_buf : Buffer.t -> t -> unit

val to_string : t -> string

val to_file : string -> t -> unit

val to_file_seq : string -> t sequence -> unit
(** Print the given sequence of expressions to a file *)

val to_chan : out_channel -> t -> unit

val print : Format.formatter -> t -> unit
(** Pretty-printer nice on human eyes (including indentation) *)

val print_noindent : Format.formatter -> t -> unit
(** Raw, direct printing as compact as possible *)

(** {2 Deserialization (decoding)} *)

module type MONAD = sig
  type 'a t
  val return : 'a -> 'a t
  val (>>=) : 'a t -> ('a -> 'b t) -> 'b t
end

type 'a parse_result = ['a or_error | `End ]
(** A parser of ['a] can return [`Ok x] when it parsed a value,
    or [`Error e] when a parse error was encountered, or
    [`End] if the input was empty *)

module MakeDecode(M : MONAD) : sig
  type t
  (** Decoder *)

  val make : ?bufsize:int -> (Bytes.t -> int -> int -> int M.t) -> t
  (** Make a decoder with the given function used to refill an
      internal buffer. The function might return [0] if the
      input is exhausted.
      @param bufsize size of internal buffer *)

  val next : t -> sexp parse_result M.t
  (** Parse the next S-expression or return an error if the input isn't
      long enough or isn't a proper S-expression *)
end

val parse_string : string -> t or_error
(** Parse a string *)

val parse_chan : ?bufsize:int -> in_channel -> t or_error
(** Parse a S-expression from the given channel. Can read more data than
    necessary, so don't use this if you need finer-grained control (e.g.
    to read something else {b after} the S-exp) *)

val parse_chan_gen : ?bufsize:int -> in_channel -> t or_error gen
(** Parse a channel into a generator of S-expressions *)

val parse_chan_list : ?bufsize:int -> in_channel -> t list or_error

val parse_file : string -> t or_error
(** Open the file and read a S-exp from it *)

val parse_file_list : string -> t list or_error
(** Open the file and read a S-exp from it *)
