use elf::ElfBytes;
use elf::endian::AnyEndian;
use std::env;
use std::path::PathBuf;

fn main() {
    // Load a program from an ELF file, e.g. compiled from C to eBPF with
    // clang/LLVM. Some minor modification to the bytecode may be required.
    let out_dir = env::var("OUT_DIR").unwrap();
    let filename = format!("{out_dir}/program.o");

    let path = PathBuf::from(filename);
    let file_data = std::fs::read(path).expect("Could not read file");
    let slice = file_data.as_slice();
    let file = ElfBytes::<AnyEndian>::minimal_parse(slice).expect("Fail to parse ELF file");

    // Here we assume the eBPF program is in the ELF section called
    // ".text".
    let classifier_section_header = match file.section_header_by_name(".text") {
        Ok(Some(header)) => header,
        Ok(None) => panic!("No .text section found"),
        Err(e) => panic!("Error while searching for .text section: {}", e),
    };

    let prog = file
        .section_data(&classifier_section_header)
        .expect("Failed to get .text section data")
        .0;

    // This is an eBPF VM for programs using a virtual metadata buffer, similar
    // to the sk_buff that eBPF programs use with tc and in Linux kernel.
    // We must provide the offsets at which the pointers to packet data start
    // and end must be stored: these are the offsets at which the program will
    // load the packet data from the metadata buffer.
    let vm = rbpf::EbpfVmNoData::new(Some(prog)).unwrap();

    // This kind of VM takes a reference to the packet data, but does not need
    // any reference to the metadata buffer: a fixed buffer is handled
    // internally by the VM.
    let res = vm.execute_program().unwrap();
    println!("Program returned: {:?} ({:#x})", res, res);
}
