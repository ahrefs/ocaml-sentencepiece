#include <caml/fail.h>
#include <sentencepiece_processor.h>

extern "C"
{

  typedef sentencepiece::SentencePieceProcessor sp_processor_t;
  typedef int sp_status_t;

  int SentencePieceProcessor_Status_Code(sp_status_t status) { return status; }

  bool SentencePieceProcessor_Status_Ok(sp_status_t status) { return status == 0; }

  int cast_to_int(sentencepiece::util::StatusCode code) { return static_cast<int>(code); }

  // Function to create a SentencePieceProcessor instance
  sp_processor_t *SentencePieceProcessor_Create() { return new sentencepiece::SentencePieceProcessor(); }

  void failwith_if_null(void *ptr, const char *msg)
  {
    if (ptr == NULL)
    {
      caml_failwith(msg);
    }
  }

  // Function to destroy a SentencePieceProcessor instance
  void SentencePieceProcessor_Destroy(sp_processor_t *sp)
  {
    failwith_if_null(sp, "SentencePieceProcessor_Destroy: sp is NULL");
    delete sp;
  }

  // Function to load a model from a filename
  sp_status_t SentencePieceProcessor_LoadModel(sp_processor_t *sp, const char *filename)
  {
    failwith_if_null(sp, "SentencePieceProcessor_LoadModel: sp is NULL");
    return cast_to_int(sp->Load(filename).code());
  }

  // Function to encode input into a sequence of ids
  int SentencePieceProcessor_EncodeIds(sp_processor_t *sp, const char *input, int **ids, size_t *num_ids)
  {
    failwith_if_null(sp, "SentencePieceProcessor_EncodeIds: sp is NULL");
    std::vector<int> cpp_ids;
    sp_status_t code = cast_to_int(sp->Encode(input, &cpp_ids).code());
    if (code == 0)
    {
      size_t len = cpp_ids.size();

      // NOTE: memory allocated here needs to be freed by the caller using
      // FreePtrArray
      int *c_ids = (int *)malloc(sizeof(int) * len);
      memcpy(c_ids, cpp_ids.data(), sizeof(int) * len);

      *ids = c_ids;
      *num_ids = len;
      return code;
    }
    return code;
  }

  /**
   * Function to encode input into a sequence of int64 ids.
   * This function upcasts an int32 id to int64 id and writes directly to the
   * output array without copying. Useful for transformers that expect int64 ids.
   */
  int SentencePieceProcessor_EncodeLongIds(sp_processor_t *sp, const char *input, int64_t **ids, size_t *num_ids)
  {
    failwith_if_null(sp, "SentencePieceProcessor_EncodeLongIds: sp is NULL");
    // sentencepiece::Encode expects a vector of int
    std::vector<int> cpp_ids;
    sp_status_t code = cast_to_int(sp->Encode(input, &cpp_ids).code());
    if (code == 0)
    {
      size_t len = cpp_ids.size();

      // NOTE: memory allocated here needs to be freed by the caller using
      // FreePtrArray
      int64_t *c_ids = (int64_t *)malloc(sizeof(int64_t) * len);

      for (size_t i = 0; i < len; ++i)
      {
        c_ids[i] = static_cast<int64_t>(cpp_ids[i]);
      }

      *ids = c_ids;
      *num_ids = len;
      return code;
    }
    return code;
  }

  int SentencePieceProcessor_EncodePieces(sp_processor_t *sp, const char *input, char ***pieces, size_t *num_pieces)
  {
    failwith_if_null(sp, "SentencePieceProcessor_EncodePieces: sp is NULL");
    std::vector<std::string> cpp_pieces;
    sp_status_t code = cast_to_int(sp->Encode(input, &cpp_pieces).code());
    if (code == 0)
    {
      size_t len = cpp_pieces.size();

      // NOTE: memory allocated needs to be freed by the caller, using
      // FreePtrArray
      char **c_pieces = (char **)malloc(sizeof(char *) * len);

      for (size_t i = 0; i < len; ++i)
      {
        // NOTE: memory allocated here needs to be freed by the caller, using
        // FreePtrArray
        c_pieces[i] = (char *)malloc(sizeof(char) * (cpp_pieces[i].size() + 1));
        strcpy(c_pieces[i], cpp_pieces[i].c_str());
      }

      *pieces = c_pieces;
      *num_pieces = len;
      return code;
    }
    return code;
  }

  int SentencePieceProcessor_DecodePieces(sp_processor_t *sp, const char **pieces, size_t num_pieces, char **detokenized)
  {
    failwith_if_null(sp, "SentencePieceProcessor_DecodePieces: sp is NULL");

    std::vector<std::string> cpp_pieces;
    cpp_pieces.reserve(num_pieces);
    for (size_t i = 0; i < num_pieces; ++i)
    {
      // NOTE: safe to cast here before nether Sentencepiece nor OCaml should
      // modify the string
      cpp_pieces.push_back(pieces[i]);
    }

    std::string cpp_detokenized;
    sp_status_t code = cast_to_int(sp->Decode(cpp_pieces, &cpp_detokenized).code());
    if (code == 0)
    {
      size_t len = cpp_detokenized.size();
      // NOTE: memory allocated here needs to be freed by the caller, using Free
      *detokenized = (char *)malloc(sizeof(char) * (len + 1));
      strcpy(*detokenized, cpp_detokenized.c_str());

      return code;
    }
    return code;
  }

  void Free(void *ptr)
  {
    failwith_if_null(ptr, "Free: ptr is null");
    if (ptr != NULL)
    {
      free(ptr);
    }
  }

  void FreePtrArray(void **arr, size_t len)
  {
    failwith_if_null(arr, "FreePtrArray: arr is null");
    if (arr != NULL)
    {
      for (size_t i = 0; i < len; ++i)
      {
        free(arr[i]);
      }
      free(arr);
    }
  }

  int SentencePieceProcessor_SetEncodeExtraOptions(sp_processor_t *sp, const char *extra_options)
  {
    failwith_if_null(sp, "SentencePieceProcessor_SetEncodeExtraOptions: sp is NULL");
    return cast_to_int(sp->SetEncodeExtraOptions(extra_options).code());
  }
}
