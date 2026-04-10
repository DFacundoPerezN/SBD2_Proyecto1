$ProjectRoot = Split-Path -Parent $PSScriptRoot

$ProjectConfig = @{
    MySqlBinDir    = "C:\Program Files\MySQL\MySQL Server 9.2\bin"
    MySqlExe       = "C:\Program Files\MySQL\MySQL Server 9.2\bin\mysql.exe"
    MySqlAdminExe  = "C:\Program Files\MySQL\MySQL Server 9.2\bin\mysqladmin.exe"
    MySqlBinlogExe = "C:\Program Files\MySQL\MySQL Server 9.2\bin\mysqlbinlog.exe"
    MySqlUser      = "root"
    MySqlPassword  = "Proyecto1Mysql!2026"
    MySqlHost      = "127.0.0.1"
    MySqlPort      = 3308
    MySqlService   = "MySQL92"
    MyIniPath      = "C:\ProgramData\MySQL\MySQL Server 9.2\my.ini"
    DataDir        = "C:\ProgramData\MySQL\MySQL Server 9.2\Data"
    SourceSchema   = "proyecto1_mundiales"
    RestoreSchema  = "proyecto2_mundiales"
    BackupBaseDir  = (Join-Path $ProjectRoot "runtime\backups")
    EvidenceDir    = (Join-Path $ProjectRoot "runtime\evidence")
}

$ProjectConfig.FullDir = Join-Path $ProjectConfig.BackupBaseDir "full"
$ProjectConfig.IncrementalDir = Join-Path $ProjectConfig.BackupBaseDir "incremental"
$ProjectConfig.LogDir = Join-Path $ProjectConfig.BackupBaseDir "logs"
