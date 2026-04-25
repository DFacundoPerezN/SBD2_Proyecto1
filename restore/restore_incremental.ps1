param(
    [ValidateSet(1, 2, 3)]
    [int]$TargetDay = 3
)

. (Join-Path (Split-Path -Parent $PSScriptRoot) "backup\common.ps1")

Ensure-Directories
Assert-Tooling

$fullBackupDir = Join-Path $ProjectConfig.FullDir "day1\data"
$logFile = Join-Path $ProjectConfig.LogDir ("restore_incremental_day{0}.log" -f $TargetDay)
$timesFile = Join-Path $ProjectConfig.LogDir "tiempos_restauracion.csv"

if (-not (Test-Path -LiteralPath $fullBackupDir)) {
    throw "No existe el full backup base del dia 1."
}

$start = Get-Date
Write-Log "RESTORE INCREMENTAL HASTA DIA $TargetDay - inicio" $logFile

Stop-MySqlServiceSafe
try {
    Clear-DirectoryContents -Path $ProjectConfig.DataDir
    Copy-DirectoryMirror -Source $fullBackupDir -Destination $ProjectConfig.DataDir
}
finally {
    Start-MySqlServiceSafe
}

$binlogPaths = New-Object System.Collections.Generic.List[string]
if ($TargetDay -ge 2) {
    foreach ($day in 2..$TargetDay) {
        $metaPath = Join-Path (Join-Path $ProjectConfig.IncrementalDir ("day{0}" -f $day)) "backup_metadata.json"
        if (-not (Test-Path -LiteralPath $metaPath)) {
            throw "No existe metadata del incremental dia $day"
        }

        $meta = Load-JsonFile -Path $metaPath
        foreach ($file in $meta.BinlogFiles) {
            $candidate = Join-Path (Join-Path $ProjectConfig.IncrementalDir ("day{0}\binlogs" -f $day)) $file
            if (-not (Test-Path -LiteralPath $candidate)) {
                throw "No existe el binlog incremental esperado: $candidate"
            }
            $binlogPaths.Add($candidate)
            Write-Log "Binlog agregado para replay: $candidate" $logFile
        }
    }
}

Apply-BinlogsToServer -BinlogPaths $binlogPaths.ToArray()
Clone-Schema -SourceSchema $ProjectConfig.SourceSchema -TargetSchema $ProjectConfig.RestoreSchema -LogFile $logFile

$end = Get-Date
$elapsedMs = [int][Math]::Round(($end - $start).TotalMilliseconds, 0)

Append-CsvLine -Path $timesFile `
    -Header "dia,tipo,operacion,inicio,fin,duracion_ms,duracion_seg" `
    -Line ("{0},INCREMENTAL,RESTORE,{1},{2},{3},{4:N3}" -f $TargetDay, $start.ToString("s"), $end.ToString("s"), $elapsedMs, (($end - $start).TotalSeconds))

Write-Log "Restauracion incremental completada hasta dia $TargetDay. Binlogs aplicados: $($binlogPaths.Count)" $logFile
