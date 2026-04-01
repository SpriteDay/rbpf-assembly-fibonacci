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

    // Storing initial user input for logging
    // We use read-only r10 stack pointer to make offset for our u64 value that we store
    *(u64 *)(r10 - 8) = r6

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

    // This is a check for u64 overflow - in r7 we stored previous state of r8, meaning that we compare if new value
    // of the register is smaller then initial - this can happen with adding only if overflow happened
    if r8 < r7 goto overflow

    // Increment the loop count
    r6 -= 1

    // For logging we use https://docs.rs/rbpf/latest/rbpf/helpers/fn.bpf_trace_printf.html function that outputs 3,4,5 arguments ignoring
    // first two - which means we will see r3,r4,r5 registers values in logs
    // We put number of iteration into r3 for better logs
    r3 = *(u64 *)(r10 - 8)
    r3 -= r6
    r4 = r7
    r5 = r8
    call 6

    goto loop

early_0:
    r8 = 0
    goto finish

overflow:
    // Putting initial user input to r1 for logs:
    r1 = *(u64 *)(r10 - 8)
    // Calling our custom helper for overflow handling
    call 9
    r8 = -1 // Marking invalid value with return of -1
    goto finish

finish:
    // Put calculated value stored in r8 to r0 used as output
    r0 = r8
    exit

    // We declare the size of start function explicitly, because ELF will check it here: https://github.com/libbpf/libbpf/blob/master/src/libbpf.c#L923
    .size entrypoint, .-entrypoint