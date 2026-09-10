$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$Out = if ($args.Count -gt 0) { $args[0] } else { Join-Path $Root 'Starfall-Vengeance.love' }
if (Test-Path $Out) { Remove-Item $Out -Force }
Push-Location $Root
try {
  $files = Get-ChildItem -Recurse -File | Where-Object { $_.FullName -notmatch '\\.git\\' -and $_.FullName -ne $Out -and $_.Extension -ne '.love' }
  Compress-Archive -Path ($files.FullName) -DestinationPath "$Out.zip" -Force
  Move-Item "$Out.zip" $Out -Force
  Write-Host "Created $Out"
} finally { Pop-Location }
