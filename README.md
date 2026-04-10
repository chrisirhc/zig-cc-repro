# zig-cc-repro

Reproduction for [ziglang/zig#23287](https://github.com/ziglang/zig/issues/23287):
**`zig c++` regression — `-l :filename.so` no longer works in zig 0.14.0+.**

## The Bug

In zig 0.13.0, linking against a shared library by its exact filename using the
`-l :filename.so` syntax (as documented in the
[GNU ld manual](https://linux.die.net/man/1/ld)) worked correctly.

Starting with zig 0.14.0, the same invocation fails with:

```
ld.lld: error: unable to find library -l:mylib.so
```

The `-l :mylib.so` form (with or without the space) instructs the linker to
search for the literal filename `mylib.so` in the library search path, instead
of the default `libmylib.so` form.  This is useful for shared libraries that do
not follow the `lib` prefix convention.

## Files

| File | Purpose |
|------|---------|
| `mylib.cpp` | Simple shared library that exports a C symbol |
| `main.cpp` | Executable that calls the symbol from `mylib.so` |
| `Makefile` | Manual build using `zig c++` (update `CXX` to point to zig) |
| `reproduce.sh` | Automated reproduction script (see below) |
| `.github/workflows/ci.yml` | CI workflow that validates the bug on every PR and push |

## Reproduction Steps

### Automated (recommended)

```bash
bash reproduce.sh
```

The script:
1. Downloads zig 0.13.0 and 0.14.0 from <https://ziglang.org/download/>.
2. Builds `mylib.so` with each version.
3. Attempts to link `main` using `-l:mylib.so`.
4. Reports **PASS** (bug confirmed) when 0.13.0 succeeds and 0.14.0 fails.

### Manual

```bash
# Download zig 0.14.0
mkdir -p zig
curl -L https://ziglang.org/download/0.14.0/zig-linux-x86_64-0.14.0.tar.xz \
  | tar -xJ -C zig

ZIG=./zig/zig-linux-x86_64-0.14.0/zig

# Build the shared library
$ZIG c++ -fPIC -shared -o mylib.so mylib.cpp

# Link — this fails with zig 0.14.0
$ZIG c++ -o main main.cpp -L. -l:mylib.so
# ld.lld: error: unable to find library -l:mylib.so
```

## CI Status

The GitHub Actions workflow (`.github/workflows/ci.yml`) runs on every push to
`main` and on every pull request.  The job exits **success** when the bug is
confirmed reproducible (zig 0.13.0 works, zig 0.14.0 fails), and **failure**
when the observed behaviour no longer matches — which would indicate either the
bug has been fixed or an unexpected regression has occurred.
