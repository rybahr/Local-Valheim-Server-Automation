@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: ============================================================
:: VALHEIM SERVER LAUNCHER
:: ============================================================

:: ============================================================
:: CONFIGURATION
:: ============================================================

set "SERVER_PATH=C:\Program Files (x86)\Steam\steamapps\common\Valheim dedicated server"
set "SERVER_EXE=%SERVER_PATH%\valheim_server.exe"

set "SERVER_NAME=YOURSERVERNAME"
set "WORLD_NAME=YOURSERVERNAME"
set "SERVER_PASSWORD=YOURPASSWORD"

:: If you plan on having multiple servers running, you'll need to increment the port accordingly, i.e. 3456, 4456, etc
set "SERVER_PORT=2456"

:: Keep this unique and do not use spaces.
set "SERVER_WINDOW_TITLE=YOURSERVERNAMEServerWindow"

set "SERVER_LOG=C:\ValheimLogs\YOURSERVERNAMElog.txt"
set "TASK_LOG=C:\ValheimLogs\YOURSERVERNAMETaskSchedulerLog.txt"

set "DISCORD_WEBHOOK=YOURDISCORDWEBHOOK"

:: Join-code polling
set "JOIN_CODE_TIMEOUT=60"
set "JOIN_CODE_CHECK_INTERVAL=5"

:: Required by Valheim
set "SteamAppId=892970"

:: ============================================================
:: BEGIN TASK LOGGING
:: ============================================================

echo [%date% %time%] - Script started. > "%TASK_LOG%"

:: ============================================================
:: CHECK IF SERVER IS ALREADY RUNNING
:: ============================================================

tasklist /v /fi "imagename eq valheim_server.exe" 2>nul | findstr /i /c:"%SERVER_WINDOW_TITLE%" >nul

if not errorlevel 1 (
    echo [%date% %time%] - Server is already running. >> "%TASK_LOG%"
    goto End
)

echo [%date% %time%] - Server is not running. Starting server. >> "%TASK_LOG%"

:: ============================================================
:: CLEAR SERVER LOG
:: ============================================================

> "%SERVER_LOG%" echo.

echo [%date% %time%] - Server log cleared: %SERVER_LOG% >> "%TASK_LOG%"

:: ============================================================
:: PASS SERVER VALUES TO EMBEDDED POWERSHELL
:: ============================================================

set "VH_EXE=%SERVER_EXE%"
set "VH_WORKDIR=%SERVER_PATH%"
set "VH_LOG=%SERVER_LOG%"

set "VH_SERVER_NAME=%SERVER_NAME%"
set "VH_WORLD_NAME=%WORLD_NAME%"
set "VH_PASSWORD=%SERVER_PASSWORD%"
set "VH_PORT=%SERVER_PORT%"
set "VH_WINDOW_TITLE=%SERVER_WINDOW_TITLE%"

:: ============================================================
:: START VALHEIM
:: ============================================================

echo [%date% %time%] - Launching Valheim server. >> "%TASK_LOG%"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$f=Get-Content -LiteralPath '%~f0';$m=[Array]::IndexOf($f,':POWERSHELL');if($m -lt 0){exit 90};$s=($f[($m+1)..($f.Length-1)] -join [Environment]::NewLine);Invoke-Expression $s"

set "LAUNCH_RESULT=%ERRORLEVEL%"

if not "%LAUNCH_RESULT%"=="0" (
    echo [%date% %time%] - ERROR: Valheim failed to launch. Error code %LAUNCH_RESULT%. >> "%TASK_LOG%"
    goto End
)

echo [%date% %time%] - Valheim process launched successfully. >> "%TASK_LOG%"

:: ============================================================
:: WAIT FOR JOIN CODE
:: ============================================================

echo [%date% %time%] - Waiting for crossplay join code. >> "%TASK_LOG%"

set "JOIN_CODE_LINE="
set "FINAL_JOIN_CODE="
set /a ELAPSED=0

:WaitForJoinCode

set "JOIN_CODE_LINE="

for /f "delims=" %%i in ('findstr /i /c:"registered with join code" "%SERVER_LOG%" 2^>nul') do (
    set "JOIN_CODE_LINE=%%i"
)

if defined JOIN_CODE_LINE goto ProcessCode

if !ELAPSED! GEQ %JOIN_CODE_TIMEOUT% (
    echo [%date% %time%] - No join code found within %JOIN_CODE_TIMEOUT% seconds. >> "%TASK_LOG%"
    goto End
)

timeout /t %JOIN_CODE_CHECK_INTERVAL% /nobreak >nul

set /a "ELAPSED=ELAPSED+JOIN_CODE_CHECK_INTERVAL"

goto WaitForJoinCode

:: ============================================================
:: PROCESS JOIN CODE
:: ============================================================

:ProcessCode

echo [%date% %time%] - Matching log line found: !JOIN_CODE_LINE! >> "%TASK_LOG%"

:: Extract the last space-delimited item from the matching line.
for %%A in (!JOIN_CODE_LINE!) do (
    set "FINAL_JOIN_CODE=%%A"
)

:: Strip punctuation commonly found at the end of the log line.
set "FINAL_JOIN_CODE=!FINAL_JOIN_CODE:.=!"
set "FINAL_JOIN_CODE=!FINAL_JOIN_CODE:,=!"
set "FINAL_JOIN_CODE=!FINAL_JOIN_CODE:;=!"

echo [%date% %time%] - Extracted join code: !FINAL_JOIN_CODE! >> "%TASK_LOG%"

:: ============================================================
:: VALIDATE JOIN CODE
:: ============================================================

echo(!FINAL_JOIN_CODE!| findstr /r /x "[0-9][0-9][0-9][0-9][0-9][0-9]" >nul

if errorlevel 1 (
    echo [%date% %time%] - ERROR: Invalid join code extracted: !FINAL_JOIN_CODE! >> "%TASK_LOG%"
    set "FINAL_JOIN_CODE="
    goto End
)

echo [%date% %time%] - Valid join code found: !FINAL_JOIN_CODE! >> "%TASK_LOG%"

:: ============================================================
:: SEND JOIN CODE TO DISCORD
:: ============================================================

echo [%date% %time%] - Sending join code to Discord. >> "%TASK_LOG%"

curl.exe -s -X POST ^
    -H "Content-Type: application/json" ^
    -d "{\"content\": \"The new Valheim server join code is: !FINAL_JOIN_CODE!\"}" ^
    "%DISCORD_WEBHOOK%" >nul 2>&1

if errorlevel 1 (
    echo [%date% %time%] - ERROR: Discord webhook failed. >> "%TASK_LOG%"
) else (
    echo [%date% %time%] - Join code sent to Discord: !FINAL_JOIN_CODE! >> "%TASK_LOG%"
)

:: ============================================================
:: FINISH
:: ============================================================

:End

echo [%date% %time%] - Script execution completed. >> "%TASK_LOG%"

endlocal
exit /b 0

:: ============================================================
:: EMBEDDED POWERSHELL / C#
::
:: Launches valheim_server.exe directly with:
::
::   - its own console window
::   - a custom window title
::   - stdout redirected to SERVER_LOG
::   - stderr redirected to SERVER_LOG
::
:: This avoids putting CMD between the shutdown script and
:: Valheim, preventing:
::
::   Terminate batch job (Y/N)?
:: ============================================================

:POWERSHELL

$exe         = $env:VH_EXE
$workDir     = $env:VH_WORKDIR
$logFile     = $env:VH_LOG
$serverName  = $env:VH_SERVER_NAME
$worldName   = $env:VH_WORLD_NAME
$password    = $env:VH_PASSWORD
$port        = $env:VH_PORT
$windowTitle = $env:VH_WINDOW_TITLE

$arguments = (
    '-nographics ' +
    '-batchmode ' +
    '-name "' + $serverName + '" ' +
    '-port ' + $port + ' ' +
    '-world "' + $worldName + '" ' +
    '-password "' + $password + '" ' +
    '-crossplay'
)

$source = @'
using System;
using System.Runtime.InteropServices;

public static class ValheimLauncher
{
    const uint FILE_APPEND_DATA       = 0x00000004;
    const uint GENERIC_READ           = 0x80000000;

    const uint FILE_SHARE_READ        = 0x00000001;
    const uint FILE_SHARE_WRITE       = 0x00000002;

    const uint OPEN_ALWAYS            = 4;
    const uint FILE_ATTRIBUTE_NORMAL  = 0x00000080;

    const uint CREATE_NEW_CONSOLE     = 0x00000010;
    const uint STARTF_USESTDHANDLES   = 0x00000100;

    static readonly IntPtr INVALID_HANDLE_VALUE =
        new IntPtr(-1);


    [StructLayout(LayoutKind.Sequential)]
    public struct SECURITY_ATTRIBUTES
    {
        public int nLength;
        public IntPtr lpSecurityDescriptor;

        [MarshalAs(UnmanagedType.Bool)]
        public bool bInheritHandle;
    }


    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct STARTUPINFO
    {
        public uint cb;
        public string lpReserved;
        public string lpDesktop;
        public string lpTitle;

        public uint dwX;
        public uint dwY;
        public uint dwXSize;
        public uint dwYSize;
        public uint dwXCountChars;
        public uint dwYCountChars;
        public uint dwFillAttribute;

        public uint dwFlags;

        public ushort wShowWindow;
        public ushort cbReserved2;

        public IntPtr lpReserved2;

        public IntPtr hStdInput;
        public IntPtr hStdOutput;
        public IntPtr hStdError;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct PROCESS_INFORMATION
    {
        public IntPtr hProcess;
        public IntPtr hThread;

        public uint dwProcessId;
        public uint dwThreadId;
    }

    [DllImport(
        "kernel32.dll",
        CharSet = CharSet.Unicode,
        SetLastError = true)]
    static extern IntPtr CreateFile(
        string lpFileName,
        uint dwDesiredAccess,
        uint dwShareMode,
        ref SECURITY_ATTRIBUTES lpSecurityAttributes,
        uint dwCreationDisposition,
        uint dwFlagsAndAttributes,
        IntPtr hTemplateFile
    );

    [DllImport(
        "kernel32.dll",
        CharSet = CharSet.Unicode,
        SetLastError = true)]
    static extern bool CreateProcess(
        string lpApplicationName,
        string lpCommandLine,
        IntPtr lpProcessAttributes,
        IntPtr lpThreadAttributes,
        bool bInheritHandles,
        uint dwCreationFlags,
        IntPtr lpEnvironment,
        string lpCurrentDirectory,
        ref STARTUPINFO lpStartupInfo,
        out PROCESS_INFORMATION lpProcessInformation
    );

    [DllImport(
        "kernel32.dll",
        SetLastError = true)]
    static extern bool CloseHandle(
        IntPtr hObject
    );

    public static int Start(
        string exe,
        string arguments,
        string workingDirectory,
        string logFile,
        string windowTitle)
    {
        SECURITY_ATTRIBUTES sa =
            new SECURITY_ATTRIBUTES();

        sa.nLength =
            Marshal.SizeOf(typeof(SECURITY_ATTRIBUTES));

        sa.lpSecurityDescriptor =
            IntPtr.Zero;

        sa.bInheritHandle =
            true;


        IntPtr logHandle =
            CreateFile(
                logFile,
                FILE_APPEND_DATA,
                FILE_SHARE_READ | FILE_SHARE_WRITE,
                ref sa,
                OPEN_ALWAYS,
                FILE_ATTRIBUTE_NORMAL,
                IntPtr.Zero
            );


        if (logHandle == INVALID_HANDLE_VALUE)
        {
            return Marshal.GetLastWin32Error();
        }


        IntPtr inputHandle =
            CreateFile(
                "NUL",
                GENERIC_READ,
                FILE_SHARE_READ | FILE_SHARE_WRITE,
                ref sa,
                OPEN_ALWAYS,
                FILE_ATTRIBUTE_NORMAL,
                IntPtr.Zero
            );


        if (inputHandle == INVALID_HANDLE_VALUE)
        {
            int error =
                Marshal.GetLastWin32Error();

            CloseHandle(logHandle);

            return error;
        }

        STARTUPINFO si =
            new STARTUPINFO();

        si.cb =
            (uint)Marshal.SizeOf(typeof(STARTUPINFO));

        si.lpTitle =
            windowTitle;

        si.dwFlags =
            STARTF_USESTDHANDLES;

        si.hStdInput =
            inputHandle;

        si.hStdOutput =
            logHandle;

        si.hStdError =
            logHandle;


        PROCESS_INFORMATION pi;


        string commandLine =
            "\"" + exe + "\" " + arguments;


        bool success =
            CreateProcess(
                exe,
                commandLine,
                IntPtr.Zero,
                IntPtr.Zero,
                true,
                CREATE_NEW_CONSOLE,
                IntPtr.Zero,
                workingDirectory,
                ref si,
                out pi
            );


        int result;

        if (!success)
        {
            result =
                Marshal.GetLastWin32Error();
        }
        else
        {
            result = 0;

            CloseHandle(pi.hThread);
            CloseHandle(pi.hProcess);
        }


        CloseHandle(inputHandle);
        CloseHandle(logHandle);

        return result;
    }
}
'@


Add-Type -TypeDefinition $source


$result = [ValheimLauncher]::Start(
    $exe,
    $arguments,
    $workDir,
    $logFile,
    $windowTitle
)


exit $result