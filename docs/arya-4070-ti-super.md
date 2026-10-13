# Arya NInfer for RTX 4070 Ti SUPER

This branch starts from [roofkid/ninfer-4080](https://github.com/roofkid/ninfer-4080), preserving its GSQ3 weights, Ada sm_89 kernels, MTP and vision support. It adds the configuration used successfully on Arya's RTX 4070 Ti SUPER 16 GB. The original Windows fork remains on this repository's master branch. Apache-2.0 licensing and upstream attribution remain intact.

## Direct WSL setup

The Docker-free route runs the same Ada engine in Ubuntu 24.04 with NVIDIA GPU access. It requires a CUDA compiler (12.8 or newer), CMake 3.28+, Ninja, a C++20 compiler, pkg-config, FFmpeg development libraries and libcurl development libraries. Keep source and build outputs on the Linux filesystem for build performance. On Arya's host, CUDA 13.0 is already installed beside FreeToken; the WSL driver libraries must precede CUDA libraries in the runtime search path.

```bash
sudo apt-get install --yes --no-install-recommends cmake ninja-build g++ pkg-config libavcodec-dev libavformat-dev libavutil-dev libswscale-dev libcurl4-openssl-dev
bash scripts/build-arya-wsl.sh
```

The build script installs binaries under `/opt/arya-ninfer/bin`; that directory must be writable by the build user. Override `NINFER_PREFIX`, `CUDA_HOME` or `NINFER_BUILD_JOBS` when needed. From Windows, use the existing artifact:

```powershell
./scripts/run-arya-wsl.ps1 -Model C:/AI/NInfer4080/models/qwen3_8_27b_gsq3.ninfer -CheckOnly
./scripts/run-arya-wsl.ps1 -Model C:/AI/NInfer4080/models/qwen3_8_27b_gsq3.ninfer
```

`-Distribution` and `-Binary` select the WSL installation; `-Context` and `-Port` select serving limits. This launcher makes no Docker calls. Control Center can instead manage the binary using its `ninfer.wsl` configuration, with distribution, binary and libraryPath. The managed helper verifies PID, start time, executable and arguments before stopping its process group. Do not start the standalone launcher while Control Center already serves the same model.

## Docker fallback

The original pinned Docker launcher remains available as a fallback. It requires Docker Desktop with its WSL2 backend and NVIDIA GPU support. Use the existing verified `qwen3_8_27b_gsq3.ninfer` artifact or the upstream download script. The model artifact is separate from this source repository.

```powershell
docker pull roofkid/ninfer-4080@sha256:bfbf286f429651295ed73feb8ef4f52a7bac30237d995c7e8dfeb37bb79867f9
./scripts/run-arya-4070-ti-super.ps1 -Model C:/AI/NInfer4080/models/qwen3_8_27b_gsq3.ninfer -CheckOnly
./scripts/run-arya-4070-ti-super.ps1 -Model C:/AI/NInfer4080/models/qwen3_8_27b_gsq3.ninfer
```

The endpoint is `http://127.0.0.1:8083/v1`, with model ID `qwen3.8-27b`. Set `NINFER_API_KEY` in the process environment to require bearer authentication. The launcher does not print its value. Stop the corresponding Control Center engine before using this standalone launcher on the same port. The launcher never stops another server.

The profile uses 102400 context tokens, rk4v4-e8 KV, a 2688-token prefill chunk, MTP with three draft tokens, the MTP3 n-gram chain, vision and one request lane. The chain and the chunk size are the upstream long-context serve defaults; both replace this branch's earlier `--ngram off` and `--prefill-chunk 1024` pin, which reproduced the control column of the published table rather than its default profile. A 4096 MiB host KV setting does not establish arbitrary active-context RAM offload. `-Context 65536` selects a smaller allocation; `-Port` selects another localhost port. `-CheckOnly` verifies file and image availability without loading the GPU.

## Evidence and limits

Existing installation checks on RTX 4070 Ti SUPER, driver 610.88 and the pinned published engine measured approximately 84.5 and 87.7 output tokens per second including request latency for two 512-token runs. Vision, code correction and tool selection/roundtrip checks passed. A guarded Arya agent correctly read an offline L5X rung and its expected states. Strict JSON formatting failed because answers included fences or surrounding prose. The user also reported roughly 81 tokens per second in a real coding chat.

The direct WSL build with CUDA 13.0 passed the same code correction, tool selection/roundtrip and PNG interpretation checks. Two 512-token output runs measured 90.9 and 96.5 tokens per second including request latency, with thinking off and n-gram chaining off. Strict JSON remained fenced. Control Center Start, Stop, Restart, tuning, logs and both model listings passed. The initial bind-based port check falsely rejected TCP cooldown sockets; the corrected listener check passed the live restart and retained foreign-listener refusal.

These are two short runs, not evidence of a general Docker-removal or kernel speedup. Configured 100K passed load/inference checks; full 100K retrieval was not measured. Maintainer repeated-corpus speed claims are not representative coding measurements. This branch supplies a source build and launchers; the Docker image remains an upstream fallback, and source checkout alone does not switch a Control Center installation.

The default profile resolves a request to `xhigh` reasoning. Across these probes that put 224-482 of 512 output tokens in the reasoning channel, so a client that wants decode throughput rather than reasoning sends `reasoning_effort: "none"` or `"low"` per request. Turning reasoning off moved the code probe from 83.8 to 104.9 tok/s on the same prompt.

Measured on the WSL build, 2026-10-12, driver 610.88, one 512-token request per probe, sampling at the Qwen3.8 thinking defaults. On the control profile (`--ngram off --prefill-chunk 1024`) the code probe decoded at 104.9 tok/s and a repetitive JSON probe at 108.2; on the default profile (`--ngram chain --prefill-chunk 2688`) the same code probe decoded at 104.0-107.9 and the repetitive probe at 142.3 and 165.9 across two runs. The chain therefore does not move ordinary code output and moves repetitive structured output by roughly 30-50%, which is the fixture property the published table's caveat describes. A 6,095-token prompt prefilled at 2,110 tok/s with a 1024-token chunk against 2,003-2,046 tok/s with a 2688-token chunk: the documented chunk gain applies near 100K context and is not visible at 6K. These are single runs on one machine, not a kernel measurement, and the published prefill and decode figures remain fixture conditions this branch has not reproduced offline.
