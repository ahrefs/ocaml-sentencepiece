# OCaml bindings to SentencePiece

[SentencePiece](https://github.com/google/sentencepiece) is an unsupervised text tokenizer. 
Tested on [v0.1.99](https://github.com/google/sentencepiece/releases/tag/v0.1.99).

## Set up
```
sudo apt install libsentencepiece-dev
```

You also need a sentencepiece model ([example](https://huggingface.co/sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2/resolve/main/sentencepiece.bpe.model)).


## Example

```ocaml
utop # open Sentencepiece;;
utop # #install_printer Processor.pp_int64_array1;;
utop # let p = Processor.load_model "sentencepiece.bpe.model" |> Result.get_ok;;
val p : Processor.t = <abstr>
utop # Processor.encode_int64_ids p "Hey there!";;
- : (int64, Bigarray.int64_elt, Bigarray.c_layout) Bigarray.Array1.t =
[|1; 28239; 2684; 37; 2; |]
utop # Processor.encode_pieces p "Hey there!";;
- : string list = ["<s>"; "▁Hey"; "▁there"; "!"; "</s>"]
utop # Processor.(decode_pieces p @@ encode_pieces p "Hey there!");;
- : string = "Hey there!"
```
