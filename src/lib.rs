use elf::{ElfBytes, endian::AnyEndian};
use std::{io, path::PathBuf};

pub struct RbpfProgram<'a> {
    vm: rbpf::EbpfVmRaw<'a>,
}

impl<'a> RbpfProgram<'a> {
    pub fn load_bytes(file_path: String) -> Vec<u8> {
        let path = PathBuf::from(file_path);
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

        prog.to_vec()
    }

    pub fn new(program_bytes: &'a [u8]) -> Self {
        // This is an eBPF VM for programs using a virtual metadata buffer, similar
        // to the sk_buff that eBPF programs use with tc and in Linux kernel.
        // We must provide the offsets at which the pointers to packet data start
        // and end must be stored: these are the offsets at which the program will
        // load the packet data from the metadata buffer.
        Self {
            vm: rbpf::EbpfVmRaw::new(Some(program_bytes)).unwrap(),
        }
    }

    pub fn register_helper(
        &mut self,
        key: u32,
        function: fn(u64, u64, u64, u64, u64) -> u64,
    ) -> Result<(), io::Error> {
        self.vm.register_helper(key, function)
    }

    pub fn run(&self, mem: &mut [u8]) -> Result<u64, io::Error> {
        self.vm.execute_program(mem)
    }
}
