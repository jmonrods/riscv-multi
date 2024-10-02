## run.ps1
# Wrapper script to run simulations using Questa under Windows
#
# Usage: from the top-level directory, call the script with one argument
# The argument is the complete name of the problem without the file extension
# Read the script to look for the available "targets"
#
# Example:
# .\run.ps1 cpu_02

param(
    [string]$Argument
)

# Path to Questa
$env:Path = 'C:\questasim64_2024.1\win64;' + $env:Path

# Path to Repo
$REPO = Get-Location
$REPO = $REPO -replace "\\","/"
Write-Host $REPO
New-Item -ItemType Directory -Force -Path $REPO\target

# This line converts all backlashes into forward slashes for Questa
$REPO = $REPO -replace "\\","/"
Write-Host $REPO


# Run the simulation now
if ($Argument -eq "clean") {
    Remove-Item $REPO\work\ -Recurse           -ErrorAction SilentlyContinue
    Remove-Item $REPO\modelsim.ini             -ErrorAction SilentlyContinue
    Remove-Item $REPO\transcript               -ErrorAction SilentlyContinue
    Remove-Item $REPO\vsim.wlf                 -ErrorAction SilentlyContinue
	Remove-Item $REPO\vsim_stacktrace.vstf     -ErrorAction SilentlyContinue
    Remove-Item $REPO\coverage.ucdb            -ErrorAction SilentlyContinue
} elseif ($Argument -eq "cpu_00") {
    vlib work
	vmap work work
	vlog -sv ./multi/cpu_tb.sv ./multi/cpu.sv
	vsim -c work.cpu_tb -do "run -all; quit -f;"
} else {
    Write-Host "Target not specified OR the specified target was not found."
    Write-Host "Call the command from the top as: > .\run.ps1 cpu_02"
}
