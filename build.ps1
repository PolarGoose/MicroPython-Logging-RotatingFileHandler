Function Info($msg) {
    Write-Host -ForegroundColor DarkGreen "`nINFO: $msg`n"
}

Function Error($msg) {
  Write-Host `n`n
  Write-Error $msg
  exit 1
}

Function CheckReturnCodeOfPreviousCommand($msg) {
  if(-Not $?) {
    Error "${msg}. Error code: $LastExitCode"
  }
}

Function GetVersion() {
    $gitCommand = Get-Command -ErrorAction Stop -Name git

    $tag = & $gitCommand describe --exact-match --tags HEAD
    if(-Not $?) {
        $tag = "v0.0-dev"
        Info "The commit is not tagged. Use '$tag' as a version instead"
    }

    $commitHash = & $gitCommand rev-parse --short HEAD
    CheckReturnCodeOfPreviousCommand "Failed to get git commit hash"

    return "$tag~$commitHash"
}

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = $PSScriptRoot
$buildDir = "$root/build"
$version = GetVersion
$gitCommand = Get-Command -Name git
$pipCommand = Get-Command -Name pip

New-Item "$buildDir" -Force -ItemType "directory" > $null

Info "Install pytest"
& $pipCommand install pytest

Info "Run tests"
$pytestCommand = Get-Command -Name pytest
& $pytestCommand "$root/src/test.py"
CheckReturnCodeOfPreviousCommand "Tests failed"

Info "Download micropython"
Invoke-WebRequest -Uri https://github.com/PolarGoose/MicroPython-for-Windows/releases/download/v1.23.0/micropython.zip -OutFile "$buildDir/micropython.zip"
Expand-Archive -Path "$buildDir/micropython.zip" -DestinationPath $buildDir -Force

Info "Download Micropython package: logging"
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/micropython/micropython-lib/master/python-stdlib/logging/logging.py" `
  -OutFile "$buildDir/logging.py"

Info "Create a mock of _thread module"
Set-Content "$buildDir/_thread.py" @"
class DummyLock():
    def __enter__(self):
        return self
    def __exit__(self, exception_type, exception_value, exception_traceback):
        pass


def allocate_lock():
    return DummyLock()
"@

Info "Run Micropython test"
Push-Location $buildDir
try {
  $env:MICROPYPATH = "$buildDir"
  & "$buildDir/micropython.exe" "$root/src/micropython_test.py"
  CheckReturnCodeOfPreviousCommand "Example failed"
} finally {
  Pop-Location
}

Info "Copy the src files to the publish directory"
New-Item "$buildDir/publish" -Force -ItemType "directory" > $null
Copy-Item -Path "$root/src/rotating_file_handler.py" -Destination "$buildDir/publish"

Info "Insert verion $version into the source file"
$content = [System.IO.File]::ReadAllText("$buildDir/publish/rotating_file_handler.py").Replace( `
  "rotating_file_handler_version = `"v0.0-dev`"", `
  "rotating_file_handler_version = `"$version`"")
[System.IO.File]::WriteAllText("$buildDir/publish/rotating_file_handler.py", $content)
