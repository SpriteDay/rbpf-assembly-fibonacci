## Why I made this
I am Solana Program developer, and I wanted to touch raw execution space of [sBPF](https://github.com/anza-xyz/sbpf), understand limitations of the `rBPF` VM and have better intuition on what's going on

## What is this exactly
It's a Fibonacci calculator written in rBPF Assembly, done with Rust harness, handling of overflow within Assembly itself, and with integration tests suite on Rust level

The source code of assembly program placed at `src/program.s`

## How to run the thing
Basically we need:
- `clang`
- `llvm`

You can try this command that will install everything in a bulk:
```sh
sudo apt install clang llvm libbpf-dev libelf-dev linux-tools-common linux-headers-generic
```

## Build
We use `build.rs` to prebuild `program.o` and rebuild on `program.s` change:
```sh
cargo build
```

## Running
We run the program using `cargo` command, passing the index of desired Fibonacci number
```sh
cargo run -- 10
```

Output:
```
8: 13, 21
9: 21, 34
10: 34, 55
Program returned: 55 (0x37)
```

During the execution program outputs current state of registers, to display index of the loop, and last 2 calculated Fibonacci numbers

## Overflow handling
Fiboncci sequence can be calculated only up to `93` number using u64 registers, on Assembly side I used simple "does this register became smaller after addition" check to determine overflow cases

On overflow you can see this output:
```sh
$ cargo run -- 100
...
92: 4660046610375530309, 7540113804746346429
93: 7540113804746346429, 12200160415121876738
Overflow encountered! Input 100
```

Overflow gets propogated via helper function we register in Rust harness

## Code Highlight
For rBPF Assembly I suggest to install my custom [rBPF VS Code extension](https://open-vsx.org/extension/spriteday/ebpf-assembly)
for code highlighting

## Explanation of code
Let's look at the first line:

```
    .section .text,"x",@progbits
```

We use default `.text` header
Elf headers: https://man7.org/linux/man-pages/man5/elf.5.html

The second argument currently set to `"x"` is optional flags argument specified here (we use `x` for executable): 
https://sourceware.org/binutils/docs/as/Section.html

The last element set to `@progbits` is data type, is also specified here: https://sourceware.org/binutils/docs/as/Section.html
    
```
    .global entrypoint
```

Here we use the same name for entrypoint symbol as `sBPF`:
https://github.com/anza-xyz/sbpf/blob/2c91f24c7bc717547db62961f53bab17dc467bf2/src/elf.rs#L417

```
    .type entrypoint,@function
```

Here we need to declare type of entrypoint function, otherwise ELF will skip it: https://github.com/libbpf/libbpf/blob/master/src/libbpf.c#L920

After that we implement main logic - Fibonacci sequence calculation

At the end we declare the size of start function explicitly, because ELF will check it here: https://github.com/libbpf/libbpf/blob/master/src/libbpf.c#L923

```
    .size entrypoint, .-entrypoint
```