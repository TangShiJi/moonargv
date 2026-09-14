param(
  [int]$Runs = 5
)

$ErrorActionPreference = 'Stop'
$moon = Join-Path $env:USERPROFILE '.moon\bin\moon.exe'
$samples = @()
for ($index = 0; $index -lt $Runs; $index++) {
  $elapsed = Measure-Command {
    & $moon run --release bench/roundtrip | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'benchmark driver failed' }
  }
  $samples += [math]::Round($elapsed.TotalMilliseconds, 2)
}
$ordered = $samples | Sort-Object
$median = $ordered[[math]::Floor($ordered.Count / 2)]
[pscustomobject]@{
  Workload = '20,000 join+parse round trips'
  Runs = $Runs
  SamplesMs = $samples -join ', '
  MedianMs = $median
}
