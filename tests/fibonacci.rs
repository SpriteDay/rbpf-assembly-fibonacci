use rbpf::helpers;
use rbpf_assembly_fibonacci::RbpfProgram;
use std::error::Error;

fn control_fibonacci(n: u64) -> Result<u64, Box<dyn Error>> {
    if n == 0 {
        // Early return for clean loop
        return Ok(0);
    };
    let mut num_1: u64 = 0;
    let mut num_2: u64 = 1;
    for _ in 0..(n - 1) {
        let temp = num_1;
        num_1 = num_2;
        let addition_result = num_2
            .checked_add(temp)
            .expect("Checked addition panicked, must be u64 overflow");
        num_2 = addition_result;
    }
    Ok(num_2)
}

fn run_program(input: u64) -> Result<u64, std::io::Error> {
    let out_dir = std::env::var("OUT_DIR").unwrap();
    let program_path = format!("{out_dir}/program.o");
    let program_bytes = RbpfProgram::load_bytes(program_path);
    let mut program = RbpfProgram::new(&program_bytes);
    program
        .register_helper(helpers::BPF_TRACE_PRINTK_IDX, helpers::bpf_trace_printf)
        .unwrap();

    program.run(&mut input.to_le_bytes())
}

#[test]
fn returns_0_element() {
    let input: u64 = 0;
    let result = run_program(input).unwrap();
    assert_eq!(result, control_fibonacci(input).unwrap());
}

#[test]
fn returns_1st_element() {
    let input: u64 = 1;
    let result = run_program(input).unwrap();
    assert_eq!(result, control_fibonacci(input).unwrap());
}

#[test]
fn returns_2nd_element() {
    let input: u64 = 2;
    let result = run_program(input).unwrap();
    assert_eq!(result, control_fibonacci(input).unwrap());
}

#[test]
fn returns_3rd_element() {
    let input: u64 = 3;
    let result = run_program(input).unwrap();
    assert_eq!(result, control_fibonacci(input).unwrap());
}
