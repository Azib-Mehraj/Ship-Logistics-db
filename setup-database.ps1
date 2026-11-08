$ErrorActionPreference = "Stop"

$ProjectRoot = $PSScriptRoot
$SchemaFile = Join-Path $ProjectRoot "database\schema.sql"
$SeedFile = Join-Path $ProjectRoot "database\seed.sql"

# Find mysql.exe from PATH first, then from the usual MySQL installation folder.
$MysqlCommand = Get-Command "mysql.exe" -ErrorAction SilentlyContinue
$MysqlExe = $null

if ($MysqlCommand) {
    $MysqlExe = $MysqlCommand.Source
}
else {
    $MysqlBase = "C:\Program Files\MySQL"
    if (Test-Path $MysqlBase) {
        $MysqlExe = Get-ChildItem $MysqlBase -Directory -Filter "MySQL Server*" |
            Sort-Object Name -Descending |
            ForEach-Object {
                $candidate = Join-Path $_.FullName "bin\mysql.exe"
                if (Test-Path $candidate) { $candidate }
            } |
            Select-Object -First 1
    }
}

if (-not $MysqlExe) {
    throw "mysql.exe was not found. Install MySQL Server (including MySQL command-line tools), or add its bin folder to PATH."
}
if (-not (Test-Path $SchemaFile)) { throw "Missing file: $SchemaFile" }
if (-not (Test-Path $SeedFile)) { throw "Missing file: $SeedFile" }

# The SQL files must not switch databases behind this script's back.
foreach ($sqlFile in @($SchemaFile, $SeedFile)) {
    $databaseSwitch = Select-String -LiteralPath $sqlFile -Pattern '^\s*USE\s+' |
        Select-Object -First 1
    if ($databaseSwitch) {
        throw "Remove the USE statement from $sqlFile. This script selects the target database."
    }
}

$DatabaseName = Read-Host "Database name [logistics]"
if ([string]::IsNullOrWhiteSpace($DatabaseName)) {
    $DatabaseName = "logistics"
}
if ($DatabaseName -notmatch '^[A-Za-z0-9_]+$') {
    throw "Invalid database name. Use only letters, numbers, and underscores."
}

Write-Host ""
Write-Host "This will create a NEW database named '$DatabaseName' and load its schema and sample data." -ForegroundColor Cyan
Write-Host "It will not overwrite an existing database." -ForegroundColor Yellow
$confirmation = Read-Host "Type CREATE to continue"
if ($confirmation -cne "CREATE") {
    Write-Host "Cancelled. No database changes were made."
    exit 0
}

$SchemaSql = Get-Content -LiteralPath $SchemaFile -Raw -Encoding UTF8
$SeedSql = Get-Content -LiteralPath $SeedFile -Raw -Encoding UTF8

$RoleAndPermissionSql = @'
INSERT INTO roles (role_name) VALUES
('Admin'),
('Manager'),
('Employee');

INSERT INTO role_permissions (role_id, permission_name)
SELECT r.role_id, p.permission_name
FROM roles AS r
JOIN (
    SELECT 'Admin' AS role_name, 'MANAGE_EMPLOYEES' AS permission_name
    UNION ALL SELECT 'Admin', 'MANAGE_SHIPS'
    UNION ALL SELECT 'Admin', 'MANAGE_ROUTES'
    UNION ALL SELECT 'Admin', 'MANAGE_SHIPMENTS'
    UNION ALL SELECT 'Admin', 'DELETE_RECORDS'

    UNION ALL SELECT 'Manager', 'MANAGE_EMPLOYEES'
    UNION ALL SELECT 'Manager', 'MANAGE_SHIPS'
    UNION ALL SELECT 'Manager', 'MANAGE_ROUTES'
    UNION ALL SELECT 'Manager', 'MANAGE_SHIPMENTS'
    UNION ALL SELECT 'Manager', 'VIEW_NEXT_CHECKPOINT'
    UNION ALL SELECT 'Manager', 'VIEW_SHIP_UPDATES'
    UNION ALL SELECT 'Manager', 'VIEW_ASSIGNED_SHIP'
    UNION ALL SELECT 'Manager', 'VIEW_ASSIGNED_ROUTE'

    UNION ALL SELECT 'Employee', 'VIEW_OWN_PROFILE'
    UNION ALL SELECT 'Employee', 'VIEW_ASSIGNED_SHIP'
    UNION ALL SELECT 'Employee', 'VIEW_ASSIGNED_ROUTE'
    UNION ALL SELECT 'Employee', 'VIEW_NEXT_CHECKPOINT'
    UNION ALL SELECT 'Employee', 'VIEW_SHIP_UPDATES'
) AS p ON p.role_name = r.role_name;
'@

$VerificationSql = @'
SELECT 'employees' AS table_name, COUNT(*) AS total FROM employees
UNION ALL SELECT 'port', COUNT(*) FROM port
UNION ALL SELECT 'route', COUNT(*) FROM route
UNION ALL SELECT 'route_stop', COUNT(*) FROM route_stop
UNION ALL SELECT 'ship', COUNT(*) FROM ship
UNION ALL SELECT 'ship_assignment', COUNT(*) FROM ship_assignment
UNION ALL SELECT 'shipment', COUNT(*) FROM shipment
UNION ALL SELECT 'checkpoint', COUNT(*) FROM checkpoint
UNION ALL SELECT 'shipment_updates', COUNT(*) FROM shipment_updates
UNION ALL SELECT 'roles', COUNT(*) FROM roles
UNION ALL SELECT 'role_permissions', COUNT(*) FROM role_permissions;
'@

$CombinedSql = @"
CREATE DATABASE $DatabaseName CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE $DatabaseName;

-- Project schema
$SchemaSql

-- Sample logistics data
$SeedSql

-- Roles and permissions
$RoleAndPermissionSql

-- Verify imported record counts
$VerificationSql
"@

$TempDirectory = [System.IO.Path]::GetTempPath()
$TempSqlFile = Join-Path $TempDirectory ("ship-logistics-setup-" + [guid]::NewGuid().ToString("N") + ".sql")
$TempDefaultsFile = Join-Path $TempDirectory ("ship-logistics-mysql-" + [guid]::NewGuid().ToString("N") + ".cnf")
$PasswordBstr = [IntPtr]::Zero
$PlainPassword = $null

try {
    # Ask once, then place credentials in a short-lived, user-restricted MySQL option file.
    $SecurePassword = Read-Host "Enter MySQL root password" -AsSecureString
    $PasswordBstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    $PlainPassword = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($PasswordBstr)

    # Escape characters interpreted specially in MySQL option files.
    $EscapedPassword = $PlainPassword.Replace('\', '\\').Replace('"', '\"')

    $DefaultsContent = @"
[client]
user=root
password="$EscapedPassword"
host=localhost
port=3306
default-character-set=utf8mb4
"@

    [System.IO.File]::WriteAllText(
        $TempDefaultsFile,
        $DefaultsContent,
        [System.Text.UTF8Encoding]::new($false)
    )

    # Restrict the temporary credential file to this Windows user and local administrators/SYSTEM.
    $Acl = Get-Acl -LiteralPath $TempDefaultsFile
    $Acl.SetAccessRuleProtection($true, $false)
    foreach ($ExistingRule in @($Acl.Access)) {
        [void]$Acl.RemoveAccessRuleAll($ExistingRule)
    }

    $CurrentSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User
    $SystemSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18")
    $AdministratorsSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
    $FullControl = [System.Security.AccessControl.FileSystemRights]::FullControl
    $Allow = [System.Security.AccessControl.AccessControlType]::Allow
    $Inheritance = [System.Security.AccessControl.InheritanceFlags]::None
    $Propagation = [System.Security.AccessControl.PropagationFlags]::None

    foreach ($Sid in @($CurrentSid, $SystemSid, $AdministratorsSid)) {
        $Rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $Sid, $FullControl, $Inheritance, $Propagation, $Allow
        )
        [void]$Acl.AddAccessRule($Rule)
    }
    Set-Acl -LiteralPath $TempDefaultsFile -AclObject $Acl

    [System.IO.File]::WriteAllText(
        $TempSqlFile,
        $CombinedSql,
        [System.Text.UTF8Encoding]::new($false)
    )

    Write-Host ""
    Write-Host "Connecting to MySQL and initializing '$DatabaseName'..." -ForegroundColor Cyan

    # Redirect SQL through the process input stream. Credentials are read from the
    # protected option file, so SQL input and password input cannot conflict.
    $StartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $StartInfo.FileName = $MysqlExe
    $StartInfo.Arguments = "--defaults-extra-file=`"$TempDefaultsFile`" --batch"
    $StartInfo.UseShellExecute = $false
    $StartInfo.RedirectStandardInput = $true
    $StartInfo.RedirectStandardOutput = $true
    $StartInfo.RedirectStandardError = $true
    $StartInfo.CreateNoWindow = $true

    $Process = New-Object System.Diagnostics.Process
    $Process.StartInfo = $StartInfo
    [void]$Process.Start()

    $StdoutTask = $Process.StandardOutput.ReadToEndAsync()
    $StderrTask = $Process.StandardError.ReadToEndAsync()

    $SqlWriter = $Process.StandardInput
    $SqlWriter.Write($CombinedSql)
    $SqlWriter.Close()

    $Process.WaitForExit()
    $Stdout = $StdoutTask.Result
    $Stderr = $StderrTask.Result

    if ($Stdout) { Write-Host $Stdout }
    if ($Process.ExitCode -ne 0) {
        if ($Stderr) { Write-Host $Stderr -ForegroundColor Red }
        throw "Database initialization failed. If the database was newly created, it may be partially initialized. Inspect it before rerunning."
    }
    if ($Stderr) { Write-Host $Stderr }

    Write-Host ""
    Write-Host "Database initialization completed." -ForegroundColor Green
    Write-Host "Created database: $DatabaseName"
    Write-Host "Imported the schema and sample records, then added Admin, Manager, and Employee roles with all 18 permissions."
    Write-Host "No login account was created. Each developer must create their own local Admin login."
}
finally {
    if ($PasswordBstr -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($PasswordBstr)
    }
    $PlainPassword = $null
    $EscapedPassword = $null
    $DefaultsContent = $null

    foreach ($TempFile in @($TempSqlFile, $TempDefaultsFile)) {
        if ($TempFile -and (Test-Path -LiteralPath $TempFile)) {
            Remove-Item -LiteralPath $TempFile -Force
        }
    }
}
