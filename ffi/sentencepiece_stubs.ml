open Ctypes
module T = Types_generated

module Functions (F : Ctypes.FOREIGN) = struct
  open F

  module Processor = struct
    type t = T.processor

    let create =
      foreign "SentencePieceProcessor_Create" (void @-> returning T.processor)

    let destroy =
      foreign "SentencePieceProcessor_Destroy" (T.processor @-> returning void)

    let load_model =
      foreign "SentencePieceProcessor_LoadModel"
        (T.processor @-> string @-> returning T.status)

    let encode_ids =
      foreign "SentencePieceProcessor_EncodeIds"
        (T.processor @-> string
        @-> ptr (ptr int32_t)
        @-> ptr size_t @-> returning T.status)

    let encode_int64_ids =
      foreign "SentencePieceProcessor_EncodeLongIds"
        (T.processor @-> string
        @-> ptr (ptr int64_t)
        @-> ptr size_t @-> returning T.status)

    let set_encode_extra_options =
      foreign "SentencePieceProcessor_SetEncodeExtraOptions"
        (T.processor @-> string @-> returning T.status)

    let encode_pieces =
      foreign "SentencePieceProcessor_EncodePieces"
        (T.processor @-> string
        @-> ptr (ptr (ptr char))
        @-> ptr size_t @-> returning T.status)

    let decode_pieces =
      foreign "SentencePieceProcessor_DecodePieces"
        (T.processor
        @-> ptr (ptr char)
        @-> size_t
        @-> ptr (ptr char)
        @-> returning T.status)
  end

  module Util = struct
    let free_ptr = foreign "Free" (ptr void @-> returning void)

    let free_ptr_arr =
      foreign "FreePtrArray" (ptr (ptr void) @-> size_t @-> returning void)
  end
end
