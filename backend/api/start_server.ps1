$logFile = "K:\Swift Egypt\swift_egypt\backend\api\server.log"
$errFile = "K:\Swift Egypt\swift_egypt\backend\api\server.err"
$python = "K:\Swift Egypt\swift_egypt\backend\api\venv\Scripts\python.exe"
$args = @("-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload")

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $python
$psi.Arguments = $args
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$psi.WorkingDirectory = "K:\Swift Egypt\swift_egypt\backend\api"
$p = [System.Diagnostics.Process]::Start($psi)
$p | Export-Clixml -Path "K:\Swift Egypt\swift_egypt\backend\api\.server_proc.xml"
Write-Output "Backend server started with PID $($p.Id)"
