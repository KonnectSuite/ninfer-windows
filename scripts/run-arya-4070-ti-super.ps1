# Serve the pinned GSQ3 engine with the measured Arya RTX 4070 Ti SUPER profile.
[CmdletBinding()]
param(
    [string]$Model = $env:NINFER_ARTIFACT,
    [ValidateRange(1024, 102400)][int]$Context = 102400,
    [ValidateRange(1, 65535)][int]$Port = 8083,
    [switch]$CheckOnly
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$profile = Get-Content -LiteralPath (Join-Path $root 'config/arya-4070-ti-super.json') -Raw | ConvertFrom-Json
if (-not $Model) { $Model = Join-Path $root 'models/qwen3_8_27b_gsq3.ninfer' }
$artifact = (Resolve-Path -LiteralPath $Model).Path
if (-not (Test-Path -LiteralPath $artifact -PathType Leaf)) { throw 'Model must be an existing file.' }
Get-Command docker -ErrorAction Stop | Out-Null
& docker image inspect $profile.image *> $null
if ($LASTEXITCODE -ne 0) { throw "Pinned engine image is missing. Run: docker pull $($profile.image)" }

$runArgs = @(
    'run', '--rm', '--gpus', 'all',
    '--label', 'dev.arya.ninfer=standalone-4070-ti-super',
    '-p', "127.0.0.1:${Port}:8080",
    '--mount', "type=bind,source=$artifact,target=/models/model.ninfer,readonly",
    $profile.image, 'ninfer-serve', '/models/model.ninfer',
    '--host', '0.0.0.0', '--port', '8080',
    '--max-context', "$Context", '--kv-capacity', "$Context", '--kv-dtype', $profile.kvDtype,
    '--max-concurrency', '1', '--max-pending-requests', '16',
    '--prefill-chunk', "$($profile.prefillChunk)", '--host-kv-mib', "$($profile.hostKvMiB)",
    '--spec', 'mtp', '--draft-tokens', "$($profile.draftTokens)", '--lm-head-draft',
    '--ngram', $profile.ngram, '--vision', '--preserve-thinking',
    '--temperature', '1', '--top-k', '20', '--top-p', '0.95', '--min-p', '0',
    '--presence-penalty', '0', '--frequency-penalty', '0'
)
if ($env:NINFER_API_KEY) {
    $runArgs += @('--api-key', $env:NINFER_API_KEY)
}
if ($CheckOnly) {
    Write-Output "Ready: pinned image and model found; ${Context} context, MTP3, vision, localhost:$Port. No server started."
    return
}
Write-Output "Serving Arya NInfer on http://127.0.0.1:$Port/v1; stop with Ctrl+C."
& docker @runArgs
if ($LASTEXITCODE -ne 0) { throw "Docker exited with code $LASTEXITCODE. Existing servers were not stopped." }
