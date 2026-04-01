use rbpf::helpers;
use rbpf_assembly_fibonacci::RbpfProgram;
use std::env;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let input = env::args().nth(1).expect(
        "Please pass an argument representing the desired index of calculated Fibonacci number, e.g. 10",
    );

    let input: u64 = input.parse().expect(
        "Please pass an argument representing the desired index of calculated Fibonacci number, e.g. 10"
    );

    // Load a program from an ELF file, e.g. compiled from C to eBPF with
    // clang/LLVM. Some minor modification to the bytecode may be required.
    let out_dir = env::var("OUT_DIR").unwrap();
    let file_path = format!("{out_dir}/program.o");

    let program_bytes = RbpfProgram::load_bytes(file_path);

    let mut program = RbpfProgram::new(&program_bytes);

    // We register a helper function, that can be called by the program, into
    // the VM. The `bpf_trace_printf` is only available when we have access to
    // the standard library.
    program
        .register_helper(helpers::BPF_TRACE_PRINTK_IDX, helpers::bpf_trace_printf)
        .unwrap();

    // This kind of VM takes a reference to the packet data, but does not need
    // any reference to the metadata buffer: a fixed buffer is handled
    // internally by the VM.
    let res = program.execute_program(&mut input.to_le_bytes()).unwrap();

    println!("Program returned: {:?} ({:#x})", res, res);
    Ok(())
}
