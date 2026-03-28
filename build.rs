use std::env;
use std::process::Command;

// Example custom build script.
fn main() {
    // Tell Cargo that if the given file changes, to rerun this build script.
    println!("cargo::rerun-if-changed=src/program.s");

    let out_dir = env::var("OUT_DIR").unwrap();

    let status = Command::new("clang")
        .args([
            "-target",
            "bpf",
            "-c",
            "src/program.s",
            "-o",
            format!("{out_dir}/program.o").as_str(),
        ])
        .status()
        .expect("clang not found");
    assert!(status.success());
}
