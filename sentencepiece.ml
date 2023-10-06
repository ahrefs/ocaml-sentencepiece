open Sentencepiece_ffi

module Util = struct
  open Ctypes
  module U = Ffi.Functions.Util

  (* Taken from [Core_kernel.Gc]. *)
  let zero = Sys.opaque_identity (int_of_string "0")

  (* The compiler won't optimize int_of_string away so it won't
     perform constant folding below. *)
  let rec keep_alive o = if zero <> 0 then keep_alive (Sys.opaque_identity o)
  let free_ptr p = U.free_ptr @@ to_voidp p

  let free_ptr_arr typ p size =
    let void_p = coerce (ptr typ) (ptr (ptr void)) p in
    U.free_ptr_arr void_p size
end

module Status = struct
  (* from sentencepiece::util::StatusCode.
      https://github.com/google/sentencepiece/blob/master/src/sentencepiece_processor.h#L34 *)
  type t =
    [ `kOk
    | `kCancelled
    | `kUnknown
    | `kInvalidArgument
    | `kDeadlineExceeded
    | `kNotFound
    | `kAlreadyExists
    | `kPermissionDenied
    | `kResourceExhausted
    | `kFailedPrecondition
    | `kAborted
    | `kOutOfRange
    | `kUnimplemented
    | `kInternal
    | `kUnavailable
    | `kDataLoss
    | `kUnauthenticated ]

  let of_int = function
    | 0 -> `kOk
    | 1 -> `kCancelled
    | 2 -> `kUnknown
    | 3 -> `kInvalidArgument
    | 4 -> `kDeadlineExceeded
    | 5 -> `kNotFound
    | 6 -> `kAlreadyExists
    | 7 -> `kPermissionDenied
    | 8 -> `kResourceExhausted
    | 9 -> `kFailedPrecondition
    | 10 -> `kAborted
    | 11 -> `kOutOfRange
    | 12 -> `kUnimplemented
    | 13 -> `kInternal
    | 14 -> `kUnavailable
    | 15 -> `kDataLoss
    | 16 -> `kUnauthenticated
    | _ -> failwith "invalid status code"

  let to_string = function
    | `kOk -> "Ok"
    | `kCancelled -> "Cancelled"
    | `kUnknown -> "Unknown"
    | `kInvalidArgument -> "InvalidArgument"
    | `kDeadlineExceeded -> "DeadlineExceeded"
    | `kNotFound -> "NotFound"
    | `kAlreadyExists -> "AlreadyExists"
    | `kPermissionDenied -> "PermissionDenied"
    | `kResourceExhausted -> "ResourceExhausted"
    | `kFailedPrecondition -> "FailedPrecondition"
    | `kAborted -> "Aborted"
    | `kOutOfRange -> "OutOfRange"
    | `kUnimplemented -> "Unimplemented"
    | `kInternal -> "Internal"
    | `kUnavailable -> "Unavailable"
    | `kDataLoss -> "DataLoss"
    | `kUnauthenticated -> "Unauthenticated"

  let raise_if_error status =
    match status with
    | 0 -> ()
    | status -> failwith @@ to_string (of_int status)
end

module Processor = struct
  module P = Ffi.Functions.Processor

  type t = P.t Ctypes.structure Ctypes.ptr
  type config = { bos : bool; eos : bool; unk : bool; reverse : bool }

  let default_config = { bos = true; eos = true; unk = true; reverse = false }

  let string_of_config { bos; eos; unk; reverse } =
    let flags =
      [ (bos, "bos"); (eos, "eos"); (unk, "unk"); (reverse, "reverse") ]
    in
    let flags = List.filter fst flags |> List.map snd in
    String.concat ":" flags

  let load_model ?config file =
    let proc = P.create () in
    let () = Gc.finalise P.destroy proc in
    let r =
      match P.load_model proc file with
      | 0 -> Ok proc
      | code ->
          Error
            ("failed to load model: " ^ Status.to_string @@ Status.of_int code)
    in
    Result.bind r @@ fun proc ->
    let config =
      match config with None -> default_config | Some config -> config
    in
    match P.set_encode_extra_options proc (string_of_config config) with
    | 0 -> Ok proc
    | code ->
        Error
          ("failed to set encode extra options: " ^ Status.to_string
         @@ Status.of_int code)

  let encode_pieces t text =
    let open Ctypes in
    let out_pieces = allocate_n (ptr (ptr char)) ~count:1 in
    let out_n_pieces = allocate_n size_t ~count:1 in

    let () =
      Status.raise_if_error @@ P.encode_pieces t text out_pieces out_n_pieces
    in

    let n_pieces = Unsigned.Size_t.to_int !@out_n_pieces in
    let pieces =
      List.map (coerce (ptr char) string)
      @@ CArray.to_list
      @@ CArray.from_ptr !@out_pieces n_pieces
    in

    let () = Util.free_ptr_arr (ptr char) !@out_pieces !@out_n_pieces in

    pieces

  let decode_pieces t pieces =
    let open Ctypes in
    let c_pieces = List.map CArray.of_string pieces in

    let in_pieces =
      CArray.of_list (ptr char) @@ List.map CArray.start c_pieces
    in
    let in_n_pieces = Unsigned.Size_t.of_int @@ CArray.length in_pieces in
    let out_text = allocate_n (ptr char) ~count:1 in

    let () =
      Status.raise_if_error
      @@ P.decode_pieces t (CArray.start in_pieces) in_n_pieces out_text
    in

    let text = coerce (ptr char) string !@out_text in
    Util.keep_alive c_pieces;

    let () = Util.free_ptr !@out_text in

    text

  let encode_ids t text =
    let open Ctypes in
    let out_ids = allocate_n (ptr int32_t) ~count:1 in
    let out_n_ids = allocate_n size_t ~count:1 in

    let () = Status.raise_if_error @@ P.encode_ids t text out_ids out_n_ids in

    let size = Unsigned.Size_t.to_int !@out_n_ids in
    let ids = bigarray_of_ptr array1 size Bigarray_compat.int32 !@out_ids in
    Gc.finalise (fun ba -> Util.free_ptr @@ bigarray_start array1 ba) ids;
    ids

  let encode_int64_ids t text =
    let open Ctypes in
    let out_ids = allocate_n (ptr int64_t) ~count:1 in
    let out_n_ids = allocate_n size_t ~count:1 in

    let () =
      Status.raise_if_error @@ P.encode_int64_ids t text out_ids out_n_ids
    in

    let size = Unsigned.Size_t.to_int !@out_n_ids in
    let ids = bigarray_of_ptr array1 size Bigarray_compat.int64 !@out_ids in
    Gc.finalise (fun ba -> Util.free_ptr @@ bigarray_start array1 ba) ids;
    ids

  let pp_int64_array1 fmt arr =
    let open Bigarray in
    let len = Array1.dim arr in
    Format.fprintf fmt "[|";
    for i = 0 to len - 1 do
      Format.fprintf fmt "%Ld; " (Array1.unsafe_get arr i)
    done;
    Format.fprintf fmt "|]"
end
