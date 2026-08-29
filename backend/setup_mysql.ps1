param(
  [string]$HostName = "127.0.0.1",
  [int]$Port = 3306,
  [string]$User = "root",
  [string]$Password = "root",
  [string]$Database = "link"
)

$mysql = "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe"
if (-not (Test-Path $mysql)) {
  Write-Host "未找到 MySQL 客户端，请确认已安装 MySQL Server。"
  exit 1
}

$sqlFile = Join-Path $PSScriptRoot "sql\00_create_database.sql"
& $mysql -h $HostName -P $Port -u $User "-p$Password" < $sqlFile
if ($LASTEXITCODE -ne 0) {
  Write-Host "连接 MySQL 失败。请先在「服务」中启动 MySQL，或修改账号密码。"
  exit $LASTEXITCODE
}

Set-Location $PSScriptRoot
.\.venv\Scripts\python init_db.py
