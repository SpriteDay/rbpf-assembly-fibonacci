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
    // comes as address to the argument bytes specified in r1 register (context passed via r1, according to https://www.kernel.org/doc/html/latest/bpf/verifier.html).
    // Then since we used u64 for user input - we type cast the bytes at the address to u64 using C-alike syntx (u64 *)val
    // Why (r1 + 0) though? According to https://www.kernel.org/doc/html/latest/bpf/standardization/instruction-set.html#regular-load-and-store-operations
    // the syntax of loading data from address to register always comes as this:
    // *(size *) (dst + offset) = src
    // Where we must specify the offset. Since r1 already contains the address we just put 0 ofset to access the passed value
    // We use r6-r9 as callee saved registers, as r0-r5 are scratch regsiters and r10 is read-only stack pointer:
    // https://www.kernel.org/doc/html/latest/bpf/verifier.html
    r6 = *(u64 *)(r1 + 0)

    // Early return for first number
    if r6 == 0 goto early_0

    // We ruled out first number early return, now we need to do r6 - 1 loops of fibonacci:
    r6 -= 1

    // First number in the sequence
    r7 = 0
    // Second number in the sequence
    r8 = 1

loop:
    if r6 == 0 goto finish
    goto fibonacci

fibonacci:
    // Temporary store n-1 number
    r9 = r7
    // Move nth to n-1 position
    r7 = r8
    // Update nth adding temporary stored n-1 number
    r8 += r9
    // Increment the loop count
    r6 -= 1

    // For logging we use https://docs.rs/rbpf/latest/rbpf/helpers/fn.bpf_trace_printf.html function that outputs 3,4,5 arguments ignoring
    // first two - which means we will see r3,r4,r5 registers values in logs
    r3 = r7
    r4 = r8
    r5 = r6
    call 6

    goto loop

invalid_input:
    r8 = -1
    goto finish

early_0:
    r8 = 0
    goto finish

finish:
    // Put calculated value stored in r8 to r0 used as output
    r0 = r8
    exit

    // We declare the size of start function explicitly, because ELF will check it here: https://github.com/libbpf/libbpf/blob/master/src/libbpf.c#L923
    .size entrypoint, .-entrypoint