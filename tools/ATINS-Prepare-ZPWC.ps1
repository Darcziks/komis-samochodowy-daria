param(
    [Parameter(Mandatory = $true)]
    [string]$RepoPath,

    [Parameter(Mandatory = $false)]
    [string]$BaseUrl,

    [Parameter(Mandatory = $false)]
    [string]$Endpoint = "/api/service"
)

$ErrorActionPreference = "Stop"

$toolsDir = $PSScriptRoot

$staticScript = Join-Path $toolsDir "review-zpwc-safe.ps1"
$runtimeScript = Join-Path $toolsDir "review-zpwc-runtime-safe.ps1"

if (-not (Test-Path $RepoPath)) {
    throw "Repository not found: $RepoPath"
}

if (-not (Test-Path $staticScript)) {
    throw "Missing static review script: $staticScript"
}

if (-not (Test-Path $runtimeScript)) {
    throw "Missing runtime review script: $runtimeScript"
}

Write-Host ""
Write-Host "=== ATINS PREPARE ZPWC ==="
Write-Host "Repo: $RepoPath"
Write-Host ""

# ------------------------------------------------------------
# STATIC PRECHECK
# ------------------------------------------------------------
Write-Host "=== STATIC PRECHECK ==="

& $staticScript -RepoPath $RepoPath

# ------------------------------------------------------------
# RUNTIME PRECHECK
# ------------------------------------------------------------
Write-Host ""
Write-Host "=== RUNTIME PRECHECK ==="

if ([string]::IsNullOrWhiteSpace($BaseUrl)) {
    & $runtimeScript `
        -RepoPath $RepoPath `
        -Endpoint $Endpoint
}
else {
    & $runtimeScript `
        -RepoPath $RepoPath `
        -BaseUrl $BaseUrl `
        -Endpoint $Endpoint
}

# ------------------------------------------------------------
# REPORT PATHS
# ------------------------------------------------------------
$repoName = Split-Path $RepoPath -Leaf
$root = Split-Path $toolsDir -Parent
$reportDir = Join-Path (Join-Path $root "reports") $repoName

$staticReport = Join-Path $reportDir "_ATINS_PRECHECK_ZPWC.txt"
$runtimeReport = Join-Path $reportDir "_ATINS_RUNTIME_REVIEW_ZPWC.txt"
$combinedReport = Join-Path $reportDir "_ATINS_PRECHECK_ZPWC_COMBINED.txt"

if (-not (Test-Path $staticReport)) {
    throw "Static ZPWC report was not generated: $staticReport"
}

if (-not (Test-Path $runtimeReport)) {
    throw "Runtime ZPWC report was not generated: $runtimeReport"
}

# ------------------------------------------------------------
# COMBINED REPORT
# ------------------------------------------------------------
$staticText = Get-Content -LiteralPath $staticReport -Raw
$runtimeText = Get-Content -LiteralPath $runtimeReport -Raw

$headRaw = git -C $RepoPath rev-parse --short HEAD 2>$null
$branchRaw = git -C $RepoPath branch --show-current 2>$null

$head = if ([string]::IsNullOrWhiteSpace([string]$headRaw)) {
    "UNKNOWN"
}
else {
    [string]$headRaw
}

$branch = if ([string]::IsNullOrWhiteSpace([string]$branchRaw)) {
    "detached HEAD"
}
else {
    [string]$branchRaw
}

$combined = @"
ATINS ZPWC COMBINED PRECHECK

Repo: $RepoPath
Branch: $branch
HEAD: $head
BaseUrl: $BaseUrl
Endpoint: $Endpoint

============================================================
STATIC PRECHECK
============================================================

$staticText

============================================================
RUNTIME PRECHECK
============================================================

$runtimeText

============================================================
INTERPRETATION
============================================================

Static PASS does not prove that a public deployment is reachable.
Runtime PASS does not prove business correctness.
A missing BaseUrl means runtime verification was not performed.
Instructor verification remains required.
"@

[System.IO.File]::WriteAllText(
    $combinedReport,
    $combined,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host ""
Write-Host "=== ZPWC PRECHECK READY ==="
Write-Host "Static report : $staticReport"
Write-Host "Runtime report: $runtimeReport"
Write-Host "Combined      : $combinedReport"
Write-Host ""
Write-Host "Instructor verification required."