#!/usr/bin/env bash
# Build the sm_89 engine with its media dependencies in an existing Ubuntu WSL distribution.
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
prefix="${NINFER_PREFIX:-/opt/arya-ninfer}"
cuda="${CUDA_HOME:-/usr/local/cuda}"
export PATH="$cuda/bin:$PATH"
cmake -S "$root" -B "$prefix/build" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_CUDA_ARCHITECTURES=89 \
  -DCUDAToolkit_ROOT="$cuda" -DNINFER_BUILD_APPS=ON \
  -DBUILD_TESTING=OFF -DNINFER_BUILD_BENCHMARKS=OFF
cmake --build "$prefix/build" --parallel "${NINFER_BUILD_JOBS:-4}" --target ninfer ninfer-serve
mkdir -p "$prefix/bin"
cp "$prefix/build/apps/ninfer" "$prefix/bin/ninfer"
cp "$prefix/build/apps/ninfer-serve" "$prefix/bin/ninfer-serve"
