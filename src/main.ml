open Core
open Hack_parallel

let create () =
  Scheduler.Daemon.check_entry_point ();
  Scheduler.create ~number_of_workers:10 ()

let () =
  let to_sum = [1; 2; 3; 4; 5; 6; 7; 8; 9; 10] in
  let scheduler = create () in
  let sum =
    Scheduler.map_reduce
      scheduler
      to_sum
      ~init:0
      ~map:(fun init bucket_values -> List.fold ~init ~f:(+) bucket_values)
      ~reduce:(fun bucket_sum total_sum -> total_sum + bucket_sum)
  in
  Format.printf "Sum: %d@." sum;
  Scheduler.destroy scheduler;
