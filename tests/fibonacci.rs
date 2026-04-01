use std::error::Error;

fn fibonacci(n: u64) -> Result<u64, Box<dyn Error>> {
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

#[test]
fn returns_0_element() {
    let result = fibonacci(0).unwrap();
    assert_eq!(result, 0);
}

#[test]
fn returns_1st_element() {
    let result = fibonacci(1).unwrap();
    assert_eq!(result, 1);
}

#[test]
fn returns_2nd_element() {
    let result = fibonacci(2).unwrap();
    assert_eq!(result, 1);
}

#[test]
fn returns_3rd_element() {
    let result = fibonacci(3).unwrap();
    assert_eq!(result, 2);
}
