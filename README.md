# README

In `src` there are two programs that demonstrate the hack parallel library. You can run `make` and then `./main.exe` and `./main_with_shared_memory.exe`.

# Basic map reduce 

The first, `main.ml`, sums a list of integers:

```ocaml
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
  Scheduler.destroy scheduler
```

The important bits are:
- Creating the scheduler (and entry point) for forked processes. [Relevant documentation](https://github.com/rvantonder/hack-parallel/blob/master/src/interface/hack_parallel_intf.mli#L435-L438).
- A map reduce call over buckets of work. 

# Shared memory

The second, `main_with_shared_memory.ml` is a (contrived) example of summing a list of integers to demonstrate the shared memory interface. In this contrived example, we
start off with some work to do: a list of strings that represent integers. The "work" we'll do is convert these string values to integer values.
We'll then store these key:value pairs in shared memory (done in parallel). Given the list of strings (our keys), we'll read and sum the values
in memory (in parallel).

The first part defines modules that are used for keys/values in the shared memory map, respectively:

```ocaml
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

module ExampleMemory = Memory.WithCache (StringKey) (IntValue)
```

[Relevant memory interface](https://github.com/rvantonder/hack-parallel/blob/master/src/interface/hack_parallel_intf.mli#L142-L253), [Key signature](https://github.com/rvantonder/hack-parallel/blob/master/src/heap/sharedMem.ml#L723-L731), [Value signature](https://github.com/rvantonder/hack-parallel/blob/master/src/heap/value.ml).

In the example, operating on shared memory happens in two phases: one where we do work (convert to integer) and write values in parallel:

```ocaml
let () =
  let to_sum = ["1"; "2"; "3"; "4"; "5"; "6"; "7"; "8"; "9"; "10"] in
  let scheduler = create () in
  (* write values in parallel *)
  let () =
    Scheduler.iter scheduler to_sum ~f:(fun bucket_values ->
        List.iter bucket_values ~f:(fun value ->
            ExampleMemory.add value (Int.of_string value)))
  in
```

And another where we read values and do work (sum) in parallel

```ocaml
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
  ...
```
