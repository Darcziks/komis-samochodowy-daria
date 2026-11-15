param(
    [Parameter(Mandatory = $true)]
    [string]$RepoPath
)

$ErrorActionPreference = "Stop"

$toolsDir = $PSScriptRoot
$reviewScript = Join-Path $toolsDir "review-tb-safe.ps1"

if (-not (Test-Path $reviewScript)) {
    throw "Missing review script: $reviewScript"
}

if (-not (Test-Path $RepoPath)) {
    throw "Repository not found: $RepoPath"
}

Write-Host ""
Write-Host "=== ATINS PREPARE TB ==="
Write-Host "Repo: $RepoPath"
Write-Host ""

& $reviewScript -RepoPath $RepoPath

if ($LASTEXITCODE -ne 0 -and $null -ne $LASTEXITCODE) {
    Write-Warning "review-tb-safe.ps1 returned exit code $LASTEXITCODE"
}

$repoName = Split-Path $RepoPath -Leaf
$root = Split-Path $toolsDir -Parent
$reportDir = Join-Path (Join-Path $root "reports") $repoName
$reportPath = Join-Path $reportDir "_ATINS_PRECHECK_TB.txt"

if (-not (Test-Path $reportPath)) {
    throw "TB report was not generated: $reportPath"
}

Write-Host ""
Write-Host "=== TB PRECHECK READY ==="
Write-Host "Report: $reportPath"
Write-Host ""
Write-Host "Instructor verification required."