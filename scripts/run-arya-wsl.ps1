# Run the Ada engine directly in WSL, preserving the Arya model and MTP/vision profile.
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Model,
    [string]$Distribution = 'Ubuntu-24.04',
    [string]$Binary = '/opt/arya-ninfer/bin/ninfer-serve',
    [ValidateRange(4096, 102400)][int]$Context = 102400,
    [ValidateRange(1024, 65535)][int]$Port = 8083,
    [switch]$CheckOnly
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$profile = Get-Content -LiteralPath (Join-Path $root 'config/arya-4070-ti-super.json') -Raw | ConvertFrom-Json
$artifact = (Resolve-Path -LiteralPath $Model).Path.Replace('\','/')
if ($artifact -notmatch '^[A-Za-z]:/') { throw 'Select an existing local Windows model file.' }
$linuxModel = '/mnt/' + $artifact.Substring(0,1).ToLowerInvariant() + $artifact.Substring(2)
& wsl.exe -d $Distribution -- test -x $Binary
if ($LASTEXITCODE -ne 0) { throw 'WSL NInfer binary is unavailable. Build it first.' }
if ($CheckOnly) {
    Write-Output "Ready: WSL binary and model found; $Context context, MTP3, vision. No server started."
    return
}
$serveArgs = @('-d', $Distribution, '--', 'env', 'LD_LIBRARY_PATH=/usr/lib/wsl/lib:/usr/local/cuda/lib',
    $Binary, $linuxModel, '--host', '127.0.0.1', '--port', "$Port",
    '--max-context', "$Context", '--kv-capacity', "$Context", '--kv-dtype', $profile.kvDtype,
    '--prefill-chunk', "$($profile.prefillChunk)", '--host-kv-mib', "$($profile.hostKvMiB)",
    '--max-concurrency', '1', '--max-pending-requests', '16',
    '--spec', 'mtp', '--draft-tokens', "$($profile.draftTokens)", '--lm-head-draft',
    '--ngram', $profile.ngram, '--vision', '--preserve-thinking')
if ($env:NINFER_API_KEY) { $serveArgs += @('--api-key', $env:NINFER_API_KEY) }
Write-Output "Serving Arya NInfer directly in WSL at http://127.0.0.1:$Port/v1; stop with Ctrl+C."
& wsl.exe @serveArgs
if ($LASTEXITCODE -ne 0) { throw "NInfer exited with code $LASTEXITCODE." }
