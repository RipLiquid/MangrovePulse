$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$rCommand = Get-Command Rscript.exe -ErrorAction SilentlyContinue
$rExecutable = if ($rCommand) { $rCommand.Source } else { 'C:\Program Files\R\R-4.6.1\bin\Rscript.exe' }
if (-not (Test-Path -LiteralPath $rExecutable)) {
  throw 'Rscript.exe was not found. Update the R path in run.ps1 to match your installation.'
}
& $rExecutable --vanilla scripts/02_country_analysis.R
if ($LASTEXITCODE -ne 0) { throw 'Analysis stopped. Copy the R error above for help.' }
Write-Host 'Done. Open reports/research_brief.html in your browser.'
