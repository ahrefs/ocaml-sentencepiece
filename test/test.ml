open Sentencepiece
open Bigarray

let bigarray1_eq a b =
  let len = Array1.dim a in
  let rec loop i =
    if i = len then true else if a.{i} <> b.{i} then false else loop (i + 1)
  in
  loop 0

module Processor_test = struct
  open Processor

  let test_encode_int64_ids model =
    let expected =
      Array1.of_array int64 c_layout
        [| 5L; 0L; 7L; 3L; 3L; 4L; 5L; 10L; 4L; 9L; 3L; 6L; 0L |]
    in
    let actual = encode_int64_ids model "Hello world!" in
    OUnit.assert_equal expected actual ~cmp:bigarray1_eq

  let test_encode_ids model =
    let expected =
      Array1.of_array int32 c_layout
        [| 5l; 0l; 7l; 3l; 3l; 4l; 5l; 10l; 4l; 9l; 3l; 6l; 0l |]
    in
    let actual = encode_ids model "Hello world!" in
    OUnit.assert_equal expected actual ~cmp:bigarray1_eq

  let test_encode_empty model =
    let expected = Array1.of_array int32 c_layout [||] in
    let actual = encode_ids model "" in
    OUnit.assert_equal expected actual ~cmp:bigarray1_eq

  let test_encode_decode_pieces model =
    let expected = "Hello world!" in
    let actual = decode_pieces model (encode_pieces model expected) in
    OUnit.assert_equal expected actual ~printer:(fun x -> x)

  let run () =
    let config =
      { default_config with bos = false; eos = false; unk = false }
    in
    match load_model ~config "./trivial.model" with
    | Error err ->
        print_endline err;
        assert false
    | Ok model ->
        let () = test_encode_ids model in
        let () = test_encode_int64_ids model in
        let () = test_encode_empty model in
        let () = test_encode_decode_pieces model in
        ()
end

(* entrypoint *)
let () =
  print_endline "Testing sentencepiece bindings...";
  Processor_test.run ();
  print_endline "All tests passed!"
