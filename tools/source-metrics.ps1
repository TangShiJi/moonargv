$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$sourceFiles = Get-ChildItem -LiteralPath $projectRoot -Recurse -Filter '*.mbt' -File |
  Where-Object {
    $_.FullName -notmatch '[\\/]_build[\\/]' -and
    $_.Name -notmatch '(?:_test|_wbtest)\.mbt$'
  }
$testFiles = Get-ChildItem -LiteralPath $projectRoot -Recurse -Filter '*.mbt' -File |
  Where-Object {
    $_.FullName -notmatch '[\\/]_build[\\/]' -and
    $_.Name -match '(?:_test|_wbtest)\.mbt$'
  }

function Measure-MoonBitLines([System.IO.FileInfo[]] $files) {
  $physical = 0
  $nonBlank = 0
  $nonBlankNonComment = 0
  foreach ($file in $files) {
    $lines = Get-Content -LiteralPath $file.FullName
    $physical += $lines.Count
    $nonBlank += ($lines | Where-Object { $_.Trim().Length -gt 0 }).Count
    $nonBlankNonComment += ($lines | Where-Object {
      $trimmed = $_.Trim()
      $trimmed.Length -gt 0 -and -not $trimmed.StartsWith('//')
    }).Count
  }
  [pscustomobject]@{
    Files = $files.Count
    PhysicalLines = $physical
    NonBlankLines = $nonBlank
    NonBlankNonCommentLines = $nonBlankNonComment
  }
}

[pscustomobject]@{
  Production = Measure-MoonBitLines $sourceFiles
  Tests = Measure-MoonBitLines $testFiles
} | ConvertTo-Json -Depth 3
