# ============================================================
#  cpu_test_run.ps1  -  Xilinx Vivado Compile / Elaborate / Simulate
#  Usage:
#    .\cpu_test_run.ps1
#    .\cpu_test_run.ps1 -TestNumber 2
#    .\cpu_test_run.ps1 -VivadoPath "C:\Xilinx\Vivado\2024.2"
# ============================================================

param (
    [Parameter(HelpMessage = "Path to the Vivado installation root")]
    [string]$VivadoPath = "C:\Xilinx\Vivado\2024.2",

    [Parameter(HelpMessage = "Path to the RTL source directory")]
    [string]$RtlDir = "..\rtl",

    [Parameter(HelpMessage = "Path to the testbench directory")]
    [string]$TbDir = "..\tb",

    [Parameter(HelpMessage = "Path to the simulation data directory")]
    [string]$DataDir = ".",

    [Parameter(HelpMessage = "CPU test number to run (1, 2, or 3)")]
    [ValidateRange(1, 4)]
    [int]$TestNumber = 1,

    [Parameter(HelpMessage = "Timescale passed to xelab (default: 1ns/100ps)")]
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

function Copy-DataFiles([string]$SourceDir, [string]$DestinationDir) {
    $files = Get-ChildItem -Path $SourceDir -Filter "CPUtest*.dat" -File
    if (-not $files) {
        Write-Host "[ERROR] No CPUtest*.dat files found in $SourceDir" -ForegroundColor Red
        exit 1
    }

    foreach ($file in $files) {
        Copy-Item -Force $file.FullName $DestinationDir
    }
}

function Resolve-TbFileName([int]$Number) {
    return "cpu_tb_$Number.sv"
}

# -- Source files --------------------------------------------
$RtlFiles = @(
    (Join-Path (Get-AbsolutePath $RtlDir) "control_pkg.sv"),
    (Join-Path (Get-AbsolutePath $RtlDir) "typedefs.sv"),
    (Join-Path (Get-AbsolutePath $RtlDir) "alu_pkg.sv"),
    (Join-Path (Get-AbsolutePath $RtlDir) "register.sv"),
    (Join-Path (Get-AbsolutePath $RtlDir) "counter.sv"),
    (Join-Path (Get-AbsolutePath $RtlDir) "scale_mux.sv"),
    (Join-Path (Get-AbsolutePath $RtlDir) "alu.sv"),
    (Join-Path (Get-AbsolutePath $RtlDir) "control.sv"),
    (Join-Path (Get-AbsolutePath $RtlDir) "mem.sv"),
    (Join-Path (Get-AbsolutePath $RtlDir) "cpu.sv")
)

$ResolvedTbFileName = Resolve-TbFileName -Number $TestNumber
$TbFile = Join-Path (Get-AbsolutePath $TbDir) $ResolvedTbFileName
$TopName = "cpu_test_$TestNumber"
$SnapshotName = "cpu_sim_$TestNumber"

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
Write-Host "  Vivado CPU Test Runner" -ForegroundColor Magenta
Write-Host "===========================================" -ForegroundColor Magenta
Write-Host "  Vivado   : $VivadoPath"
Write-Host "  RTL dir  : $RtlDir"
Write-Host "  TB dir   : $TbDir"
Write-Host "  TB file  : $ResolvedTbFileName"
Write-Host "  Top      : $TopName"
Write-Host "  Snapshot : $SnapshotName"
Write-Host "  Data dir : $DataDir"
Write-Host "  Test #   : $TestNumber"
Write-Host "  Build dir: $BuildDir"

Assert-Tool $Xvlog
Assert-Tool $Xelab
Assert-Tool $Xsim

foreach ($rtlFile in $RtlFiles) { Assert-Source $rtlFile }
Assert-Source $TbFile

$DataSourceDir = Get-AbsolutePath $DataDir
if (-not (Test-Path $DataSourceDir)) {
    Write-Host "[ERROR] Data directory not found: $DataSourceDir" -ForegroundColor Red
    exit 1
}

Copy-DataFiles -SourceDir $DataSourceDir -DestinationDir $BuildDir

Push-Location $BuildDir
try {
    # -- Step 1: Compile -------------------------------------
    Write-Step "1" "Compile (xvlog)"

    $CompileArgs = @("-sv") + $RtlFiles + @($TbFile)
    Run-Command -Tool $Xvlog -CmdArgs $CompileArgs

    # -- Step 2: Elaborate -----------------------------------
    Write-Step "2" "Elaborate (xelab)"

    $ElabArgs = @(
        "-top",      $TopName,
        "-snapshot", $SnapshotName,
        "-timescale", $Timescale
    )

    Run-Command -Tool $Xelab -CmdArgs $ElabArgs

    # -- Step 3: Simulate ------------------------------------
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
Write-Host "  CPU simulation complete." -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green