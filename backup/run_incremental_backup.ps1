param(
    [Parameter(Mandatory = $true)]
    [int]$Day
)

. (Join-Path $PSScriptRoot "common.ps1")

Ensure-Directories
Assert-Tooling

$targetDir = Join-Path $ProjectConfig.IncrementalDir ("day{0}" -f $Day)
$binlogDir = Join-Path $targetDir "binlogs"
$logFile = Join-Path $ProjectConfig.LogDir ("incremental_backup_day{0}.log" -f $Day)
$timesFile = Join-Path $ProjectConfig.LogDir "tiempos_backup.csv"

if (Test-Path -LiteralPath $targetDir) {
    Remove-Item -LiteralPath $targetDir -Recurse -Force
}
New-Item -ItemType Directory -Path $binlogDir -Force | Out-Null

$start = Get-Date
Write-Log "INCREMENTAL BACKUP DIA $Day - inicio" $logFile

if ($Day -eq 1) {
    $fullMetaPath = Join-Path (Join-Path $ProjectConfig.FullDir "day1") "backup_metadata.json"
    if (-not (Test-Path -LiteralPath $fullMetaPath)) {
        throw "Primero debes ejecutar full_backup_day1.ps1"
    }

    $fullMeta = Load-JsonFile -Path $fullMetaPath
    $metadata = [pscustomobject]@{
        Day = 1
        BackupType = "INCREMENTAL"
        CreatedAt = (Get-Date).ToString("s")
        BaseFullDay = 1
        StartFile = $fullMeta.IncrementalStartFile
        EndFile = $null
        NextStartFile = $fullMeta.IncrementalStartFile
        BinlogFiles = @()
        Notes = "Dia 1 deja definido el punto de inicio de la cadena incremental."
    }
    Save-JsonFile -Path (Join-Path $targetDir "backup_metadata.json") -Object $metadata

    $end = Get-Date
    $elapsedMs = [int][Math]::Round(($end - $start).TotalMilliseconds, 0)
    Append-CsvLine -Path $timesFile `
        -Header "dia,tipo,operacion,inicio,fin,duracion_ms,duracion_seg,tamano_mb" `
        -Line ("1,INCREMENTAL,BACKUP,{0},{1},{2},{3:N3},0.00" -f $start.ToString("s"), $end.ToString("s"), $elapsedMs, (($end - $start).TotalSeconds))
    Write-Log "Incremental dia 1 preparado como marcador de cadena." $logFile
    return
}

$previousMetaPath = Join-Path (Join-Path $ProjectConfig.IncrementalDir ("day{0}" -f ($Day - 1))) "backup_metadata.json"
if (-not (Test-Path -LiteralPath $previousMetaPath)) {
    throw "No existe el incremental del dia anterior: $previousMetaPath"
}

$previousMeta = Load-JsonFile -Path $previousMetaPath
$startFile = $previousMeta.NextStartFile
if (-not $startFile) {
    throw "No se encontro el punto inicial de binlog para el incremental del dia $Day"
}

$currentBinlog = Rotate-And-GetCurrentBinlog
$closedFiles = @(Get-ClosedBinlogFiles -StartFile $startFile -CurrentActiveFile $currentBinlog.File)

foreach ($file in $closedFiles) {
    $sourcePath = Join-Path $ProjectConfig.DataDir $file
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "No se encontro el binlog a respaldar: $sourcePath"
    }
    Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $binlogDir $file) -Force
    Write-Log "Binlog respaldado: $file" $logFile
}

$end = Get-Date
$elapsedMs = [int][Math]::Round(($end - $start).TotalMilliseconds, 0)
$sizeMb = Get-FileSizeMB -Path $binlogDir

$metadata = [pscustomobject]@{
    Day = $Day
    BackupType = "INCREMENTAL"
    CreatedAt = $end.ToString("s")
    BaseFullDay = 1
    StartFile = $startFile
    EndFile = if ($closedFiles.Count -gt 0) { $closedFiles[-1] } else { $null }
    NextStartFile = $currentBinlog.File
    BinlogFiles = $closedFiles
}
Save-JsonFile -Path (Join-Path $targetDir "backup_metadata.json") -Object $metadata

Append-CsvLine -Path $timesFile `
    -Header "dia,tipo,operacion,inicio,fin,duracion_ms,duracion_seg,tamano_mb" `
    -Line ("{0},INCREMENTAL,BACKUP,{1},{2},{3},{4:N3},{5}" -f $Day, $start.ToString("s"), $end.ToString("s"), $elapsedMs, (($end - $start).TotalSeconds), $sizeMb)

Write-Log "Incremental backup completado. Binlogs: $($closedFiles.Count). Tamano MB: $sizeMb" $logFile
