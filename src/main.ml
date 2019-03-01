open Parallel

let create () =
  Scheduler.Daemon.check_entry_point ();
  let scheduler = Scheduler.create ~number_of_workers:10 () in
  scheduler

let () =
  let files =
    [ ("a", 3)
    ; ("b", 4)
    ; ("c", 4)
    ; ("d", 2)
    ; ("e", 3)
    ; ("f", 9)
    ; ("g", 2)
    ]
  in
  Format.printf "Hello world@.";
  let partitions = Scheduler.longest_processing_time_first 3 files in
  List.iteri  (fun i partition ->
      Format.printf "%d: [" i;
      List.iter (fun element -> Format.printf "%s," element) partition;
      Format.printf "]@.")
    partitions;
  let scheduler = create () in
  Format.printf "Ok world@.";
  Scheduler.destroy scheduler;
