<!--
 Copyright 2021-2022 Fred Dushin <fred@dushin.net>

 SPDX-License-Identifier: Apache-2.0 OR LGPL-2.1-or-later
-->

# AtomVM Internals

## What is an Abstract Machine?

AtomVM is an "abstract" or "virtual" machine, in the sense that it simulates, in software, what a physical machine would do when executing machine instructions.  In a normal computing machine (e.g., a desktop computer), machine code instructions are generated by a tool called a compiler, allowing an application developer to write software in a high-level language (such as C).  (In rare cases, application developers will write instructions in assembly code, which is closer to the actual machine instructions, but which still requires a translation step, called "assembly", to translate the assembly code into actual machine code.)  Machine code instructions are executed in hardware using the machine's Central Processing Unit (CPU), which is specifically designed to efficiently execute machine instructions targeted for the specific machine architecture (e.g., Intel x86, ARM, Apple M-series, etc.)  As a result, machine code instructions are typically tightly packed, encoded instructions that require minimum effort (on the part of the machine) to unpack an interpret.  These a low level instructions unsuited for human interpretation, or at least for most humans.

AtomVM and virtual machines generally (including, for example, the Java Virtual Machine) perform a similar task, except that i) the instructions are not machine code instructions, but rather what are typically called "bytecode" or sometimes "opcode" instructions; and ii) the generated instructions are themselves executed by a runtime execution engine written in software, a so-called "virtual" or sometimes "abstract" machine.  These bytecode instructions are generated by a compiler tailored specifically for the virtual machine.  For example, the `javac` compiler is used to translate Java source code into Java VM bytecode, and the `erlc` compiler is used to translate Erlang source code into BEAM opcodes.

AtomVM is an abstract machine designed to implement the BEAM instruction set, the 170+ (and growing) set of virtual machine instructions implemented in the Erlang/OTP BEAM.

> Note that there is no abstract specification of the BEAM abstract machine and instruction set.  Instead, the BEAM implementation by the Erlang/OTP team is the definitive specification of its behavior.

At a high level, the AtomVM abstract machine is responsible for:

* Loading and execution of the BEAM opcodes encoded in one or more BEAM files;
* Managing calls to internal and external functions, handling return values, exceptions, and crashes;
* Creation and destruction of Erlang "processes" within the AtomVM memory space, and communication between processes via message passing;
* Memory management (allocation and reclamation) of memory associated with Erlang "processes"
* Pre-emptive scheduling and interruption of Erlang "processes"
* Execution of user-defined native code (Nifs and Ports)
* Interfacing with the host operating system (or facsimile)

This document provides a description of the AtomVM abstract machine, including its architecture and the major components and data structures that form the system.  It is intended for developers who want to get involved in bug fixing or implementing features for the VM, as well as for anyone interested in virtual machine internals targeted for BEAM-based languages, such as Erlang or Elixir.

## AtomVM Data Structures

This section describes AtomVM internal data structures that are used to manage the load and runtime state of the virtual machine.  Since AtomVM is written in C, this discussion will largely be in the context of native C data structures (i.e., `structs`).  The descriptions will start at a fairly high level but drill down to some detail about the data structures, themselves.  This narrative is important, because memory is limited on the target architectures for AtomVM (i.e., micro-controllers), and it is important to always be aware of how memory is organized and used in a way that is as space-efficient as possible.

### The GlobalContext

We start with the top level data structure, the `GlobalContext` struct.  This object is a singleton object (currently, and for the foreseeable future), and represents the root of all data structures in the virtual machine.  It is in essence in 1..1 correspondence with instances of the virtual machine.

> Note. Given the design of the system, it is theoretically possible to run multiple instances of the AtomVM in one process space.  However, no current deployments make use of this capability.

In order to simplify the exposition of this structure, we break the fields of the structure into manageable subsets:

* Process management -- fields associated with the management of Erlang (lightweight) "processes"
* Atoms management -- fields associated with the storage of atoms
* Module Management -- fields associated with the loading of BEAM modules
* Reference Counted Binaries -- fields associated with the storage of binary data shared between processes
* Other data structures

These subsets are described in more detail below.

> Note.  Not all fields of the `GlobalContext` structure are described in this document.

#### Process Management

As a BEAM implementation, AtomVM must be capable of spawning and managing the lifecycle of Erlang lightweight processes.  Each of these processes is encapsulated in the `Context` structure, described in more detail in subsequent sections.

The `GlobalContext` structure maintains a list of running processes and contains the following fields for managing the running Erlang processes in the VM:

* `processes_table` the list of all processes running in the system
* `waiting_processes` the subset of processes that are waiting to run (e.g., waiting for a message or timeout condition).  This set is the complement of the set of ready processes.
* `ready_processes` the subset of processes that are ready to run.  This set is the complement of the set of waiting processes.

Each of these fields are doubly-linked list (ring) structures, i.e, structs containing a `prev` and `next` pointer field.  The `Context` data structure begins with two such structures, the first of which links the `Context` struct in the `processes_table` field, and the second of which is used for either the `waiting_processes` or the `ready_processes` field.

> Note.  The C programming language treats structures in memory as contiguous sequences of fields of given types.  Structures have no hidden pramble data, such as you might find in C++ or who knows what in even higher level languages.  The size of a struct, therefore, is determined simply by the size of the component fields.


The relationship between the `GlobalContext` fields that manage BEAM processes and the `Context` data structures that represent the processes, themselves, is illustrated in the following diagram:

![GlobalContext Processes](_static/globalcontext-processes.svg)

> Note.  The `Context` data structure is described in more detail below.

#### Module Management

#### An Aside: What's in a HashTable?


### Modules

### Contexts

## Runtime Execution Loop

## Module Loading

## Function Calls and Return Values

## Exception Handling

## The Scheduler

## Stacktraces

Stacktraces are computed from information gathered at load time from BEAM modules loaded into the application, together with information in the runtime stack that is maintained during the execution of a program.  In addition, if a BEAM file contains a `Line` chunk, additional information is added to stack traces, including the file name (as defined at compile time), as well as the line number of a function call.

> Note.  Adding line information to a BEAM file adds non-trivial memory overhead to applications and should only be used when necessary (e.g., during the development process).  For applications to make the best use of memory in tightly constrained environments, packagers should consider removing line information all together from BEAM files and rely instead on logging or other mechanisms for diagnosing problems in the field.

Newcomers to Erlang may find stacktraces slightly confusing, because some optimizations taken by the Erlang compiler and runtime can result in stack frames "missing" from stack traces.  For example, tail-recursive function calls, as well as function calls that occur as the last expression in a function clause, don't involve the creation of frames in the runtime stack, and consequently will not appear in a stacktrace.

### Line Numbers

Including file and line number information in stacktraces adds considerable overhead to both the BEAM file data, as well as the memory consumed at module load time.  The data structures used to track line numbers and file names are described below and are only created if the associated BEAM file contains a `Line` chunk.

#### The line-refs table

The line-refs table is an array of 16-bit integers, mapping line references (as they occur in BEAM instructions) to the actual line numbers in a file.  (Internally, BEAM instructions do not reference line numbers directly, but instead are indirected through a line index).  This table is stored on the `Module` structure.

This table is populated when the BEAM file is loaded.  The table is created from information in the `Line` chunk in the BEAM file, if it exists.  Note that if there is no `Line` chunk in a BEAM file, this table is not created.

The memory cost of this table is `num_line_refs * 2` bytes, for each loaded module, or 0, if there is no `Line` chunk in the associated BEAM file.

#### The filenames table

The filenames table is a table of (usually only 1?) file name.  This table maps filename indices to `ModuleFilename` structures, which is essentially a pointer and a length (of type `size_t`).  This table generally only contains 1 entry, the file name of the Erlang source code module from which the BEAM file was generated.  This table is stored on the `Module` structure.

Note that a `ModuleFilename` structure points to data directly in the `Line` chunk of the BEAM file.  Therefore, for ports of AtomVM that memory-map BEAM file data (e.g., ESP32), the actual file name data does not consume any memory.

The memory cost of this table is `num_filenames * sizeof(struct ModuleFilename)`, where `struct ModuleFilename` is a pointer and length, for each loaded module, or 0, if there is no `Line` chunk in the associated BEAM file.

#### The line-ref-offsets list

The line-ref-offsets list is a sequence of `LineRefOffset` structures, where each structure contains a ListHead (for list book-keeping), a 16-bit line-ref, and an unsigned integer value designating the code offset at which the line reference occurs in the code chunk of the BEAM file.  This list is stored on the `Module` structure.

This list is populated at code load time.  When a line reference is encountered during code loading, a `LineRefOffset` structure is allocated and added to the line-ref-offsets list.  This list is used at a later time to find the line number at which a stack frame is called, in a manner described below.

The memory cost of this list is `num_line_refs * sizeof(struct LineRefOffset)`, for each loaded module, or 0, if there is no `Line` chunk in the associated BEAM file.

### Raw Stacktraces
