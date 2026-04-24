$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$RootDir = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$SetupScript = Join-Path $RootDir 'setup.ps1'

function Fail {
    param([string]$Message)
    Write-Error "FAIL: $Message"
}

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )
    if (-not $Condition) {
        Fail $Message
    }
}

function Assert-Contains {
    param(
        [string]$Haystack,
        [string]$Needle
    )
    Assert-True ($Haystack.Contains($Needle)) "expected output to contain [$Needle]"
}

function Assert-NotContains {
    param(
        [string]$Haystack,
        [string]$Needle
    )
    Assert-True (-not $Haystack.Contains($Needle)) "expected output not to contain [$Needle]"
}

. $SetupScript

$manifest = Get-WindowsPackageManifest -RootDir $RootDir
$packageIds = @($manifest.packages | ForEach-Object { $_.id })
$expectedIds = @(
    'Microsoft.WindowsTerminal.Preview',
    'Starship.Starship',
    'Microsoft.PowerShell',
    'eza-community.eza',
    'astral-sh.uv',
    'Schniz.fnm',
    'sharkdp.fd',
    'Git.Git',
    'junegunn.fzf',
    'ajeetdsouza.zoxide',
    'FxSound.FxSound'
)

foreach ($id in $expectedIds) {
    Assert-True ($packageIds -contains $id) "expected package manifest to include [$id]"
}

$newProfileTemplate = Join-Path $RootDir 'configs/windows/Microsoft.PowerShell_profile.ps1'
$oldProfileTemplate = Join-Path $RootDir 'configs/windows/profile.ps1'
Assert-True (Test-Path -LiteralPath $newProfileTemplate) 'expected PowerShell profile template to use Microsoft.PowerShell_profile.ps1'
Assert-True (-not (Test-Path -LiteralPath $oldProfileTemplate)) 'expected old configs/windows/profile.ps1 to be removed'

$profileContent = Get-PowerShellProfileContent -RootDir $RootDir
Assert-Contains $profileContent 'starship init powershell'
Assert-Contains $profileContent 'fnm env --use-on-cd --shell powershell'
Assert-Contains $profileContent 'zoxide init powershell'
Assert-Contains $profileContent 'fzf --pwsh'
Assert-Contains $profileContent 'function ll'
Assert-Contains $profileContent 'function lt'
Assert-Contains $profileContent 'function cd'

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "terminal-setup-test-$([guid]::NewGuid())"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
try {
    $profilePath = Join-Path $tempDir 'profile.ps1'
    Set-Content -LiteralPath $profilePath -Value 'Write-Output "old profile"' -Encoding UTF8
    Deploy-PowerShellProfile -RootDir $RootDir -ProfilePath $profilePath
    $deployedContent = Get-Content -LiteralPath $profilePath -Raw
    Assert-Contains $deployedContent 'starship init powershell'
    Assert-NotContains $deployedContent 'old profile'
    Assert-True (-not (Get-ChildItem -LiteralPath $tempDir -Filter 'profile.ps1.bak.*')) 'expected existing profile to be replaced without backup'

    $missingProfilePath = Join-Path $tempDir 'missing-profile.ps1'
    Deploy-PowerShellProfile -RootDir $RootDir -ProfilePath $missingProfilePath
    Assert-True (Test-Path -LiteralPath $missingProfilePath) 'expected missing profile to be created by copying template'
    Assert-Contains (Get-Content -LiteralPath $missingProfilePath -Raw) 'starship init powershell'
} finally {
    Remove-Item -LiteralPath $tempDir -Recurse -Force
}

$script:CapturedCommands = @()
Invoke-SetupCommand -FilePath 'winget' -ArgumentList @('install', '--id', 'Starship.Starship') -DryRun -CommandSink {
    param([string]$CommandLine)
    $script:CapturedCommands += $CommandLine
}
Assert-True ($script:CapturedCommands.Count -eq 1) 'expected dry-run command to be captured once'
Assert-Contains $script:CapturedCommands[0] 'winget install --id Starship.Starship'

Write-Output 'PASS: windows setup'
