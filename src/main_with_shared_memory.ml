open Core
open Hack_parallel

module StringKey = struct
  type t = string
  let to_string = ident
  let compare = String.compare
end

module IntValue = struct
  type t = int
  let prefix = Prefix.make ()
  let description = "Value"
end

module ExampleMemory = SharedMem.WithCache (StringKey) (IntValue)

let create () =
  Scheduler.Daemon.check_entry_point ();
  Scheduler.create ~number_of_workers:10 ()

let () =
  let to_sum = ["1"; "2"; "3"; "4"; "5"; "6"; "7"; "8"; "9"; "10"] in
  let scheduler = create () in
  (* write values in parallel *)
  let () =
    Scheduler.iter scheduler to_sum ~f:(fun bucket_values ->
        List.iter bucket_values ~f:(fun value ->
            ExampleMemory.add value (Int.of_string value)))
  in
  (* read values in parallel and sum *)
  let sum =
    Scheduler.map_reduce
      scheduler
      to_sum
      ~init:0
      ~map:(fun init bucket_values ->
          List.fold bucket_values ~init ~f:(fun acc key ->
              acc + ExampleMemory.find_unsafe key))
      ~reduce:(fun bucket_sum total_sum -> total_sum + bucket_sum)
  in
  Format.printf "Sum: %d@." sum;
  Scheduler.destroy scheduler
