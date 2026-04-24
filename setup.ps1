[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$SkipPackages,
    [switch]$SkipProfile
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Resolve-SetupRoot {
    if ($PSScriptRoot) {
        return $PSScriptRoot
    }

    return (Get-Location).Path
}

function Test-CommandExists {
    param([Parameter(Mandatory)][string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Join-CommandLine {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [string[]]$ArgumentList = @()
    )

    return (@($FilePath) + $ArgumentList) -join ' '
}

function Invoke-SetupCommand {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [string[]]$ArgumentList = @(),
        [switch]$DryRun,
        [scriptblock]$CommandSink
    )

    $commandLine = Join-CommandLine -FilePath $FilePath -ArgumentList $ArgumentList

    if ($DryRun) {
        if ($CommandSink) {
            & $CommandSink $commandLine
        } else {
            Write-Host "[DRY-RUN] $commandLine" -ForegroundColor Yellow
        }
        return
    }

    & $FilePath @ArgumentList
}

function Get-WindowsPackageManifest {
    param([string]$RootDir = (Resolve-SetupRoot))

    $manifestPath = Join-Path $RootDir 'configs/windows/packages.json'
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        throw "Package manifest not found: $manifestPath"
    }

    return Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
}

function Test-WingetPackageInstalled {
    param([Parameter(Mandatory)][string]$Id)

    & winget list --id $Id --exact --source winget *> $null
    return $LASTEXITCODE -eq 0
}

function Install-WingetPackages {
    param(
        [Parameter(Mandatory)]$Manifest,
        [switch]$DryRun
    )

    if (-not (Test-CommandExists 'winget')) {
        throw 'winget is required. Install App Installer from Microsoft Store first.'
    }

    foreach ($package in $Manifest.packages) {
        $id = [string]$package.id
        $name = [string]$package.name

        if (-not $DryRun -and (Test-WingetPackageInstalled -Id $id)) {
            Write-Ok "$name already installed"
            continue
        }

        Write-Info "Installing $name ($id)"
        Invoke-SetupCommand `
            -FilePath 'winget' `
            -ArgumentList @(
                'install',
                '--id', $id,
                '--exact',
                '--source', 'winget',
                '--accept-package-agreements',
                '--accept-source-agreements'
            ) `
            -DryRun:$DryRun
    }
}

function Deploy-StarshipConfig {
    param(
        [string]$RootDir = (Resolve-SetupRoot),
        [switch]$DryRun
    )

    $source = Join-Path $RootDir 'configs/starship.toml'
    $targetDir = Join-Path $HOME '.config'
    $target = Join-Path $targetDir 'starship.toml'

    if (-not (Test-Path -LiteralPath $source)) {
        throw "Starship config not found: $source"
    }

    if ($DryRun) {
        Write-Host "[DRY-RUN] New-Item -ItemType Directory -Force $targetDir" -ForegroundColor Yellow
        Write-Host "[DRY-RUN] Copy-Item $source $target" -ForegroundColor Yellow
        return
    }

    New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    if (Test-Path -LiteralPath $target) {
        $backup = "$target.bak.$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
        Copy-Item -LiteralPath $target -Destination $backup
        Write-Warn "Backed up existing starship.toml to $backup"
    }

    Copy-Item -LiteralPath $source -Destination $target
    Write-Ok "Starship config deployed to $target"
}

function Get-PowerShellProfileTemplatePath {
    param([string]$RootDir = (Resolve-SetupRoot))

    $templatePath = Join-Path $RootDir 'configs/windows/Microsoft.PowerShell_profile.ps1'
    if (-not (Test-Path -LiteralPath $templatePath)) {
        throw "PowerShell profile template not found: $templatePath"
    }

    return $templatePath
}

function Get-PowerShellProfileContent {
    param([string]$RootDir = (Resolve-SetupRoot))

    $templatePath = Get-PowerShellProfileTemplatePath -RootDir $RootDir
    return Get-Content -LiteralPath $templatePath -Raw
}

function Deploy-PowerShellProfile {
    param(
        [string]$RootDir = (Resolve-SetupRoot),
        [string]$ProfilePath = $PROFILE,
        [switch]$DryRun
    )

    $profileDir = Split-Path -Parent $ProfilePath
    $templatePath = Get-PowerShellProfileTemplatePath -RootDir $RootDir

    Write-Info "profileDir: $profileDir"
    Write-Info "ProfilePath: $ProfilePath"

    if ($DryRun) {
        Write-Host "[DRY-RUN] New-Item -ItemType Directory -Force $profileDir" -ForegroundColor Yellow
        Write-Host "[DRY-RUN] Copy-Item -Force $templatePath $ProfilePath" -ForegroundColor Yellow
        return
    }

    New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
    Copy-Item -LiteralPath $templatePath -Destination $ProfilePath -Force
    Write-Ok "PowerShell Profile replaced at $ProfilePath"
}

function Invoke-WindowsSetup {
    param(
        [switch]$DryRun,
        [switch]$SkipPackages,
        [switch]$SkipProfile
    )

    $rootDir = Resolve-SetupRoot

    Write-Host ''
    if ($DryRun) {
        Write-Host '  DRY-RUN MODE - no changes will be made' -ForegroundColor Yellow
        Write-Host ''
    }

    if (-not $IsWindows) {
        throw 'setup.ps1 supports native Windows only.'
    }

    Write-Info 'Step 1/5: Prerequisites'
    if (-not (Test-CommandExists 'winget') -and -not $SkipPackages) {
        throw 'winget is required. Install App Installer from Microsoft Store first.'
    }
    Write-Ok 'Prerequisites ready'

    if (-not $SkipPackages) {
        Write-Info 'Step 2/5: Packages'
        $manifest = Get-WindowsPackageManifest -RootDir $rootDir
        Install-WingetPackages -Manifest $manifest -DryRun:$DryRun
    } else {
        Write-Warn 'Skipping package installation'
    }

    Write-Info 'Step 3/5: Starship'
    Deploy-StarshipConfig -RootDir $rootDir -DryRun:$DryRun

    if (-not $SkipProfile) {
        Write-Info 'Step 4/5: PowerShell Profile'
        Deploy-PowerShellProfile -RootDir $rootDir -DryRun:$DryRun
    } else {
        Write-Warn 'Skipping PowerShell Profile update'
    }

    Write-Info 'Step 5/5: Summary'
    Write-Host "  Profile: $($PROFILE)"
    Write-Host '  Restart PowerShell or Windows Terminal after setup completes.'
    Write-Ok 'Windows setup complete'
}

if ($MyInvocation.InvocationName -ne '.') {
    Invoke-WindowsSetup -DryRun:$DryRun -SkipPackages:$SkipPackages -SkipProfile:$SkipProfile
}
