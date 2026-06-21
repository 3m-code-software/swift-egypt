$python = "K:\Swift Egypt\swift_egypt\backend\api\venv\Scripts\python.exe"
$workdir = "K:\Swift Egypt\swift_egypt\backend\api"
$log = Join-Path $workdir "server.log"
$err = Join-Path $workdir "server.err"

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $python
$psi.Arguments = "-m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"
$psi.WorkingDirectory = $workdir
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $false
$psi.RedirectStandardError = $false
$psi.CreateNoWindow = $true

$p = [System.Diagnostics.Process]::Start($psi)
$p.Id | Out-File (Join-Path $workdir "server.pid")
Write-Host "Server started with PID: $($p.Id)"
