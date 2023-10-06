module Status : sig
  type t
  (** A wrapper for [sentencepiece::util::Status]. *)

  val to_string : t -> string
  val of_int : int -> t
end

module Processor : sig
  type t
  (** A wrapper for [sentencepiece::SentencePieceProcessor]. *)

  type config = { bos : bool; eos : bool; unk : bool; reverse : bool }

  val default_config : config

  val load_model : ?config:config -> string -> (t, string) result
  (** [load_model model_path] creates a [Processor.t] using the model file at [model_path]. *)

  val encode_pieces : t -> string -> string list
  (** [encode_pieces t input] encodes a UTF8 input into a sequences of string tokens. *)

  val decode_pieces : t -> string list -> string
  (** [decode_pieces t pieces] restore a sequence of string tokens to its original string. *)

  val encode_ids :
    t ->
    string ->
    (int32, Bigarray.int32_elt, Bigarray.c_layout) Bigarray.Array1.t
  (** [encode_ids t input] encodes a UTF8 input into a sequence of ids. *)

  val encode_int64_ids :
    t ->
    string ->
    (int64, Bigarray.int64_elt, Bigarray.c_layout) Bigarray.Array1.t
  (** [encode_int64_ids t input] encodes a UTF8 input into a sequence of int64 ids. *)

  val pp_int64_array1 :
    Format.formatter ->
    (int64, Bigarray.int64_elt, Bigarray.c_layout) Bigarray.Array1.t ->
    unit
end
