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

function Copy-AddonRuntimeFiles {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,
        [Parameter(Mandatory = $true)]
        [string]$Target,
        [Parameter(Mandatory = $true)]
        [string]$TocName,
        [string[]]$AdditionalPaths = @()
    )

    New-Item -ItemType Directory -Path $Target -Force | Out-Null

    $tocSource = Join-Path $Source $TocName
    if (-not (Test-Path -LiteralPath $tocSource -PathType Leaf)) {
        throw "Required addon manifest is missing: $tocSource"
    }

    $runtimePaths = @($TocName)
    $runtimePaths += Get-Content -LiteralPath $tocSource |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith("#") }
    $runtimePaths += $AdditionalPaths

    foreach ($relativePath in ($runtimePaths | Select-Object -Unique)) {
        $sourcePath = Join-Path $Source $relativePath
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            throw "Runtime file listed for release is missing: $sourcePath"
        }

        $targetPath = Join-Path $Target $relativePath
        $targetParent = Split-Path $targetPath -Parent
        New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
        Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Recurse -Force
    }
}

Copy-AddonRuntimeFiles `
    -Source $mainSource `
    -Target $mainTarget `
    -TocName "CoAAnalytics.toc" `
    -AdditionalPaths @("Textures")
Copy-AddonRuntimeFiles `
    -Source $dataProbeSource `
    -Target $dataProbeTarget `
    -TocName "CoAAnalytics_DataProbe.toc"
Compress-Archive -Path (Join-Path $stagingRoot "*") -DestinationPath $archivePath -CompressionLevel Optimal
Remove-Item -LiteralPath $stagingRoot -Recurse -Force

Write-Output "Created CoAAnalytics $version release package: $archivePath"
Write-Output "Included addons: CoAAnalytics, CoAAnalytics_DataProbe"
