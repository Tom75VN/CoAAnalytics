param(
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "release")
)

$ErrorActionPreference = "Stop"

$mainSource = $PSScriptRoot
$dataProbeSource = Join-Path (Split-Path $PSScriptRoot -Parent) "CoAAnalytics_DataProbe"
$tocPath = Join-Path $mainSource "CoAAnalytics.toc"

if (-not (Test-Path -LiteralPath $dataProbeSource -PathType Container)) {
    throw "CoAAnalytics_DataProbe is required for every release package."
}

$versionLine = Select-String -LiteralPath $tocPath -Pattern '^## Version:\s*(.+)$'
if (-not $versionLine) {
    throw "The addon version could not be read from CoAAnalytics.toc."
}
$version = $versionLine.Matches[0].Groups[1].Value.Trim()

$stagingRoot = Join-Path $OutputDirectory "staging"
$mainTarget = Join-Path $stagingRoot "CoAAnalytics"
$dataProbeTarget = Join-Path $stagingRoot "CoAAnalytics_DataProbe"
$archivePath = Join-Path $OutputDirectory "CoAAnalytics.zip"

if (Test-Path -LiteralPath $stagingRoot) {
    Remove-Item -LiteralPath $stagingRoot -Recurse -Force
}
if (Test-Path -LiteralPath $archivePath) {
    Remove-Item -LiteralPath $archivePath -Force
}

New-Item -ItemType Directory -Path $mainTarget -Force | Out-Null

$excludedNames = @(
    ".git",
    ".github",
    ".gitignore",
    "AGENTS.md",
    "Package-Release.ps1",
    "RELEASING.md",
    "release"
)

Get-ChildItem -LiteralPath $mainSource -Force |
    Where-Object { $_.Name -notin $excludedNames } |
    ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $mainTarget -Recurse -Force
    }

Copy-Item -LiteralPath $dataProbeSource -Destination $dataProbeTarget -Recurse -Force
Compress-Archive -Path (Join-Path $stagingRoot "*") -DestinationPath $archivePath -CompressionLevel Optimal
Remove-Item -LiteralPath $stagingRoot -Recurse -Force

Write-Output "Created CoAAnalytics $version release package: $archivePath"
Write-Output "Included addons: CoAAnalytics, CoAAnalytics_DataProbe"
