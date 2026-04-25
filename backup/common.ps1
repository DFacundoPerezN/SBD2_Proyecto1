Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "config.ps1")

function Ensure-Directories {
    foreach ($path in @(
        $ProjectConfig.BackupBaseDir,
        $ProjectConfig.FullDir,
        $ProjectConfig.IncrementalDir,
        $ProjectConfig.LogDir,
        $ProjectConfig.EvidenceDir
    )) {
        if (-not (Test-Path -LiteralPath $path)) {
            New-Item -ItemType Directory -Path $path | Out-Null
        }
    }
}

function Write-Log {
    param([string]$Message, [string]$LogFile)
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    $line | Tee-Object -FilePath $LogFile -Append
}

function Assert-Tooling {
    foreach ($tool in @(
        $ProjectConfig.MySqlExe,
        $ProjectConfig.MySqlAdminExe,
        $ProjectConfig.MySqlBinlogExe
    )) {
        if (-not (Test-Path -LiteralPath $tool)) {
            throw "No se encontro el binario requerido: $tool"
        }
    }
}

function Get-MySqlArgs {
    param([string]$Database)
    $args = @(
        "--host=$($ProjectConfig.MySqlHost)",
        "--port=$($ProjectConfig.MySqlPort)",
        "--user=$($ProjectConfig.MySqlUser)"
    )
    if ($ProjectConfig.MySqlPassword) {
        $args += "--password=$($ProjectConfig.MySqlPassword)"
    }
    if ($Database) {
        $args += "--database=$Database"
    }
    return $args
}

function Invoke-MySqlQuery {
    param(
        [Parameter(Mandatory = $true)][string]$Query,
        [string]$Database,
        [switch]$Batch
    )
    $args = Get-MySqlArgs -Database $Database
    if ($Batch) {
        $args += "--batch"
        $args += "--raw"
        $args += "--skip-column-names"
    }
    $args += "-e"
    $args += $Query
    & $ProjectConfig.MySqlExe @args
}

function Stop-MySqlServiceSafe {
    net stop $ProjectConfig.MySqlService | Out-Null
    Start-Sleep -Seconds 2
}

function Start-MySqlServiceSafe {
    net start $ProjectConfig.MySqlService | Out-Null
    Start-Sleep -Seconds 4
}

function Copy-DirectoryMirror {
    param([string]$Source, [string]$Destination)
    if (-not (Test-Path -LiteralPath $Destination)) {
        New-Item -ItemType Directory -Path $Destination | Out-Null
    }
    $null = robocopy $Source $Destination /MIR /COPY:DAT /DCOPY:DAT /R:2 /W:2 /NFL /NDL /NJH /NJS /NP
    if ($LASTEXITCODE -gt 7) {
        throw "Robocopy fallo con codigo $LASTEXITCODE"
    }
}

function Clear-DirectoryContents {
    param([string]$Path)
    Get-ChildItem -LiteralPath $Path -Force | Remove-Item -Recurse -Force
}

function Save-JsonFile {
    param([string]$Path, [object]$Object)
    $Object | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $Path -Encoding UTF8
}

function Load-JsonFile {
    param([string]$Path)
    Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
}

function Rotate-And-GetCurrentBinlog {
    Invoke-MySqlQuery -Query "FLUSH BINARY LOGS;"
    $row = Invoke-MySqlQuery -Query "SHOW BINARY LOG STATUS;" -Batch
    $parts = $row -split "`t"
    [pscustomobject]@{
        File     = $parts[0]
        Position = if ($parts.Length -gt 1) { $parts[1] } else { "" }
    }
}

function Get-BinaryLogs {
    $rows = Invoke-MySqlQuery -Query "SHOW BINARY LOGS;" -Batch
    $logs = @()
    foreach ($row in $rows) {
        if (-not $row) { continue }
        $parts = $row -split "`t"
        $logs += [pscustomobject]@{
            File = $parts[0]
            Size = if ($parts.Length -gt 1) { [int64]$parts[1] } else { 0 }
        }
    }
    $logs
}

function Get-ClosedBinlogFiles {
    param([string]$StartFile, [string]$CurrentActiveFile)
    $allLogs = Get-BinaryLogs
    $files = @()
    $capture = $false
    foreach ($log in $allLogs) {
        if ($log.File -eq $StartFile) {
            $capture = $true
        }
        if ($capture -and $log.File -ne $CurrentActiveFile) {
            $files += $log.File
        }
        if ($log.File -eq $CurrentActiveFile) {
            break
        }
    }
    $files
}

function Clone-Schema {
    param([string]$SourceSchema, [string]$TargetSchema, [string]$LogFile)
    $tableRows = Invoke-MySqlQuery -Batch -Query @"
SELECT TABLE_NAME
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = '$SourceSchema'
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
"@
    Invoke-MySqlQuery -Query ('DROP DATABASE IF EXISTS `{0}`; CREATE DATABASE `{0}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;' -f $TargetSchema)
    Invoke-MySqlQuery -Database $TargetSchema -Query "SET FOREIGN_KEY_CHECKS = 0;"
    foreach ($table in $tableRows) {
        if (-not $table) { continue }
        if ($LogFile) {
            Write-Log "Clonando tabla $table a esquema $TargetSchema" $LogFile
        }
        Invoke-MySqlQuery -Database $TargetSchema -Query ('CREATE TABLE `{0}` LIKE `{1}`.`{0}`; INSERT INTO `{0}` SELECT * FROM `{1}`.`{0}`;' -f $table, $SourceSchema)
    }
    Invoke-MySqlQuery -Database $TargetSchema -Query "SET FOREIGN_KEY_CHECKS = 1;"
}

function Append-CsvLine {
    param([string]$Path, [string]$Header, [string]$Line)
    if (-not (Test-Path -LiteralPath $Path)) {
        Set-Content -LiteralPath $Path -Value $Header -Encoding UTF8
    }
    Add-Content -LiteralPath $Path -Value $Line -Encoding UTF8
}

function Get-FileSizeMB {
    param([string]$Path)
    $size = (Get-ChildItem -LiteralPath $Path -Recurse -File | Measure-Object -Property Length -Sum).Sum
    if (-not $size) { return "0.00" }
    "{0:N2}" -f ($size / 1MB)
}

function Apply-BinlogsToServer {
    param([string[]]$BinlogPaths)
    if (-not $BinlogPaths -or $BinlogPaths.Count -eq 0) { return }
    $binlogArgs = @("--force-read") + $BinlogPaths
    $mysqlArgs = Get-MySqlArgs
    & $ProjectConfig.MySqlBinlogExe @binlogArgs | & $ProjectConfig.MySqlExe @mysqlArgs
}
