    // We use default .text header
    // Elf headers: https://man7.org/linux/man-pages/man5/elf.5.html
    //
    // The second argument currently set to "x" is optional flags argument specified here (we use x for executable): 
    // https://sourceware.org/binutils/docs/as/Section.html
    //
    // The last element set to @progbits is data type, is also specified here: https://sourceware.org/binutils/docs/as/Section.html
    .section .text,"x",@progbits

    // We use sBPF name for entrypoint symbol:
    // https://github.com/anza-xyz/sbpf/blob/2c91f24c7bc717547db62961f53bab17dc467bf2/src/elf.rs#L417
    .global entrypoint

    // We need to declare type of entrypoint, otherwise ELF will skip it: https://github.com/libbpf/libbpf/blob/master/src/libbpf.c#L920
    .type entrypoint,@function

entrypoint:
    // What is this? The passed argument that we specify in Rust harness (user input in this case)
    // comes as address to the argument bytes specified in r1 register (according to https://docs.rs/rbpf/latest/rbpf/struct.EbpfVmRaw.html example).
    // Then since we used u64 for user input - we type cast the bytes at the address to u64 using C-alike syntx (u64 *)val
    // Why (r1 + 0) though? According to https://www.kernel.org/doc/html/latest/bpf/standardization/instruction-set.html#regular-load-and-store-operations
    // the syntax of loading data from address to register always comes as this:
    // *(size *) (dst + offset) = src
    // Where we must specify the offset. Since r1 already contains the address we just put 0 ofset to access the passed value
    r1 = *(u64 *)(r1 + 0)
    // Accumulator
    r0 = 0
    // Initial state of the loop counter
    r2 = 0
    // Number we are adding
    r3 = 1

loop:
    if r2 < r1 goto increment
    exit

increment:
    r0 += r3
    r2 += 1
    r3 += 1
    goto loop


    // We declare the size of start function explicitly, because ELF will check it here: https://github.com/libbpf/libbpf/blob/master/src/libbpf.c#L923
    .size entrypoint, .-entrypoint