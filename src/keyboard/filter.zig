pub fn isPrintableKey(code: u16) bool {
    return switch (code) {
        2...11, // numbers
        14, // backspace
        15, // tab
        16...25, //  qwerty
        30...38, // asdf
        44...50, // zxcv
        57, // spacebar
        96...105, // numpad numbers
        107, // numpad plus
        109, // numpad minus
        110, // numpad period
        111, // numpad divide
        28,
        => true,
        else => false,
    };
}
