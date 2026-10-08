param(
    [string]$Godot = 'D:\Godot_v4.7.2\Godot_v4.7.2-stable_win64_console.exe',
    [switch]$Export,
    [switch]$Routes
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$env:GODOT_FORGE_NO_SERVER = '1'
& $Godot --headless --editor --path $projectRoot --import --quit
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
foreach ($runner in @('qa_runner', 'traversal_runner', 'recovery_runner', 'combat_runner', 'loop_runner')) {
    & $Godot --headless --path $projectRoot --script "res://tests/$runner.gd"
    if ($LASTEXITCODE -ne 0) { throw "$runner failed." }
}
if ($Routes) {
    & $Godot --headless --path $projectRoot --script res://tests/route_runner.gd
    if ($LASTEXITCODE -ne 0) { throw 'Route audit failed.' }
}
if ($Export) {
    $target = Join-Path $projectRoot 'builds\windows\Margin.exe'
    New-Item -ItemType Directory -Force (Split-Path -Parent $target) | Out-Null
    & $Godot --headless --path $projectRoot --export-release 'Windows Desktop' $target
    if ($LASTEXITCODE -ne 0) { throw 'Windows export failed.' }
}
