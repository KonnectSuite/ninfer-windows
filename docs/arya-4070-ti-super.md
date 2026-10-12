# Arya NInfer for RTX 4070 Ti SUPER

This branch starts from [roofkid/ninfer-4080](https://github.com/roofkid/ninfer-4080), preserving its GSQ3 weights, Ada sm_89 kernels, MTP and vision support. It adds the configuration used successfully on Arya's RTX 4070 Ti SUPER 16 GB. The original Windows fork remains on this repository's master branch. Apache-2.0 licensing and upstream attribution remain intact.

## Windows setup

Install Docker Desktop with its WSL2 backend and NVIDIA GPU support. Use the existing verified `qwen3_8_27b_gsq3.ninfer` artifact or the upstream download script. The model artifact is separate from this source repository.

```powershell
docker pull roofkid/ninfer-4080@sha256:bfbf286f429651295ed73feb8ef4f52a7bac30237d995c7e8dfeb37bb79867f9
./scripts/run-arya-4070-ti-super.ps1 -Model C:/AI/NInfer4080/models/qwen3_8_27b_gsq3.ninfer -CheckOnly
./scripts/run-arya-4070-ti-super.ps1 -Model C:/AI/NInfer4080/models/qwen3_8_27b_gsq3.ninfer
```

The endpoint is `http://127.0.0.1:8083/v1`, with model ID `qwen3.8-27b`. Set `NINFER_API_KEY` in the process environment to require bearer authentication. The launcher does not print its value. Stop the corresponding Control Center engine before using this standalone launcher on the same port. The launcher never stops another server.

The profile uses 102400 context tokens, rk4v4-e8 KV, a 1024-token prefill chunk, MTP with three draft tokens, vision, one request lane and n-gram speculation disabled. A 4096 MiB host KV setting does not establish arbitrary active-context RAM offload. `-Context 65536` selects a smaller allocation; `-Port` selects another localhost port. `-CheckOnly` verifies file and image availability without loading the GPU.

## Evidence and limits

Existing installation checks on RTX 4070 Ti SUPER, driver 610.88 and the pinned published engine measured approximately 84.5 and 87.7 output tokens per second including request latency for two 512-token runs. Vision, code correction and tool selection/roundtrip checks passed. A guarded Arya agent correctly read an offline L5X rung and its expected states. Strict JSON formatting failed because answers included fences or surrounding prose. The user also reported roughly 81 tokens per second in a real coding chat.

These measurements describe the existing published engine, not a rebuilt Arya binary or a kernel optimization in this branch. Configured 100K passed a load/inference smoke; full 100K retrieval was not measured. Maintainer repeated-corpus speed claims are not representative coding measurements. This branch ships a host profile and pinned launcher, not a new independently benchmarked engine image. It does not replace the running Control Center installation automatically.
