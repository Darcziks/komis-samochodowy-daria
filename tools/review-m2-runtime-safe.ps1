param(
    [Parameter(Mandatory = $true)]
    [string]$RepoPath,

    [Parameter(Mandatory = $false)]
    [string]$BaseUrl = ""
)

$ErrorActionPreference = "Stop"

function Add-Finding {
    param(
        [string]$Area,
        [ValidateSet("PASS","WARN","FAIL","INFO")]
        [string]$Status,
        [string]$Observation,
        [string]$Evidence
    )

    $script:Findings += [PSCustomObject]@{
        Area        = $Area
        Status      = $Status
        Observation = $Observation
        Evidence    = $Evidence
    }
}

function Test-JsonResponse {
    param([string]$Content)

    if ([string]::IsNullOrWhiteSpace($Content)) {
        return $false
    }

    try {
        $null = $Content | ConvertFrom-Json
        return $true
    }
    catch {
        return $false
    }
}

function Invoke-EndpointCheck {
    param(
        [string]$Name,
        [string]$Url
    )

    try {
        $response = Invoke-WebRequest -Uri $Url -Method GET -TimeoutSec 15 -UseBasicParsing -ErrorAction Stop

        $statusCode = [int]$response.StatusCode
        $contentType = [string]$response.Headers["Content-Type"]
        $isJson = Test-JsonResponse -Content ([string]$response.Content)

        if ($statusCode -ge 200 -and $statusCode -lt 300) {
            Add-Finding $Name "PASS" "Endpoint returned HTTP $statusCode" $Url
        }
        else {
            Add-Finding $Name "WARN" "Endpoint returned HTTP $statusCode" $Url
        }

        if ($contentType -match "(?i)application/json") {
            Add-Finding "$Name content-type" "PASS" "Response Content-Type is JSON" $contentType
        }
        else {
            Add-Finding "$Name content-type" "WARN" "Content-Type does not indicate JSON" $contentType
        }

        if ($isJson) {
            Add-Finding "$Name JSON" "PASS" "Response body is valid JSON" "Full response body was not stored"
        }
        else {
            Add-Finding "$Name JSON" "FAIL" "Response body is not valid JSON" "Full response body was not stored"
        }
    }
    catch {
        $message = $_.Exception.Message

        if ($null -ne $_.Exception.Response) {
            try {
                $statusCode = [int]$_.Exception.Response.StatusCode
                Add-Finding $Name "FAIL" "Endpoint returned HTTP error $statusCode" $Url
                return
            }
            catch {
            }
        }

        Add-Finding $Name "FAIL" "Endpoint request failed" $message
    }
}

if (-not (Test-Path $RepoPath)) {
    throw "Repository not found: $RepoPath"
}

if (-not (Test-Path (Join-Path $RepoPath ".git"))) {
    throw "RepoPath is not a Git repository: $RepoPath"
}

$Findings = @()

$branch = git -C $RepoPath branch --show-current 2>$null
$head = git -C $RepoPath rev-parse --short HEAD 2>$null

Add-Finding "Git" "INFO" "Audited repository state" "branch=$branch; HEAD=$head"

if ([string]::IsNullOrWhiteSpace($BaseUrl)) {
    Add-Finding "M2 runtime" "INFO" "BaseUrl not provided - smoke test skipped" "Use -BaseUrl https://application-address"
}
elseif ($BaseUrl -notmatch "^https?://") {
    Add-Finding "M2 runtime" "FAIL" "Invalid BaseUrl" "Only http:// and https:// addresses are accepted"
}
else {
    $BaseUrl = $BaseUrl.TrimEnd("/")

    Add-Finding "M2 runtime" "INFO" "API smoke test started" $BaseUrl

    Invoke-EndpointCheck -Name "M2 runtime /health" -Url "$BaseUrl/health"
    Invoke-EndpointCheck -Name "M2 runtime /api/cars" -Url "$BaseUrl/api/cars"
}

Write-Host ""
Write-Host "=== ATINS M2 Runtime Review SAFE ==="
Write-Host "Repo:    $RepoPath"
Write-Host "BaseUrl: $BaseUrl"
Write-Host ""

$Findings | Format-Table -AutoSize -Wrap

$passCount = @($Findings | Where-Object Status -eq "PASS").Count
$warnCount = @($Findings | Where-Object Status -eq "WARN").Count
$failCount = @($Findings | Where-Object Status -eq "FAIL").Count
$infoCount = @($Findings | Where-Object Status -eq "INFO").Count

Write-Host ""
Write-Host "PASS: $passCount | WARN: $warnCount | FAIL: $failCount | INFO: $infoCount"

Write-Host ""
Write-Host "RULES:"
Write-Host "- no student DATABASE_URL is used"
Write-Host "- no student authentication secrets are used"
Write-Host "- full API responses are not stored"
Write-Host "- only the explicitly provided BaseUrl is tested"

$repoName = Split-Path $RepoPath -Leaf
$reviewsRoot = Split-Path $PSScriptRoot -Parent
$reportDir = Join-Path $reviewsRoot ("reports\" + $repoName)

if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$reportPath = Join-Path $reportDir "_ATINS_RUNTIME_REVIEW_M2.txt"

@(
    "ATINS M2 Runtime Review SAFE"
    "Repo: $RepoPath"
    "Branch: $branch"
    "HEAD: $head"
    "BaseUrl: $BaseUrl"
    ""
    ($Findings | Format-Table -AutoSize -Wrap | Out-String)
    "PASS: $passCount | WARN: $warnCount | FAIL: $failCount | INFO: $infoCount"
    ""
    "Student secrets were not used."
    "This report supports instructor review and is not a final assessment."
) | Set-Content -Path $reportPath -Encoding UTF8

Write-Host ""
Write-Host "Report: $reportPath"
