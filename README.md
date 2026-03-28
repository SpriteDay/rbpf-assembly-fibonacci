This project is exploration of rBPF and how it works - Fibonacci calculator written in assembly for rBPF. Done as practice piece for future Solana Programs development, to get intuition of the backbone of [sBPF](https://github.com/anza-xyz/sbpf)

We use `src/program.s` as Assembly source of rBPF program and Rust harness using `rBPF` to run it with passsed argument

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

## Prerequisites
Basically we need:
- `clang`
- `llvm`
- `bpftool`

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
```sh
cargo run
```

## Code Highlight
For rBPF Assembly I suggest to install my custom [rBPF VS Code extension](https://open-vsx.org/extension/spriteday/ebpf-assembly)
for code highlighting