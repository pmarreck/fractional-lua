# Fractional-Lua: Arbitrary Precision Fractional Number Library

A high-performance, arbitrary precision fractional number library implemented in MoonScript/Lua, designed for financial calculations requiring exact precision.

## Features

- **Arbitrary Precision**: Uses the GNU Multiple Precision (GMP) library via LuaJIT's FFI for unlimited precision
- **Exact Representation**: Stores numbers as fractions (rational numbers) to avoid floating-point errors
- **Automatic Reduction**: Configurable reduction strategy to keep fractions in simplified form
- **Financial Formatting**: Smart display of extremely large and small fractions for financial calculations
- **Performance Optimized**: Handles complex calculations with thousands of operations efficiently

## System Requirements

- [LuaJIT](https://luajit.org/) (2.0.5+) - Just-in-time compiler for Lua
- [MoonScript](https://moonscript.org/) (0.5.0+) - Language that compiles to Lua
- [GNU Multiple Precision Library (GMP)](https://gmplib.org/) (6.0.0+) - Arbitrary precision arithmetic library

### Installation Guidelines

#### macOS

```bash
# Install dependencies with Homebrew
brew install luajit moonscript gmp

# Set GMP path (add to your .bashrc or .zshrc)
export GMP_PATH=/opt/homebrew/lib/libgmp.dylib
```

#### Linux (Debian/Ubuntu)

```bash
# Install dependencies
sudo apt-get install luajit libluajit-5.1-dev libgmp-dev

# Install MoonScript
sudo luarocks install moonscript

# Set GMP path (add to your .bashrc)
export GMP_PATH=/usr/lib/x86_64-linux-gnu/libgmp.so
```

## Performance

Based on financial portfolio simulation with 20 portfolios and 20,000 transactions:

| Metric | Value |
|--------|-------|
| Operations per second | ~74,500 ops/sec |
| Total test calculation time | ~7.2 seconds |
| Total operations performed | 518,260 |
| Memory efficiency | Successfully handles fractions with hundreds of digits |

### Performance Highlights

- Consistently performs between 64,000-130,000 operations per second
- Portfolio calculations with thousands of transactions complete in <1 second
- Correctly formats and calculates with extremely large fractions (hundreds of digits)
- Auto-reduction strategies successfully prevent excessive fraction growth

## Getting Started

### Basic Usage

```lua
-- Creating fractions
f1 = Fractional("3/4")     -- From string
f2 = Fractional(1.5)       -- From float
f3 = Fractional(7, 8)      -- From two integers

-- Arithmetic operations
sum = f1 + f2              -- Addition
diff = f3 - f1             -- Subtraction
product = f1 * f2          -- Multiplication
quotient = f3 / f2         -- Division

-- Comparison operations
if f1 < f2 then
  print("f1 is less than f2")
end

-- Display/conversion
print(f3:format("$", 2))   -- Format as currency: "$0.88"
float_val = f3:to_number() -- Convert to float (may lose precision)
```

### Advanced Features

```lua
-- Handle extremely large fractions
big_fraction = Fractional(10)^100 / Fractional(3)  -- 10^100/3

-- Get formatted output with scientific notation for very large values
print(big_fraction:format())  -- Display with appropriate scientific notation

-- Configure reduction frequency
f = Fractional(1.5)
f:set_reduction_threshold(5)  -- Reduce every 5 operations

-- Perform exact financial calculations
interest = principal * (Fractional(1) + rate)^years
```

## Library Components

- **bignum.moon/lua**: Arbitrary precision integer implementation using GMP
- **fractional.moon/lua**: Core fractional number implementation
- **cli_utils.moon/lua**: Utility functions for command-line tools
- **perf_demo.moon/lua**: Performance testing application

## Memory Management

The library properly handles memory management when interacting with GMP via FFI:

- **Garbage Collection**: Uses FFI metatypes with `__gc` metamethods to ensure proper cleanup of GMP objects when they're garbage collected by Lua.
```lua
mpz_wrapper = ffi.metatype("struct { mpz_t value; }", {
    __gc = function(self) 
        return gmp.__gmpz_clear(self.value)
    end
})

mpq_wrapper = ffi.metatype("struct { mpq_t value; }", {
    __gc = function(self)
        return gmp.__gmpq_clear(self.value)
    end
})
```

- **Explicit Cleanup**: Manually calls cleanup functions (`__gmpz_clear`, `__gmpq_clear`) after operations to prevent memory leaks with temporary objects.

- **Error Handling**: Uses `pcall` for operations that might fail, ensuring cleanup code runs even when errors occur.

## Running the Tests

### Unit Tests

Each core module includes unit tests that can be run directly:

```bash
# Run individual unit tests
./bignum.moon --test
./fractional.moon --test
./cli_utils.moon --test

# Run all tests at once
for test in {bignum,fractional,cli_utils}.moon; do ./$$test --test; done
```

### Performance Tests

The performance demo creates 20 test portfolios and runs 20,000 transactions to measure the library's performance:

```bash
# Run performance test
./perf_demo.moon > perf_demo_out.txt
```

## License

This project is licensed under the GNU General Public License v3.0 (GPL-3.0) - see the LICENSE file for details.

## Acknowledgments

- GNU Multiple Precision Library for arbitrary precision arithmetic
- LuaJIT FFI for efficient C library bindings in Lua
- MoonScript for elegant syntax over Lua