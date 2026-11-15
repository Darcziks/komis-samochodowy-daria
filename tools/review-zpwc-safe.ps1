param(
    [Parameter(Mandatory = $true)]
    [string]$RepoPath
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

function Read-TextSafe {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return ""
    }

    $value = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop

    if ($null -eq $value) {
        return ""
    }

    return [string]$value
}

if (-not (Test-Path $RepoPath)) {
    throw "Repository not found: $RepoPath"
}

if (-not (Test-Path (Join-Path $RepoPath ".git"))) {
    throw "Path is not a Git repository: $RepoPath"
}

$Findings = @()

Write-Host ""
Write-Host "=== ATINS ZPWC PRECHECK SAFE ==="
Write-Host "Repo: $RepoPath"
Write-Host ""

$branchRaw = git -C $RepoPath branch --show-current 2>$null
$headRaw = git -C $RepoPath rev-parse --short HEAD 2>$null
$tracked = @(git -C $RepoPath ls-tree -r --name-only HEAD)

$branch = if ([string]::IsNullOrWhiteSpace([string]$branchRaw)) {
    "detached HEAD"
}
else {
    [string]$branchRaw
}

if ([string]::IsNullOrWhiteSpace([string]$headRaw)) {
    throw "Cannot determine repository HEAD."
}

$head = [string]$headRaw

Add-Finding "Git" "INFO" "Audited repository state" "branch=$branch; HEAD=$head"

# ------------------------------------------------------------
# REQUIRED FILES
# ------------------------------------------------------------
foreach ($required in @(".env.example", "package.json", "README_AUDIT.md")) {
    if (Test-Path (Join-Path $RepoPath $required)) {
        Add-Finding "Required file" "PASS" "File exists" $required
    }
    else {
        Add-Finding "Required file" "FAIL" "Required file missing" $required
    }
}

# ------------------------------------------------------------
# FORBIDDEN TRACKED FILES
# ------------------------------------------------------------
$forbidden = @(
    $tracked | Where-Object {
        $_ -eq ".env" -or
        $_ -eq ".env.local" -or
        $_ -like "node_modules/*"
    }
)

if ($forbidden.Count -eq 0) {
    Add-Finding "Secrets / tracked files" "PASS" "No forbidden tracked files detected" "Static Git check"
}
else {
    Add-Finding "Secrets / tracked files" "FAIL" "Forbidden tracked files detected" ($forbidden -join ", ")
}

# ------------------------------------------------------------
# CODE INVENTORY
# ------------------------------------------------------------
$codeFiles = @(
    $tracked | Where-Object {
        $_ -match "\.(js|mjs|cjs|ts|jsx|tsx)$"
    }
)

$serverlessFiles = @()
$allCode = ""

foreach ($relative in $codeFiles) {
    $full = Join-Path $RepoPath $relative
    $content = Read-TextSafe -Path $full

    if ([string]::IsNullOrWhiteSpace($content)) {
        continue
    }

    $allCode += "`n" + $content

    $looksLikeServerlessPath =
        $relative -match "(?i)(^|/)(api|functions|serverless)(/|$)"

    $looksLikeServerlessCode =
        $content -match "(?i)export\s+async\s+function\s+(GET|POST|PUT|PATCH|DELETE)\b" -or
        $content -match "(?i)export\s+default\s+async\s+function" -or
        $content -match "(?i)\bResponse\.json\s*\(" -or
        $content -match "(?i)\bNextResponse\.json\s*\("

    if ($looksLikeServerlessPath -or $looksLikeServerlessCode) {
        $serverlessFiles += $relative
    }
}

if ($serverlessFiles.Count -gt 0) {
    Add-Finding "ZPWC serverless" "PASS" "Serverless/function implementation detected" (($serverlessFiles | Select-Object -Unique) -join ", ")
}
else {
    Add-Finding "ZPWC serverless" "FAIL" "Serverless/function implementation not detected" "No function evidence"
}

# ------------------------------------------------------------
# SERVICE-TO-SERVICE
# ------------------------------------------------------------
$hasServiceToService =
    $allCode -match "(?i)\bfetch\s*\(" -or
    $allCode -match "(?i)\baxios\b" -or
    $allCode -match "(?i)\bgenerateText\s*\(" -or
    $allCode -match "(?i)@ai-sdk/" -or
    $allCode -match "(?i)\bhttps?://"

if ($hasServiceToService) {
    Add-Finding "ZPWC service-to-service" "PASS" "Service-to-service integration evidence detected" "Static code inspection"
}
elseif ($serverlessFiles.Count -gt 0) {
    Add-Finding "ZPWC service-to-service" "WARN" "No clear service-to-service integration detected" "Verify manually"
}
else {
    Add-Finding "ZPWC service-to-service" "INFO" "No serverless implementation available for inspection" "No further inference"
}

# ------------------------------------------------------------
# DEPLOYMENT EVIDENCE
# ------------------------------------------------------------
$deploymentEvidence = @()

foreach ($candidate in @(
    "README_AUDIT.md",
    "README.md",
    "vercel.json"
)) {
    $full = Join-Path $RepoPath $candidate

    if (Test-Path $full) {
        $content = Read-TextSafe -Path $full

        if ($content -match "(?i)https://[a-z0-9.-]+\.vercel\.app") {
            $deploymentEvidence += $candidate
        }
    }
}

if ($deploymentEvidence.Count -gt 0) {
    Add-Finding "ZPWC deployment" "PASS" "Deployment URL evidence detected" ($deploymentEvidence -join ", ")
}
else {
    Add-Finding "ZPWC deployment" "WARN" "No deployment URL detected" "Runtime deployment requires verification"
}

# ------------------------------------------------------------
# POSTMAN
# ------------------------------------------------------------
$postmanFiles = @(
    $tracked | Where-Object {
        $_ -match "(?i)postman.*\.json$|.*collection.*\.json$"
    }
)

if ($postmanFiles.Count -gt 0) {
    Add-Finding "ZPWC Postman" "PASS" "Postman evidence detected" ($postmanFiles -join ", ")
}
else {
    Add-Finding "ZPWC Postman" "WARN" "No Postman collection detected" "Required evidence in ZPWC profile"
}

# ------------------------------------------------------------
# OBSERVABILITY
# ------------------------------------------------------------
$hasLogging =
    $allCode -match "(?i)\bconsole\.(log|info|warn|error)\s*\(" -or
    $allCode -match "(?i)\blogger\." -or
    $allCode -match "(?i)\brequestId\b" -or
    $allCode -match "(?i)\bcorrelationId\b"

if ($hasLogging) {
    Add-Finding "ZPWC observability" "PASS" "Logging/diagnostic evidence detected" "Static code inspection"
}
else {
    Add-Finding "ZPWC observability" "WARN" "No clear observability evidence detected" "Verify logs/monitoring manually"
}

# ------------------------------------------------------------
# CI/CD
# ------------------------------------------------------------
$workflowFiles = @(
    $tracked | Where-Object {
        $_ -match "(?i)^\.github/workflows/.+\.ya?ml$"
    }
)

if ($workflowFiles.Count -gt 0) {
    Add-Finding "ZPWC CI/CD" "PASS" "GitHub Actions workflow detected" ($workflowFiles -join ", ")
}
else {
    Add-Finding "ZPWC CI/CD" "WARN" "No GitHub Actions workflow detected" "Verify deployment automation"
}

# ------------------------------------------------------------
# README_AUDIT
# ------------------------------------------------------------
$readmePath = Join-Path $RepoPath "README_AUDIT.md"

if (Test-Path $readmePath) {
    $readme = Read-TextSafe -Path $readmePath

    $auditElements = @(
        "cel",
        "uruchom",
        "test",
        "wynik",
        "ogranic"
    )

    $missingAudit = @(
        $auditElements | Where-Object {
            $readme -notmatch "(?i)$([regex]::Escape($_))"
        }
    )

    if ($missingAudit.Count -eq 0) {
        Add-Finding "README_AUDIT" "PASS" "Expected audit sections detected" "goal/run/test/result/limitations"
    }
    else {
        Add-Finding "README_AUDIT" "WARN" "Audit README may be incomplete" ("Missing evidence: " + ($missingAudit -join ", "))
    }
}

# ------------------------------------------------------------
# TESTS
# ------------------------------------------------------------
$testFiles = @(
    $tracked | Where-Object {
        $_ -match "(?i)(^|/)(tests?|__tests__)(/|$)" -or
        $_ -match "(?i)\.(test|spec)\.(js|ts|mjs|cjs)$"
    }
)

if ($testFiles.Count -gt 0) {
    Add-Finding "Tests" "PASS" "Test files detected" ($testFiles -join ", ")
}
else {
    Add-Finding "Tests" "WARN" "No test files detected" "Verify testing evidence"
}

# ------------------------------------------------------------
# NPM CHECKS
# ------------------------------------------------------------
$packagePath = Join-Path $RepoPath "package.json"

if (Test-Path $packagePath) {
    try {
        $package = (Read-TextSafe -Path $packagePath) | ConvertFrom-Json
        $scriptNames = @()

        if ($null -ne $package.scripts) {
            $scriptNames = @($package.scripts.PSObject.Properties.Name)
        }

        foreach ($expected in @("check:syntax", "typecheck")) {
            if ($scriptNames -notcontains $expected) {
                Add-Finding "npm:$expected" "WARN" "Script not defined" "package.json"
                continue
            }

            $output = @(
                & $(if ($IsWindows) { "npm.cmd" } else { "npm" }) --prefix $RepoPath run $expected 2>&1
            )

            $exitCode = $LASTEXITCODE

            if ($exitCode -eq 0) {
                Add-Finding "npm:$expected" "PASS" "Script completed successfully" "ExitCode=0"
            }
            else {
                Add-Finding "npm:$expected" "FAIL" "Script failed" "ExitCode=$exitCode"
            }
        }
    }
    catch {
        Add-Finding "package.json" "FAIL" "Cannot process package.json" $_.Exception.Message
    }
}

# ------------------------------------------------------------
# SECURITY HEURISTICS
# ------------------------------------------------------------
if ($allCode -match "(?i)console\.(log|info|warn|error)\s*\([^)]*(API_KEY|TOKEN|PASSWORD|DATABASE_URL)") {
    Add-Finding "Security logging" "FAIL" "Possible secret logging detected" "Static heuristic"
}
else {
    Add-Finding "Security logging" "PASS" "No obvious secret logging detected" "Static heuristic"
}

if ($allCode -match "(?i)(postgres(ql)?://|sk-[a-zA-Z0-9]{16,}|Bearer\s+[a-zA-Z0-9._-]{16,})") {
    Add-Finding "Security secrets" "FAIL" "Possible embedded secret detected" "Static heuristic"
}
else {
    Add-Finding "Security secrets" "PASS" "No obvious embedded secret detected" "Static heuristic"
}

# ------------------------------------------------------------
# OUTPUT
# ------------------------------------------------------------
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
Write-Host "- no external service is called"
Write-Host "- deployment is not contacted"
Write-Host "- findings require instructor verification"

$repoName = Split-Path $RepoPath -Leaf
$toolsRoot = Split-Path $PSScriptRoot -Parent
$reportDir = Join-Path (Join-Path $toolsRoot "reports") $repoName

if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$reportPath = Join-Path $reportDir "_ATINS_PRECHECK_ZPWC.txt"

@(
    "ATINS ZPWC PRECHECK SAFE"
    "Repo: $RepoPath"
    "Branch: $branch"
    "HEAD: $head"
    ""
    ($Findings | Format-Table -AutoSize -Wrap | Out-String)
    "PASS: $passCount | WARN: $warnCount | FAIL: $failCount | INFO: $infoCount"
    ""
    "Static technical precheck. Instructor verification required."
) | Set-Content -Path $reportPath -Encoding UTF8

Write-Host ""
Write-Host "Report: $reportPath"