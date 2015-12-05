(* file.ml
 * Updated 151127 by Albert Zhang
 * For ATEXT text-editor project.
 *)

open Auxiliary

(* File name. *)
type name = {
  n   : string;
  ext : string option
}

(* The first string is the parent. *)
type path = string list

exception FileNotFound of string

let designated : path ref =
  ref ["myfiles"]

let rec concat_path (p : path) : string =
  match p with
  | [] -> ""
  | h :: t -> h ^ "/" ^ (concat_path t)

let concat_root_path (p : path) : string =
  "/" ^ (concat_path p)

let in_chn_of_name (n : name) : in_channel =
  pd "File.in_chn_of_name: Attempting to open an in channel";
  let p : string = concat_path !designated in
  let full : string = match n.ext with
    | Some s -> p ^ n.n ^ "." ^ s
    | None -> p ^ n.n
  in try open_in full with Sys_error s -> raise (FileNotFound s)

let out_chn_of_name (n : name) : out_channel =
  pd "File.out_chn_of_name: Attempting to open an out channel";
  let p : string = concat_path !designated in
  let full : string = match n.ext with
    | Some s -> p ^ n.n ^ "." ^ s
    | None -> p ^ n.n
  in open_out full

let open_lines (n : name) : string list =
  pd "File.open_lines: try opening channel and see if file exists";
  let chn : in_channel = in_chn_of_name n in
  pd "File.open_lines: Channel in has been opened";
  let rec read_lines (chn : in_channel) (acc : string list) : string list =
    try read_lines chn (input_line chn :: acc)
    with End_of_file -> acc
  in let lines : string list = List.rev_append (read_lines chn []) [] in
  pd "File.open_lines: Things have been read";
  close_in chn; lines

let save_to (n : name) (data : string) : unit =
  let chn : out_channel = out_chn_of_name n in
  output_string chn data; close_out chn

let save_lines (n : name) (data : string list) : unit =
  let chn : out_channel = out_chn_of_name n in
  let rec write_lines (chn : out_channel) (pile : string list) : unit =
    match pile with
    | [] -> failwith "Cannot be pure empty!"
    | h :: [] -> output_string chn h
    | h :: t -> output_string chn h; output_char chn '\n';
      write_lines chn t
  in write_lines chn data; close_out chn

let file_of_string (s : string) : name =
  if String.contains s '.' then
    let i : int = String.rindex s '.' in
    let l : int = String.length s in
    {n = String.sub s 0 i; ext = Some (String.sub s (i + 1) (l - (i + 1)))}
  else {n = s; ext = None}

let string_of_file (n : name) : string =
  match n.ext with
  | None -> n.n
  | Some ext -> n.n ^ "." ^ ext

let create (n : name) : name =
  pd "File.create: creating file from scratch";
  n |> out_chn_of_name |> close_out; n

let default : unit -> name = fun _ ->
  pd "File.default: creating file with untitled";
  "untitled" |> file_of_string |> create