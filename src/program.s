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
    r0 = 40
    r0 += 2
    exit

    // We declare the size of start function explicitly, because ELF will check it here: https://github.com/libbpf/libbpf/blob/master/src/libbpf.c#L923
    .size entrypoint, .-entrypoint