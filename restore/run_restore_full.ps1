param(
    [Parameter(Mandatory = $true)]
    [int]$Day
)

. (Join-Path (Split-Path -Parent $PSScriptRoot) "backup\common.ps1")

Ensure-Directories
Assert-Tooling

$backupDir = Join-Path $ProjectConfig.FullDir ("day{0}" -f $Day)
$dataBackupDir = Join-Path $backupDir "data"
$logFile = Join-Path $ProjectConfig.LogDir ("restore_full_day{0}.log" -f $Day)
$timesFile = Join-Path $ProjectConfig.LogDir "tiempos_restauracion.csv"

if (-not (Test-Path -LiteralPath $dataBackupDir)) {
    throw "No existe el full backup del dia $Day en $dataBackupDir"
}

$start = Get-Date
Write-Log "RESTORE FULL DIA $Day - inicio" $logFile

Stop-MySqlServiceSafe
try {
    Clear-DirectoryContents -Path $ProjectConfig.DataDir
    Copy-DirectoryMirror -Source $dataBackupDir -Destination $ProjectConfig.DataDir
}
finally {
    Start-MySqlServiceSafe
}

Clone-Schema -SourceSchema $ProjectConfig.SourceSchema -TargetSchema $ProjectConfig.RestoreSchema -LogFile $logFile

$end = Get-Date
$elapsedMs = [int][Math]::Round(($end - $start).TotalMilliseconds, 0)

Append-CsvLine -Path $timesFile `
    -Header "dia,tipo,operacion,inicio,fin,duracion_ms,duracion_seg" `
    -Line ("{0},FULL,RESTORE,{1},{2},{3},{4:N3}" -f $Day, $start.ToString("s"), $end.ToString("s"), $elapsedMs, (($end - $start).TotalSeconds))

Write-Log "Restauracion full completada y esquema secundario clonado: $($ProjectConfig.RestoreSchema)" $logFile
