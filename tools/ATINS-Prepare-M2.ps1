param(
    [Parameter(Mandatory = $true)]
    [string]$RepoPath,

    [Parameter(Mandatory = $false)]
    [string]$BaseUrl = ""
)

$ErrorActionPreference = "Stop"

$toolsRoot = $PSScriptRoot
$reviewsRoot = Split-Path $toolsRoot -Parent
$repoName = Split-Path $RepoPath -Leaf
$reportDir = Join-Path $reviewsRoot ("reports\" + $repoName)

if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$contentScript = Join-Path $toolsRoot "review-content-safe.ps1"
$runtimeScript = Join-Path $toolsRoot "review-m2-runtime-safe.ps1"

if (-not (Test-Path $contentScript)) {
    throw "Missing script: $contentScript"
}

if (-not (Test-Path $runtimeScript)) {
    throw "Missing script: $runtimeScript"
}

Write-Host ""
Write-Host "=== ATINS M2 PRECHECK ==="
Write-Host "Repo:    $RepoPath"
Write-Host "BaseUrl: $BaseUrl"
Write-Host ""

& $contentScript `
    -RepoPath $RepoPath `
    -Milestone "M2"

if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
    Write-Host "WARN: content review returned exit code $LASTEXITCODE"
}

& $runtimeScript `
    -RepoPath $RepoPath `
    -BaseUrl $BaseUrl

if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
    Write-Host "WARN: runtime review returned exit code $LASTEXITCODE"
}

$contentReport = Join-Path $reportDir "_ATINS_CONTENT_REVIEW_M2.txt"
$runtimeReport = Join-Path $reportDir "_ATINS_RUNTIME_REVIEW_M2.txt"
$combinedReport = Join-Path $reportDir "_ATINS_PRECHECK_M2.txt"

$sections = @()

$sections += "ATINS M2 PRECHECK"
$sections += "Repo: $RepoPath"
$sections += "BaseUrl: $BaseUrl"
$sections += ""

$sections += "============================================================"
$sections += "SECTION 1 - STATIC / CONTENT REVIEW"
$sections += "============================================================"

if (Test-Path $contentReport) {
    $sections += Get-Content $contentReport
}
else {
    $sections += "CONTENT REVIEW REPORT NOT FOUND"
}

$sections += ""
$sections += "============================================================"
$sections += "SECTION 2 - RUNTIME REVIEW"
$sections += "============================================================"

if (Test-Path $runtimeReport) {
    $sections += Get-Content $runtimeReport
}
else {
    $sections += "RUNTIME REVIEW REPORT NOT FOUND"
}

$sections += ""
$sections += "============================================================"
$sections += "SECTION 3 - INSTRUCTOR CHECK"
$sections += "============================================================"
$sections += "Manual verification still required:"
$sections += "- API contract quality"
$sections += "- correctness of data mapping"
$sections += "- image_key / imageUrl flow"
$sections += "- separation of client / API / database / storage responsibilities"
$sections += "- semantic correctness of returned data"
$sections += ""
$sections += "This precheck supports instructor review and is not a final assessment."

$sections | Set-Content -Path $combinedReport -Encoding UTF8

Write-Host ""
Write-Host "Combined M2 precheck:"
Write-Host $combinedReport