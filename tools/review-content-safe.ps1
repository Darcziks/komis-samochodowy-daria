param(
    [Parameter(Mandatory = $true)]
    [string]$RepoPath,

    [Parameter(Mandatory = $false)]
    [string]$Milestone = "M1"
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

    $value = Get-Content -Path $Path -Raw -ErrorAction Stop

    if ($null -eq $value) {
        return ""
    }

    return [string]$value
}

if (-not (Test-Path $RepoPath)) {
    throw "Nie znaleziono repo: $RepoPath"
}

if (-not (Test-Path (Join-Path $RepoPath ".git"))) {
    throw "Podana ścieżka nie jest repozytorium Git: $RepoPath"
}

$Findings = @()

Write-Host ""
Write-Host "=== ATINS Content Review SAFE ==="
Write-Host "Repo:      $RepoPath"
Write-Host "Milestone: $Milestone"
Write-Host ""

$branchRaw = git -C $RepoPath branch --show-current 2>$null
$headRaw = git -C $RepoPath rev-parse --short HEAD 2>$null

if ($null -eq $branchRaw) {
    $branch = "detached HEAD"
}
else {
    $branch = [string]$branchRaw
}

if ($null -eq $headRaw) {
    throw "Nie udało się ustalić HEAD repozytorium."
}
else {
    $head = [string]$headRaw
}
$tracked = @(git -C $RepoPath ls-tree -r --name-only HEAD)

Add-Finding "Git" "INFO" "Audytowany stan repo" "branch=$branch; HEAD=$head"

# ------------------------------------------------------------
# DATABASE SQL
# ------------------------------------------------------------
$sqlFiles = @(
    $tracked | Where-Object {
        $_ -like "database/*.sql" -or $_ -like "database/*/*.sql"
    }
)

if ($sqlFiles.Count -eq 0) {
    Add-Finding "database/" "FAIL" "Brak plików SQL" "Nie znaleziono database/*.sql"
}
else {
    Add-Finding "database/" "PASS" "Znaleziono pliki SQL" ($sqlFiles -join ", ")

    $combinedSql = ""

    foreach ($relative in $sqlFiles) {
        $full = Join-Path $RepoPath $relative
        $sqlPart = Read-TextSafe -Path $full
        $combinedSql += "`n" + $sqlPart

        if ([string]::IsNullOrWhiteSpace($sqlPart)) {
            Add-Finding "database/" "WARN" "Pusty plik SQL" $relative
        }
    }

    if ($combinedSql -match "(?i)\bCREATE\s+TABLE\b") {
        Add-Finding "database/" "PASS" "Wykryto definicję tabeli" "CREATE TABLE"
    }
    else {
        Add-Finding "database/" "WARN" "Nie wykryto CREATE TABLE" "Wymaga ręcznego oglądu"
    }

    if ($combinedSql -match "(?i)\bPRIMARY\s+KEY\b") {
        Add-Finding "database/" "PASS" "Wykryto klucz główny" "PRIMARY KEY"
    }
    else {
        Add-Finding "database/" "WARN" "Nie wykryto PRIMARY KEY" "Wymaga ręcznego oglądu"
    }

    if ($combinedSql -match "(?i)\bFOREIGN\s+KEY\b|\bREFERENCES\b") {
        Add-Finding "database/" "PASS" "Wykryto relację" "FOREIGN KEY / REFERENCES"
    }
    else {
        Add-Finding "database/" "WARN" "Nie wykryto relacji" "Wymaga ręcznego oglądu"
    }

    if ($combinedSql -match "(?i)\bCHECK\s*\(") {
        Add-Finding "database/" "INFO" "Wykryto CHECK" "CHECK(...)"
    }

    if ($combinedSql -match "(?i)\bUNIQUE\b") {
        Add-Finding "database/" "INFO" "Wykryto UNIQUE" "UNIQUE"
    }
}

# ------------------------------------------------------------
# PACKAGE.JSON
# ------------------------------------------------------------
$packagePath = Join-Path $RepoPath "package.json"

if (-not (Test-Path $packagePath)) {
    Add-Finding "package.json" "FAIL" "Brak package.json" "Nie można sprawdzić konfiguracji npm"
}
else {
    try {
        $packageRaw = Read-TextSafe -Path $packagePath

        if ([string]::IsNullOrWhiteSpace($packageRaw)) {
            throw "package.json jest pusty"
        }

        $package = $packageRaw | ConvertFrom-Json
        Add-Finding "package.json" "PASS" "Poprawny JSON" "package.json można odczytać"

        $scriptNames = @()

        if ($null -ne $package.scripts) {
            $scriptNames = @($package.scripts.PSObject.Properties.Name)
        }

        if ($scriptNames.Count -gt 0) {
            Add-Finding "package.json scripts" "INFO" "Zdefiniowane skrypty npm" ($scriptNames -join ", ")
        }
        else {
            Add-Finding "package.json scripts" "WARN" "Brak scripts" "Sprawdź wymagania M1"
        }

       foreach ($expected in @("check:syntax", "typecheck")) {

    if ($scriptNames -notcontains $expected) {
        Add-Finding "npm:$expected" "WARN" "Skrypt nie istnieje" "Sprawdź wymagania M1"
        continue
    }

    $output = @(
        & npm.cmd --prefix $RepoPath run $expected 2>&1
    )

    $exitCode = $LASTEXITCODE
    $outputText = ($output | ForEach-Object { [string]$_ }) -join "`n"

    if ($exitCode -eq 0) {
        Add-Finding "npm:$expected" "PASS" "Skrypt wykonany poprawnie" "ExitCode=0"
    }
    else {
        Add-Finding "npm:$expected" "FAIL" "Skrypt zakończył się błędem" "ExitCode=$exitCode`n$outputText"
    }
}

if ($scriptNames -contains "check-db") {
    Add-Finding "npm:check-db" "PASS" "Skrypt istnieje" "Nie uruchamiano bez sekretów Studenta"
}
else {
    Add-Finding "npm:check-db" "WARN" "Skrypt nie istnieje" "Sprawdź wymagania M1"
}
}
    catch {
        Add-Finding "package.json" "FAIL" "Niepoprawny package.json" $_.Exception.Message
    }
}

# ------------------------------------------------------------
# STATIC DB CONNECTION REVIEW
# ------------------------------------------------------------
$dbCandidates = @(
    $tracked | Where-Object {
        ($_ -match "\.(js|mjs|cjs|ts|jsx|tsx)$") -and
        (
            $_.StartsWith("src/") -or
            $_.StartsWith("scripts/") -or
            $_.StartsWith("tests/")
        )
    }
)

$dbContent = ""
$dbFiles = @()

foreach ($relative in $dbCandidates) {
    $full = Join-Path $RepoPath $relative
    $content = Read-TextSafe -Path $full

    if (
        $content -match "DATABASE_URL" -or
        $content -match "(?i)\bnew\s+(Pool|Client)\s*\(" -or
        $content -match "(?i)\bfrom\s+['""]pg['""]" -or
        $content -match "(?i)\brequire\(['""]pg['""]\)"
    ) {
        $dbContent += "`n" + $content
        $dbFiles += $relative
    }
}

if ($dbFiles.Count -eq 0) {
    Add-Finding "DB connection" "WARN" "Nie znaleziono kodu połączenia z bazą" "Szukano DATABASE_URL / pg / Pool / Client"
}
else {
    Add-Finding "DB connection" "PASS" "Znaleziono kod połączenia" ($dbFiles -join ", ")

    if ($dbContent -match "process\.env\.DATABASE_URL") {
        Add-Finding "DB config" "PASS" "Konfiguracja korzysta z DATABASE_URL" "process.env.DATABASE_URL"
    }
    else {
        Add-Finding "DB config" "WARN" "Nie wykryto process.env.DATABASE_URL" "Sprawdź sposób konfiguracji"
    }

    if ($dbContent -match "(?i)\bnew\s+(pg\.)?Pool\s*\(" -or $dbContent -match "(?i)\bnew\s+(pg\.)?Client\s*\(") {
        Add-Finding "DB client" "PASS" "Wykryto klienta PostgreSQL" (($dbFiles | Select-Object -Unique) -join ", ")
    }
    else {
        Add-Finding "DB client" "WARN" "Nie wykryto new Pool/new Client" (($dbFiles | Select-Object -Unique) -join ", ")
    }

    if ($dbContent -match "(?i)\bfrom\s+['""]pg['""]" -or $dbContent -match "(?i)\brequire\(['""]pg['""]\)") {
        Add-Finding "DB library" "PASS" "Wykryto bibliotekę pg" "import/require pg"
    }
    else {
        Add-Finding "DB library" "INFO" "Nie wykryto bezpośredniego importu pg" "Możliwa inna biblioteka"
    }

    if ($dbContent -match "(?i)postgres(ql)?://[^'""\s]+") {
        Add-Finding "DB security" "FAIL" "Wykryto connection string w kodzie" "Wymaga ręcznej kontroli plików DB"
    }
    else {
        Add-Finding "DB security" "PASS" "Nie wykryto connection stringa w kodzie" "Kontrola heurystyczna"
    }

    if ($dbContent -match "(?i)(password|passwd)\s*[:=]\s*['""][^'""]+['""]") {
        Add-Finding "DB security" "WARN" "Wykryto możliwe hasło w kodzie" "Wymaga ręcznej weryfikacji"
    }
    else {
        Add-Finding "DB security" "PASS" "Nie wykryto oczywistego hasła" "Kontrola heurystyczna"
    }

    $hasDirectDbValidation =
    $dbContent -match "(?i)DATABASE_URL_REQUIRED|if\s*\(\s*!process\.env\.DATABASE_URL\s*\)"

	$hasAssignedDbValidation =
		$dbContent -match "(?is)(const|let|var)\s+connectionString\s*=\s*process\.env\.DATABASE_URL.*?if\s*\(\s*!connectionString\s*\)"

	if ($hasDirectDbValidation -or $hasAssignedDbValidation) {
		Add-Finding "DB validation" "PASS" "Wykryto obsługę braku DATABASE_URL" "Walidacja konfiguracji"
	}
	else {
		Add-Finding "DB validation" "WARN" "Nie wykryto jawnej obsługi braku DATABASE_URL" "Sprawdź ręcznie"
	}
}

# ------------------------------------------------------------
# SCRIPTS / SRC
# ------------------------------------------------------------
foreach ($area in @("scripts","src")) {
    $files = @($tracked | Where-Object { $_.StartsWith("$area/") })

    if ($files.Count -eq 0) {
        Add-Finding "$area/" "FAIL" "Brak plików" "$area/ jest pusty w Git"
        continue
    }

    Add-Finding "$area/" "PASS" "Znaleziono pliki" "$($files.Count) plik(ów)"

    foreach ($relative in $files) {
        if ($relative -notmatch "\.(js|mjs|cjs|ts|jsx|tsx)$") {
            continue
        }

        $content = Read-TextSafe -Path (Join-Path $RepoPath $relative)

        if ([string]::IsNullOrWhiteSpace($content)) {
            Add-Finding "$area/" "WARN" "Pusty plik kodu" $relative
            continue
        }

        $contentText = ($content | Out-String)

        if ($contentText -match "(?i)\bTODO\b|\bFIXME\b|\bPLACEHOLDER\b") {
            Add-Finding "$area/" "WARN" "Możliwy placeholder/TODO" $relative
        }
    }
}

# ------------------------------------------------------------
# TESTS
# ------------------------------------------------------------
$testFiles = @($tracked | Where-Object { $_.StartsWith("tests/") -and ([System.IO.Path]::GetFileName($_) -ne ".gitkeep") })

if ($testFiles.Count -eq 0) {
    Add-Finding "tests/" "FAIL" "Brak testów" "tests/ nie zawiera śledzonych plików"
}
else {
    Add-Finding "tests/" "PASS" "Znaleziono pliki testowe" ($testFiles -join ", ")

    $testConstructs = 0
    $assertConstructs = 0

    foreach ($relative in $testFiles) {
        $full = Join-Path $RepoPath $relative
        $content = Read-TextSafe -Path $full

        if ([string]::IsNullOrWhiteSpace($content)) {
            Add-Finding "tests/" "WARN" "Pusty plik testowy" $relative
            continue
        }

        $contentText = ($content | Out-String)

        $testConstructs += (
            [regex]::Matches(
                $contentText,
                "(?m)\b(test|it|describe)\s*\("
            )
        ).Count

        $assertConstructs += (
            [regex]::Matches(
                $contentText,
                "(?m)(?<![\w`$])expect\s*\("
            )
        ).Count
    }

    if ($testConstructs -gt 0) {
        Add-Finding "tests/" "PASS" "Wykryto konstrukcje testowe" "test/it/describe: $testConstructs"
    }
    else {
        Add-Finding "tests/" "WARN" "Nie wykryto standardowych konstrukcji testowych" ($testFiles -join ", ")
    }

    $allTestContent = @(
    $testFiles | ForEach-Object {
        $testPath = Join-Path $RepoPath $_
        Get-Content -LiteralPath $testPath -Raw -ErrorAction SilentlyContinue
    }
		) -join "`n"

		$hasAssertion =
			$allTestContent -match '(?i)\bexpect\s*\(' -or
			$allTestContent -match '(?i)\bassert\s*\(' -or
			$allTestContent -match '(?i)\bassert\.(equal|strictEqual|deepEqual|deepStrictEqual|throws|rejects|ok|match|doesNotThrow)\s*\('

		if ($hasAssertion) {
			Add-Finding "tests/" "PASS" "Wykryto asercję" "expect/assert"
		}
		else {
			Add-Finding "tests/" "WARN" "Nie wykryto jednoznacznej asercji" ($testFiles -join ", ")
		}
}

# ------------------------------------------------------------
# ENV
# ------------------------------------------------------------
$envPath = Join-Path $RepoPath ".env.example"

if (Test-Path $envPath) {
    $envText = Read-TextSafe -Path $envPath
    $envLines = @($envText -split "`r?`n")

    $names = @(
        $envLines |
        Where-Object { $_ -match "^\s*[A-Za-z_][A-Za-z0-9_]*\s*=" } |
        ForEach-Object { ($_ -split "=",2)[0].Trim() }
    )

    Add-Finding ".env.example" "INFO" "Zmienne środowiskowe" ($names -join ", ")

    if ($names -contains "DATABASE_URL") {
        Add-Finding ".env.example" "PASS" "DATABASE_URL zadeklarowane" "Bez odczytywania sekretów Studenta"
    }
    else {
        Add-Finding ".env.example" "WARN" "Brak DATABASE_URL" "Sprawdź wymagania M1"
    }
}
else {
    Add-Finding ".env.example" "WARN" "Brak .env.example" "Sprawdź wymagania M1"
}

# ------------------------------------------------------------
# M2 API PRECHECK
# ------------------------------------------------------------
if ($Milestone -eq "M2") {

    $codeFiles = @(
        $tracked | Where-Object {
            $_ -match "\.(js|mjs|cjs|ts|jsx|tsx)$"
        }
    )

    $apiFiles = @()
    $apiContent = ""

    foreach ($relative in $codeFiles) {
        $full = Join-Path $RepoPath $relative
        $contentM2 = Read-TextSafe -Path $full

        if ([string]::IsNullOrWhiteSpace($contentM2)) {
            continue
        }

        $looksLikeApiPath =
            $relative -match "(?i)(^|/)(api|routes|server)(/|$)" -or
            $relative -match "(?i)(route|router|server|api)\.(js|ts|mjs|cjs)$"

        $looksLikeApiCode =
            $contentM2 -match "(?i)\bapp\.(get|post|put|patch|delete)\s*\(" -or
            $contentM2 -match "(?i)\brouter\.(get|post|put|patch|delete)\s*\(" -or
            $contentM2 -match "(?i)export\s+async\s+function\s+(GET|POST|PUT|PATCH|DELETE)\b" -or
            $contentM2 -match "(?i)\bResponse\.json\s*\(" -or
            $contentM2 -match "(?i)\bNextResponse\.json\s*\("

        if ($looksLikeApiPath -or $looksLikeApiCode) {
            $apiFiles += $relative
            $apiContent += "`n" + $contentM2
        }
    }

    # API implementation
    if ($apiFiles.Count -gt 0) {
        Add-Finding "M2 API implementation" "PASS" "Wykryto pliki warstwy API" (($apiFiles | Select-Object -Unique) -join ", ")
    }
    else {
        Add-Finding "M2 API implementation" "FAIL" "Nie wykryto warstwy API" "Brak plikow lub konstrukcji charakterystycznych dla HTTP API"
    }

    # /health
    if ($apiContent -match "(?i)['""]\/health['""]") {
        Add-Finding "M2 API /health" "PASS" "Wykryto endpoint /health" "Kontrola statyczna kodu API"
    }
    else {
        Add-Finding "M2 API /health" "FAIL" "Nie wykryto endpointu /health" "Sprawdz implementacje API"
    }

    # /api/cars
    if ($apiContent -match "(?i)['""]\/api\/cars['""]") {
        Add-Finding "M2 API /api/cars" "PASS" "Wykryto endpoint /api/cars" "Kontrola statyczna kodu API"
    }
    else {
        Add-Finding "M2 API /api/cars" "FAIL" "Nie wykryto endpointu /api/cars" "Sprawdz implementacje API"
    }

    # JSON
    if (
        $apiContent -match "(?i)\.json\s*\(" -or
        $apiContent -match "(?i)Response\.json\s*\(" -or
        $apiContent -match "(?i)NextResponse\.json\s*\("
    ) {
        Add-Finding "M2 API JSON" "PASS" "Wykryto odpowiedz JSON" "Kontrola statyczna kodu API"
    }
    elseif ($apiFiles.Count -gt 0) {
        Add-Finding "M2 API JSON" "WARN" "Nie wykryto jednoznacznej odpowiedzi JSON" "Wymaga recznej kontroli"
    }
    else {
        Add-Finding "M2 API JSON" "INFO" "Brak warstwy API do kontroli JSON" "Nie wykonano dalszego wnioskowania"
    }

    # API -> DB
    if ($apiFiles.Count -eq 0) {
        Add-Finding "M2 API -> DB" "INFO" "Brak warstwy API do kontroli integracji DB" "Nie utozsamiano narzedzi DB z API"
    }
    elseif (
        $apiContent -match "(?i)\.query\s*\(" -or
        $apiContent -match "(?is)\bSELECT\b.+?\bFROM\b" -or
        $apiContent -match "process\.env\.DATABASE_URL"
    ) {
        Add-Finding "M2 API -> DB" "PASS" "Wykryto integracje API z baza danych" "Kontrola heurystyczna ograniczona do kodu API"
    }
    else {
        Add-Finding "M2 API -> DB" "WARN" "Nie wykryto integracji API z baza danych" "Sprawdz implementacje endpointu"
    }

    # Images
    if ($apiContent -match "(?i)\bimage_key\b|\bimageUrl\b|\bimage_url\b") {
        Add-Finding "M2 images" "PASS" "Wykryto obsluge referencji obrazu" "image_key / imageUrl / image_url"
    }
    elseif ($apiFiles.Count -gt 0) {
        Add-Finding "M2 images" "WARN" "Nie wykryto image_key ani imageUrl" "Sprawdz czesc Object Storage"
    }
    else {
        Add-Finding "M2 images" "INFO" "Brak API do kontroli obslugi obrazow" "Nie wykonano dalszego wnioskowania"
    }

    # Security - logging
    if ($apiFiles.Count -eq 0) {
        Add-Finding "M2 security logging" "INFO" "Brak kodu API do kontroli logowania sekretow" "Nie wykonano dalszego wnioskowania"
    }
    elseif ($apiContent -match "(?i)console\.log\s*\([^)]*DATABASE_URL") {
        Add-Finding "M2 security logging" "FAIL" "Mozliwy wyciek DATABASE_URL przez logowanie" "console.log(...DATABASE_URL...)"
    }
    else {
        Add-Finding "M2 security logging" "PASS" "Nie wykryto logowania DATABASE_URL w kodzie API" "Kontrola heurystyczna"
    }

    # Security - secrets
    if ($apiFiles.Count -eq 0) {
        Add-Finding "M2 security secrets" "INFO" "Brak kodu API do kontroli connection stringa" "Nie wykonano dalszego wnioskowania"
    }
    elseif ($apiContent -match "(?i)postgres(ql)?://[^'""\s]+") {
        Add-Finding "M2 security secrets" "FAIL" "Wykryto connection string PostgreSQL w kodzie API" "Usun sekret z repo"
    }
    else {
        Add-Finding "M2 security secrets" "PASS" "Nie wykryto jawnego connection stringa PostgreSQL w API" "Kontrola heurystyczna"
    }

    Add-Finding "M2 precheck" "INFO" "Statyczny precheck M2 zakonczony" "Runtime API jest sprawdzany osobnym etapem"
}

# ------------------------------------------------------------# ------------------------------------------------------------
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
Write-Host "ZASADA:"
Write-Host "- brak połączenia z bazą Studenta"
Write-Host "- brak użycia DATABASE_URL Studenta"
Write-Host "- brak npm run check-db"
Write-Host "- audyt DB wyłącznie statyczny"
Write-Host ""
Write-Host "Raport wspiera prowadzącego; nie stanowi finalnej oceny."

$repoName = Split-Path $RepoPath -Leaf
$reviewsRoot = Split-Path $PSScriptRoot -Parent
$reportDir = Join-Path $reviewsRoot ("reports\" + $repoName)

if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$reportPath = Join-Path $reportDir "_ATINS_CONTENT_REVIEW_$Milestone.txt"

@(
    "ATINS Content Review SAFE"
    "Repo: $RepoPath"
    "Milestone: $Milestone"
    "Branch: $branch"
    "HEAD: $head"
    ""
    ($Findings | Format-Table -AutoSize -Wrap | Out-String)
    "PASS: $passCount | WARN: $warnCount | FAIL: $failCount | INFO: $infoCount"
    ""
    "Audyt DB był wyłącznie statyczny."
    "Raport wspiera prowadzącego; nie stanowi finalnej oceny."
) | Set-Content -Path $reportPath -Encoding UTF8

Write-Host "Raport: $reportPath"

