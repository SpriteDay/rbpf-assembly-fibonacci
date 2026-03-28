    // eBPF programs can be attached at different points in the kernel and will be called like a function
    // That's why we specify the type via "socket" 
    // Program types: https://docs.ebpf.io/linux/program-type/
    //
    // The second argument currently set to "x" is optional flags argument specified here (we use x for executable): 
    // https://sourceware.org/binutils/docs/as/Section.html
    //
    // The last element set to @progbits is data type, is also specified here: https://sourceware.org/binutils/docs/as/Section.html
    .section socket,"x",@progbits

    .global start

    // We need to declare type of start, otherwise ELF will skip it: https://github.com/libbpf/libbpf/blob/master/src/libbpf.c#L920
    .type start,@function

start:
    r0 = 1
    exit

    // We declare the size of start function explicitly, because ELF will check it here: https://github.com/libbpf/libbpf/blob/master/src/libbpf.c#L923
    .size start, .-start