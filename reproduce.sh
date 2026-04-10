#!/usr/bin/env bash
# reproduce.sh
#
# Reproduces the zig c++ regression where `-l :filename.so` no longer works.
# Reference: https://github.com/ziglang/zig/issues/23287
#
# The script downloads zig 0.14.0 (broken) and zig 0.13.0 (working), then
# demonstrates the difference.  It exits 0 when the bug is confirmed present
# (i.e. 0.13.0 succeeds and 0.14.0 fails), and non-zero otherwise.

set -euo pipefail

ZIG_DIR="${ZIG_DIR:-./zig}"
ARCH="$(uname -m)"  # e.g. x86_64 or aarch64
OS="linux"

ZIG_0_13_VERSION="0.13.0"
ZIG_0_14_VERSION="0.14.0"

ZIG_BASE_URL="https://ziglang.org/download"

download_zig() {
    local version="$1"
    local tarball="zig-${OS}-${ARCH}-${version}.tar.xz"
    local dir="${ZIG_DIR}/zig-${OS}-${ARCH}-${version}"

    if [ -d "$dir" ]; then
        echo "zig ${version} already present at ${dir}"
        return 0
    fi

    mkdir -p "$ZIG_DIR"
    local url="${ZIG_BASE_URL}/${version}/${tarball}"
    echo "Downloading zig ${version} from ${url} ..."
    curl -fL --retry 3 --retry-delay 5 -o "${ZIG_DIR}/${tarball}" "$url"
    tar -xJf "${ZIG_DIR}/${tarball}" -C "$ZIG_DIR"
    rm "${ZIG_DIR}/${tarball}"
    echo "zig ${version} extracted to ${dir}"
}

run_test() {
    local zig_bin="$1"
    local label="$2"
    local workdir
    workdir="$(mktemp -d)"
    cp main.cpp mylib.cpp "$workdir/"

    echo ""
    echo "=== Testing with ${label} ==="
    echo "zig binary: ${zig_bin}"

    echo ">> Building shared library: zig c++ -fPIC -shared -o mylib.so mylib.cpp"
    if ! "$zig_bin" c++ -fPIC -shared -o "${workdir}/mylib.so" "${workdir}/mylib.cpp"; then
        echo "FAIL: could not build mylib.so"
        rm -rf "$workdir"
        return 1
    fi

    echo ">> Linking main: zig c++ -o main main.cpp -L. -l :mylib.so"
    local link_output
    if link_output=$("$zig_bin" c++ -o "${workdir}/main" "${workdir}/main.cpp" \
        -L"${workdir}" "-l:mylib.so" 2>&1); then
        echo "PASS: linked successfully"
        rm -rf "$workdir"
        return 0
    else
        echo "FAIL: linker error"
        echo "$link_output"
        rm -rf "$workdir"
        return 1
    fi
}

# Download both versions
download_zig "$ZIG_0_13_VERSION"
download_zig "$ZIG_0_14_VERSION"

ZIG_0_13="${ZIG_DIR}/zig-${OS}-${ARCH}-${ZIG_0_13_VERSION}/zig"
ZIG_0_14="${ZIG_DIR}/zig-${OS}-${ARCH}-${ZIG_0_14_VERSION}/zig"

# zig 0.13.0 should succeed
if run_test "$ZIG_0_13" "zig ${ZIG_0_13_VERSION} (expected: PASS)"; then
    echo ""
    echo "[OK] zig ${ZIG_0_13_VERSION} succeeded as expected."
    RESULT_013=0
else
    echo ""
    echo "[UNEXPECTED] zig ${ZIG_0_13_VERSION} failed — behaviour may have changed further."
    RESULT_013=1
fi

# zig 0.14.0 should fail with the bug
if run_test "$ZIG_0_14" "zig ${ZIG_0_14_VERSION} (expected: FAIL due to bug)"; then
    echo ""
    echo "[UNEXPECTED] zig ${ZIG_0_14_VERSION} succeeded — bug may have been fixed!"
    RESULT_014=0
else
    echo ""
    echo "[OK] zig ${ZIG_0_14_VERSION} failed as expected — bug confirmed."
    RESULT_014=1
fi

echo ""
echo "=== Summary ==="
echo "zig ${ZIG_0_13_VERSION}: $([ "$RESULT_013" -eq 0 ] && echo PASS || echo FAIL)"
echo "zig ${ZIG_0_14_VERSION}: $([ "$RESULT_014" -eq 1 ] && echo 'FAIL (bug confirmed)' || echo 'PASS (bug fixed?)')"

# Exit 0 only when the regression is confirmed: 0.13 works, 0.14 fails
if [ "$RESULT_013" -eq 0 ] && [ "$RESULT_014" -eq 1 ]; then
    echo ""
    echo "Bug confirmed: regression present in zig ${ZIG_0_14_VERSION}."
    exit 0
else
    echo ""
    echo "Unexpected result — either the bug was fixed or a new problem appeared."
    exit 1
fi
