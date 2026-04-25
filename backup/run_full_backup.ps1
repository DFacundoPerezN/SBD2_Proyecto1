param(
    [Parameter(Mandatory = $true)]
    [int]$Day
)

. (Join-Path $PSScriptRoot "common.ps1")

Ensure-Directories
Assert-Tooling

$targetDir = Join-Path $ProjectConfig.FullDir ("day{0}" -f $Day)
$dataBackupDir = Join-Path $targetDir "data"
$logFile = Join-Path $ProjectConfig.LogDir ("full_backup_day{0}.log" -f $Day)
$timesFile = Join-Path $ProjectConfig.LogDir "tiempos_backup.csv"

if (Test-Path -LiteralPath $targetDir) {
    Remove-Item -LiteralPath $targetDir -Recurse -Force
}
New-Item -ItemType Directory -Path $dataBackupDir -Force | Out-Null

$start = Get-Date
Write-Log "FULL BACKUP DIA $Day - inicio" $logFile

$binlogInfo = Rotate-And-GetCurrentBinlog
Write-Log "Binlog activo despues del FLUSH: $($binlogInfo.File) posicion $($binlogInfo.Position)" $logFile

Stop-MySqlServiceSafe
try {
    Copy-DirectoryMirror -Source $ProjectConfig.DataDir -Destination $dataBackupDir
}
finally {
    Start-MySqlServiceSafe
}

$end = Get-Date
$elapsedMs = [int][Math]::Round(($end - $start).TotalMilliseconds, 0)
$sizeMb = Get-FileSizeMB -Path $dataBackupDir

$metadata = [pscustomobject]@{
    Day = $Day
    BackupType = "FULL"
    CreatedAt = $end.ToString("s")
    SourceSchema = $ProjectConfig.SourceSchema
    RestoreSchema = $ProjectConfig.RestoreSchema
    DataBackupDir = $dataBackupDir
    IncrementalStartFile = $binlogInfo.File
    IncrementalStartPosition = $binlogInfo.Position
}
Save-JsonFile -Path (Join-Path $targetDir "backup_metadata.json") -Object $metadata

Append-CsvLine -Path $timesFile `
    -Header "dia,tipo,operacion,inicio,fin,duracion_ms,duracion_seg,tamano_mb" `
    -Line ("{0},FULL,BACKUP,{1},{2},{3},{4:N3},{5}" -f $Day, $start.ToString("s"), $end.ToString("s"), $elapsedMs, (($end - $start).TotalSeconds), $sizeMb)

Write-Log "Full backup completado. Tamano MB: $sizeMb" $logFile
