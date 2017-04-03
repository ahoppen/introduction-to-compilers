func fibonacci(_ a: Int) -> Int {
    if a <= 0 {
        return 1
    }
    return fibonacci(a - 1) + fibonacci(a - 2)
}
print(fibonacci(2))
