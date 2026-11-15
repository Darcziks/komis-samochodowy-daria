param(
    [Parameter(Mandatory = $true)]
    [string]$RepoPath,

    [Parameter(Mandatory = $false)]
    [string]$BaseUrl,

    [Parameter(Mandatory = $false)]
    [string]$Endpoint = "/api/service"
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

if (-not (Test-Path $RepoPath)) {
    throw "Repository not found: $RepoPath"
}

$Findings = @()

Write-Host ""
Write-Host "=== ATINS ZPWC RUNTIME SAFE ==="
Write-Host "Repo: $RepoPath"

if ([string]::IsNullOrWhiteSpace($BaseUrl)) {
    Add-Finding `
        "ZPWC runtime" `
        "INFO" `
        "BaseUrl not provided" `
        "Runtime verification skipped"
}
else {
    $base = $BaseUrl.TrimEnd("/")
    $endpointPath = "/" + $Endpoint.TrimStart("/")
    $url = $base + $endpointPath

    Write-Host "URL: $url"
    Write-Host ""

    try {
        $response = Invoke-WebRequest `
            -Uri $url `
            -Method GET `
            -TimeoutSec 15 `
            -MaximumRedirection 5 `
            -ErrorAction Stop

        $statusCode = [int]$response.StatusCode
        $contentType = [string]$response.Headers["Content-Type"]
        $body = [string]$response.Content

        if ($statusCode -ge 200 -and $statusCode -lt 300) {
            Add-Finding `
                "ZPWC runtime HTTP" `
                "PASS" `
                "Endpoint returned successful HTTP status" `
                "HTTP $statusCode"
        }
        else {
            Add-Finding `
                "ZPWC runtime HTTP" `
                "FAIL" `
                "Endpoint returned non-success HTTP status" `
                "HTTP $statusCode"
        }

        if ($contentType -match "(?i)application/json") {
            Add-Finding `
                "ZPWC runtime content-type" `
                "PASS" `
                "JSON content type detected" `
                $contentType
        }
        else {
            Add-Finding `
                "ZPWC runtime content-type" `
                "WARN" `
                "Response is not explicitly application/json" `
                $contentType
        }

        try {
            $null = $body | ConvertFrom-Json

            Add-Finding `
                "ZPWC runtime JSON" `
                "PASS" `
                "Response body contains valid JSON" `
                "JSON parse successful"
        }
        catch {
            Add-Finding `
                "ZPWC runtime JSON" `
                "FAIL" `
                "Response body is not valid JSON" `
                $_.Exception.Message
        }
    }
    catch {
        $status = $null

        if ($null -ne $_.Exception.Response) {
            try {
                $status = [int]$_.Exception.Response.StatusCode
            }
            catch {
                $status = $null
            }
        }

        if ($null -ne $status) {
            Add-Finding `
                "ZPWC runtime HTTP" `
                "FAIL" `
                "Endpoint request failed" `
                "HTTP $status"
        }
        else {
            Add-Finding `
                "ZPWC runtime network" `
                "FAIL" `
                "Endpoint could not be reached" `
                $_.Exception.Message
        }
    }
}

Write-Host ""
$Findings | Format-Table -AutoSize -Wrap

$passCount = @($Findings | Where-Object Status -eq "PASS").Count
$warnCount = @($Findings | Where-Object Status -eq "WARN").Count
$failCount = @($Findings | Where-Object Status -eq "FAIL").Count
$infoCount = @($Findings | Where-Object Status -eq "INFO").Count

Write-Host ""
Write-Host "PASS: $passCount | WARN: $warnCount | FAIL: $failCount | INFO: $infoCount"
Write-Host ""
Write-Host "SAFE MODE:"
Write-Host "- no student secrets are read"
Write-Host "- no direct database connection is used"
Write-Host "- only the provided public endpoint is contacted"
Write-Host "- findings require instructor verification"

$repoName = Split-Path $RepoPath -Leaf
$toolsRoot = Split-Path $PSScriptRoot -Parent
$reportDir = Join-Path (Join-Path $toolsRoot "reports") $repoName

if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$reportPath = Join-Path $reportDir "_ATINS_RUNTIME_REVIEW_ZPWC.txt"

@(
    "ATINS ZPWC RUNTIME SAFE"
    "Repo: $RepoPath"
    "BaseUrl: $BaseUrl"
    "Endpoint: $Endpoint"
    ""
    ($Findings | Format-Table -AutoSize -Wrap | Out-String)
    "PASS: $passCount | WARN: $warnCount | FAIL: $failCount | INFO: $infoCount"
    ""
    "Runtime technical precheck. Instructor verification required."
) | Set-Content -Path $reportPath -Encoding UTF8

Write-Host ""
Write-Host "Report: $reportPath"