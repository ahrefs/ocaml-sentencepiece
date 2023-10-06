#ifndef SENTENCEPIECE_WRAPPER_H
#define SENTENCEPIECE_WRAPPER_H

#ifdef __cplusplus
extern "C"
{
#endif
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

  // forward declaration
  typedef struct sp_processor_t sp_processor_t;

  typedef int sp_status_t;

  // Function to create a SentencePieceProcessor instance
  sp_processor_t *SentencePieceProcessor_Create();

  // Function to destroy a SentencePieceProcessor instance
  void SentencePieceProcessor_Destroy(sp_processor_t *handle);

  // Function to load a model from a filename
  sp_status_t SentencePieceProcessor_LoadModel(sp_processor_t *handle, const char *filename);

  // Function to encode input into a sequence of ids
  sp_status_t SentencePieceProcessor_EncodeIds(sp_processor_t *handle, const char *input, int **ids, size_t *num_ids);

  // Function to encode input into a sequence of int64 ids.
  sp_status_t SentencePieceProcessor_EncodeLongIds(sp_processor_t *handle, const char *input, int64_t **ids, size_t *num_ids);

  sp_status_t SentencePieceProcessor_EncodePieces(sp_processor_t *handle, const char *input, char ***pieces, size_t *num_pieces);

  sp_status_t SentencePieceProcessor_DecodePieces(sp_processor_t *handle, char **pieces, size_t num_pieces, char **detokenized);

  void Free(void *ptr);
  void FreePtrArray(void **arr, size_t len);

  sp_status_t SentencePieceProcessor_SetEncodeExtraOptions(sp_processor_t *sp, const char *extra_options);

  bool SentencePieceProcessor_Status_Ok(sp_status_t status);
  int SentencePieceProcessor_Status_Code(sp_status_t status);

#ifdef __cplusplus
}
#endif
#endif
