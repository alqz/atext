(* file.ml
 * Updated 151127 by Albert Zhang
 * For ATEXT text-editor project.
 *)

(* File name. *)
type name = string

exception FileNotFound

let open_lines (n : name) : string list =
  let chn : in_channel = open_in n in
  let rec read_lines (chn : in_channel) (acc : string list) : string list =
    try read_lines chn (input_line chn :: acc)
    with End_of_file -> acc
  in let lines : string list = read_lines chn [] in
  close_in chn; lines

let save_to (n : name) (data : string) : unit =
  let chn : out_channel = open_out n in
  output_string chn data; close_out chn

let save_lines (n : name) (data : string list) : unit =
  let chn : out_channel = open_out n in
  let rec write_lines (chn : out_channel) (pile : string list) : unit =
    match pile with
    | [] -> ()
    | h :: [] -> output_string chn h
    | h :: t -> output_string chn h; output_char chn '\n';
      write_lines chn t
  in write_lines chn data; close_out chn

let create (n : string) : name = n
let untitled : unit -> name = fun _ -> "untitled"