# Per-user installation. No administrator privileges are requested.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root
$logStarted = $false

function Test-Python([string]$Executable, [string[]]$Prefix = @()) {
    try {
        & $Executable @Prefix -c 'import sys,venv; sys.exit(0 if sys.version_info >= (3,10) else 1)' 2>$null
        return ($LASTEXITCODE -eq 0)
    } catch { return $false }
}

try {
    Start-Transcript -Path (Join-Path $root 'install.log') -Append | Out-Null
    $logStarted = $true
    foreach ($file in @('app.py','desktop.py','requirements.txt','assets\duty-template.docx','Start DutyDesk.bat')) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $file))) {
            throw "Missing $file. Extract the entire DutyDesk ZIP before running the installer."
        }
    }

    $venvPython = Join-Path $root '.venv-windows\Scripts\python.exe'
    if (-not (Test-Python $venvPython)) {
        $python = $null
        $prefixArgs = @()
        $privatePython = Join-Path $env:LOCALAPPDATA 'DutyDesk\Python313\python.exe'
        foreach ($candidate in @($privatePython, 'py.exe', 'python.exe')) {
            # Do not invoke Windows' placeholder alias, which opens the Store.
            if ($candidate -eq 'python.exe') {
                $command = Get-Command $candidate -ErrorAction SilentlyContinue
                if (-not $command -or $command.Source -like '*\Microsoft\WindowsApps\*') { continue }
            }
            $candidateArgs = @()
            if ($candidate -eq 'py.exe') { $candidateArgs = @('-3') }
            if (Test-Python $candidate $candidateArgs) {
                $python = $candidate
                $prefixArgs = $candidateArgs
                break
            }
        }

        if (-not $python) {
            Write-Host 'Installing Python for your Windows account...'
            # Download from Python.org and require a valid Python Foundation
            # Authenticode signature before running the installer.
            $version = '3.13.7'
            $suffix = if ([Environment]::Is64BitOperatingSystem) { '-amd64' } else { '' }
            $url = "https://www.python.org/ftp/python/$version/python-$version$suffix.exe"
            $download = Join-Path ([IO.Path]::GetTempPath()) ('dutydesk-python-' + [Guid]::NewGuid().ToString() + '.exe')
            try {
                [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $download
                $signature = Get-AuthenticodeSignature -FilePath $download
                if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch '(^|,\s*)O=Python Software Foundation(,|$)') {
                    throw 'Python installer signature verification failed. The installer was not executed.'
                }
                $target = Split-Path -Parent $privatePython
                $arguments = @('/quiet', 'InstallAllUsers=0', 'Include_launcher=0', 'Include_test=0', 'Include_pip=1', 'PrependPath=0', 'Shortcuts=0', ('TargetDir="' + $target + '"'))
                $process = Start-Process -FilePath $download -ArgumentList $arguments -Wait -PassThru
                if ($process.ExitCode -notin @(0,3010)) { throw "Python installation failed with code $($process.ExitCode)." }
            } finally {
                if (Test-Path -LiteralPath $download) { Remove-Item -LiteralPath $download -Force }
            }
            $python = $privatePython
            if (-not (Test-Python $python)) { throw 'Python is not available after installation. Restart Windows and run this installer again.' }
        }

        Write-Host 'Preparing the DutyDesk Python environment...'
        & $python @prefixArgs -m venv (Join-Path $root '.venv-windows')
        if ($LASTEXITCODE -ne 0) { throw 'Could not create the Python environment. Extract DutyDesk to a writable folder and try again.' }
    }

    Write-Host 'Installing application dependencies...'
    & $venvPython -m pip install --disable-pip-version-check --no-input -r (Join-Path $root 'requirements.txt')
    if ($LASTEXITCODE -ne 0) { throw 'Dependency installation failed. Check your internet connection and install.log.' }

    Write-Host 'Checking the application...'
    # Use an isolated temporary database so validation never changes user records.
    @'
import pathlib
import tempfile
from app import app
t = tempfile.TemporaryDirectory()
app.config.update(DATABASE=str(pathlib.Path(t.name) / 'check.sqlite'), TESTING=True)
client = app.test_client()
assert client.get('/').status_code == 200
assert client.get('/api/officers').status_code == 200
print('Application check passed')
'@ | & $venvPython -
    if ($LASTEXITCODE -ne 0) { throw 'Application validation failed. See install.log.' }

    try {
        $shell = New-Object -ComObject WScript.Shell
        $desktop = [Environment]::GetFolderPath('Desktop')
        $shortcut = $shell.CreateShortcut((Join-Path $desktop 'DutyDesk.lnk'))
        $shortcut.TargetPath = Join-Path $root 'Start DutyDesk.bat'
        $shortcut.WorkingDirectory = $root
        $shortcut.Description = 'Officer profiles and monthly duty returns'
        $shortcut.Save()
        Write-Host 'Desktop shortcut created.'
    } catch {
        Write-Warning 'The desktop shortcut could not be created. Use Start DutyDesk.bat in this folder instead.'
    }
    Write-Host 'DutyDesk is installed. Keep this folder in place to preserve the launcher and your saved records.'
} catch {
    Write-Host ("INSTALLATION FAILED: " + $_.Exception.Message) -ForegroundColor Red
    if ($logStarted) { Stop-Transcript | Out-Null }
    exit 1
}
if ($logStarted) { Stop-Transcript | Out-Null }
exit 0
