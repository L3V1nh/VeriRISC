# ============================================================
#  vivado_sim.ps1  -  Xilinx Vivado Compile / Elaborate / Simulate
#  Usage:
#    .\vivado_sim.ps1 -Module control
#    .\vivado_sim.ps1 -Module control -UsePackage
#    .\vivado_sim.ps1 -Module control -UsePackage -VivadoPath "C:\Xilinx\Vivado\2024.2"
# ============================================================

param (
    [Parameter(Mandatory = $true, HelpMessage = "Base module name, e.g. 'control'")]
    [string]$Module,

    [Parameter(HelpMessage = "Include a _pkg.sv package file for this module")]
    [switch]$UsePackage,

    [Parameter(HelpMessage = "Path to the Vivado installation root")]
    [string]$VivadoPath = "C:\Xilinx\Vivado\2024.2",

    [Parameter(HelpMessage = "Path to the RTL source directory")]
    [string]$RtlDir = "..\rtl",

    [Parameter(HelpMessage = "Path to the testbench directory")]
    [string]$TbDir = "..\tb",

    [Parameter(HelpMessage = "Timescale passed to xelab (default: 1ns/1ps)")]
    [string]$Timescale = "1ns/100ps"
)

# -- Project paths -------------------------------------------
$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$BuildDir    = Join-Path $ProjectRoot "build"

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

function Get-AbsolutePath([string]$Path) {
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $ScriptDir $Path))
}

# -- Derived names -------------------------------------------
$TopName      = "${Module}_test"
$SnapshotName = "${Module}_sim"
$PkgFile      = Join-Path (Get-AbsolutePath $RtlDir) "${Module}_pkg.sv"
$RtlFile      = Join-Path (Get-AbsolutePath $RtlDir) "${Module}.sv"
$TbFile       = Join-Path (Get-AbsolutePath $TbDir)  "${Module}_tb.sv"

# -- Tool paths ----------------------------------------------
$BinDir = Join-Path $VivadoPath "bin"
$Xvlog  = Join-Path $BinDir "xvlog.bat"
$Xelab  = Join-Path $BinDir "xelab.bat"
$Xsim   = Join-Path $BinDir "xsim.bat"

# -- Helpers -------------------------------------------------
function Write-Step([string]$Num, [string]$Label) {
    Write-Host ""
    Write-Host "-----------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Step $Num > $Label" -ForegroundColor Cyan
    Write-Host "-----------------------------------------" -ForegroundColor DarkGray
}

function Assert-Tool([string]$Path) {
    if (-not (Test-Path $Path)) {
        Write-Host "[ERROR] Tool not found: $Path" -ForegroundColor Red
        Write-Host "        Check -VivadoPath or your Vivado installation." -ForegroundColor Yellow
        exit 1
    }
}

function Assert-Source([string]$Path) {
    if (-not (Test-Path $Path)) {
        Write-Host "[ERROR] Source file not found: $Path" -ForegroundColor Red
        exit 1
    }
}

function Run-Command {
    param(
        [string[]]$CmdArgs,
        [string]$Tool
    )
    Write-Host ""
    Write-Host "CMD: $Tool $($CmdArgs -join ' ')" -ForegroundColor DarkYellow
    & $Tool @CmdArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "[FAILED] Exit code $LASTEXITCODE - aborting." -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

# -- Pre-flight checks ---------------------------------------
Write-Host ""
Write-Host "===========================================" -ForegroundColor Magenta
Write-Host "  Vivado Simulation Runner" -ForegroundColor Magenta
Write-Host "===========================================" -ForegroundColor Magenta
Write-Host "  Module   : $Module"
Write-Host "  Package  : $(if ($UsePackage) { 'Yes' } else { 'No' })"
Write-Host "  Vivado   : $VivadoPath"
Write-Host "  RTL dir  : $RtlDir"
Write-Host "  TB dir   : $TbDir"
Write-Host "  Build dir: $BuildDir"

Assert-Tool $Xvlog
Assert-Tool $Xelab
Assert-Tool $Xsim

if ($UsePackage) { Assert-Source $PkgFile }
Assert-Source $RtlFile
Assert-Source $TbFile

Push-Location $BuildDir
try {
    # -- Step 1: Compile -----------------------------------------
    Write-Step "1" "Compile (xvlog)"

    $CompileArgs = @("-sv")
    if ($UsePackage) { $CompileArgs += $PkgFile }
    $CompileArgs += $RtlFile
    $CompileArgs += $TbFile

    Run-Command -Tool $Xvlog -CmdArgs $CompileArgs

    # -- Step 2: Elaborate ---------------------------------------
    Write-Step "2" "Elaborate (xelab)"

    $ElabArgs = @(
        "-top",       $TopName,
        "-snapshot",  $SnapshotName,
        "-timescale", $Timescale
    )

    Run-Command -Tool $Xelab -CmdArgs $ElabArgs

    # -- Step 3: Simulate ----------------------------------------
    Write-Step "3" "Simulate (xsim)"

    $SimArgs = @($SnapshotName, "-R")

    Run-Command -Tool $Xsim -CmdArgs $SimArgs
}
finally {
    Pop-Location
}

# -- Done ----------------------------------------------------
Write-Host ""
Write-Host "===========================================" -ForegroundColor Green
Write-Host "  Simulation complete." -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green