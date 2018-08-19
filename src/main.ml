open Parallel

let create () =
  Scheduler.Daemon.check_entry_point ();
  let scheduler = Scheduler.create ~number_of_workers:10 () in
  scheduler

let () =
  Format.printf "Hello world@.";
  let scheduler = create () in
  Format.printf "Ok world@.";
  Scheduler.destroy scheduler;
