param([string]$Game = '', [switch]$Routes, [switch]$Render)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (!$Game) { $Game = Join-Path $projectRoot 'builds\windows\Margin.exe' }
$output = Join-Path $projectRoot 'tests\output'
New-Item -ItemType Directory -Force $output | Out-Null
$runs = @('integration', 'traversal', 'recovery', 'combat', 'loop')
if ($Routes) { $runs += 'routes' }
if ($Render) { $runs += @('visual', 'render') }
foreach ($run in $runs) {
    $arguments = @('--log-file', "$output/exe-$run.log")
    if ($run -notin @('render', 'visual')) { $arguments += '--headless' }
    $arguments += @('--', "--self-test=$run", "--report=$output/exe-$run-report.json", "--output=$output")
    $process = Start-Process -FilePath $Game -ArgumentList $arguments -WindowStyle Hidden -PassThru -Wait -RedirectStandardOutput "$output/exe-$run-stdout.log" -RedirectStandardError "$output/exe-$run-stderr.log"
    if ($process.ExitCode -ne 0) { throw "$run failed with code $($process.ExitCode)." }
    $errors = Get-Content "$output/exe-$run-stderr.log" -Raw
    if ($errors -match 'ERROR:|SCRIPT ERROR:') { throw "$run emitted engine errors: $errors" }
    Write-Output "$run passed."
}
