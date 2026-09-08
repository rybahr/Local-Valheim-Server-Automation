@echo off
setlocal EnableExtensions EnableDelayedExpansion

title ValheimShutdown

:: ============================================================
:: VALHEIM - GRACEFUL SHUTDOWN ALL SERVERS
::
:: PURPOSE:
::
::   1. Find all running valheim_server.exe processes.
::   2. Send CTRL+C to each server console.
::   3. Allow Valheim to save and shut down normally.
::   4. Wait until every valheim_server.exe process has exited.
::   5. Close leftover launcher CMD windows.
::
:: IMPORTANT:
::
::   Each Valheim launcher BAT should use a CMD title beginning:
::
::       ValheimServer-
::
::   Examples:
::
::       ValheimServer-AlmostPerfect
::       ValheimServer-Vanilla
::       ValheimServer-Test
::
::   The title contains NO spaces.
::
::   This script NEVER force-kills valheim_server.exe.
::
:: ============================================================


:: ============================================================
:: CONFIGURATION
:: ============================================================

set "PROCESS_NAME=valheim_server.exe"

:: Maximum amount of time to allow Valheim to save and exit.
set "SHUTDOWN_TIMEOUT=120"

:: Seconds between process checks.
set "CHECK_INTERVAL=2"

:: Time given to Windows to dispatch CTRL+C before the temporary
:: signaling process detaches.
set "SIGNAL_DELAY_MS=500"


:: ============================================================
:: TEMP FILE
:: ============================================================

set "PID_FILE=%TEMP%\ValheimShutdown_PIDs_%RANDOM%.txt"


:: ============================================================
:: HEADER
:: ============================================================

echo.
echo ============================================================
echo              VALHEIM SERVER SHUTDOWN
echo ============================================================
echo.
echo Shutdown method : CTRL+C
echo Timeout         : %SHUTDOWN_TIMEOUT% seconds
echo.


:: ============================================================
:: CHECK FOR RUNNING VALHEIM SERVERS
:: ============================================================

tasklist /FI "IMAGENAME eq %PROCESS_NAME%" /NH 2>NUL | find /I "%PROCESS_NAME%" >NUL

if errorlevel 1 goto NO_SERVERS


:: ============================================================
:: DISPLAY RUNNING SERVERS
:: ============================================================

echo Running Valheim servers:
echo.

tasklist /FI "IMAGENAME eq %PROCESS_NAME%"

echo.


:: ============================================================
:: BUILD PID LIST
::
:: TASKLIST output is written to a file first rather than using
:: a nested FOR /F command. This avoids CMD parsing problems.
:: ============================================================

tasklist /FI "IMAGENAME eq %PROCESS_NAME%" /FO CSV /NH > "%PID_FILE%"

if not exist "%PID_FILE%" goto PID_FILE_ERROR


:: ============================================================
:: SEND CTRL+C TO EACH SERVER
:: ============================================================

echo ------------------------------------------------------------
echo Sending CTRL+C to each Valheim server...
echo ------------------------------------------------------------
echo.

set /a SERVER_COUNT=0
set /a SIGNAL_FAILURES=0


for /F "usebackq tokens=2 delims=," %%P in ("%PID_FILE%") do (

    set "TARGET_PID=%%~P"

    if defined TARGET_PID (

        set /a SERVER_COUNT+=1

        echo [SERVER] PID !TARGET_PID!
        echo          Sending CTRL+C...

        set "VALHEIM_TARGET_PID=!TARGET_PID!"
        set "VALHEIM_SIGNAL_DELAY=%SIGNAL_DELAY_MS%"

        powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$f=Get-Content -LiteralPath '%~f0';$m=[Array]::IndexOf($f,':POWERSHELL');if($m -lt 0){exit 90};$s=($f[($m+1)..($f.Length-1)] -join [Environment]::NewLine);Invoke-Expression $s"

        set "RESULT=!ERRORLEVEL!"

        if "!RESULT!"=="0" (
            echo          [OK] CTRL+C sent successfully.
        ) else (
            echo          [ERROR] CTRL+C failed. Error code !RESULT!
            set /a SIGNAL_FAILURES+=1
        )

        echo.
    )
)


:: ============================================================
:: REMOVE INITIAL PID FILE
:: ============================================================

if exist "%PID_FILE%" del "%PID_FILE%" >NUL 2>&1


:: ============================================================
:: VERIFY AT LEAST ONE PID WAS PROCESSED
:: ============================================================

if !SERVER_COUNT! EQU 0 goto PID_PARSE_ERROR


:: ============================================================
:: WAIT FOR VALHEIM TO SHUT DOWN
:: ============================================================

echo ------------------------------------------------------------
echo Waiting for Valheim servers to save and shut down...
echo ------------------------------------------------------------
echo.

set /a ELAPSED=0


:WAIT_LOOP

tasklist /FI "IMAGENAME eq %PROCESS_NAME%" /NH 2>NUL | find /I "%PROCESS_NAME%" >NUL

if errorlevel 1 goto SHUTDOWN_SUCCESS

if !ELAPSED! GEQ %SHUTDOWN_TIMEOUT% goto SHUTDOWN_TIMEOUT


:: ============================================================
:: COUNT REMAINING SERVERS
:: ============================================================

tasklist /FI "IMAGENAME eq %PROCESS_NAME%" /FO CSV /NH > "%PID_FILE%"

set /a REMAINING=0


for /F "usebackq tokens=2 delims=," %%P in ("%PID_FILE%") do (

    set "CURRENT_PID=%%~P"

    if defined CURRENT_PID (
        set /a REMAINING+=1
    )
)


if exist "%PID_FILE%" del "%PID_FILE%" >NUL 2>&1


echo [WAIT] !REMAINING! server(s) still running - !ELAPSED!/%SHUTDOWN_TIMEOUT% seconds

timeout /t %CHECK_INTERVAL% /nobreak >NUL

set /a ELAPSED+=%CHECK_INTERVAL%

goto WAIT_LOOP



:: ============================================================
:: SHUTDOWN SUCCESS
:: ============================================================

:SHUTDOWN_SUCCESS

if exist "%PID_FILE%" del "%PID_FILE%" >NUL 2>&1

echo.
echo ============================================================
echo              VALHEIM SHUTDOWN SUCCESSFUL
echo ============================================================
echo.
echo All Valheim server processes have exited.
echo.
echo Servers processed : !SERVER_COUNT!
echo Signal failures   : !SIGNAL_FAILURES!
echo Shutdown time     : approximately !ELAPSED! seconds
echo.

goto CLEANUP_LAUNCHERS



:: ============================================================
:: NO RUNNING SERVERS
:: ============================================================

:NO_SERVERS

echo [INFO] No Valheim servers are currently running.
echo.

goto CLEANUP_LAUNCHERS



:: ============================================================
:: CLEAN UP LEFTOVER LAUNCHER WINDOWS
:: ============================================================

:CLEANUP_LAUNCHERS

echo ------------------------------------------------------------
echo Cleaning up Valheim launcher windows...
echo ------------------------------------------------------------
echo.


:: ============================================================
:: SAFETY CHECK
::
:: Never close launcher CMD windows while a Valheim server is
:: still running.
:: ============================================================

tasklist /FI "IMAGENAME eq %PROCESS_NAME%" /NH 2>NUL | find /I "%PROCESS_NAME%" >NUL

if not errorlevel 1 goto CLEANUP_ABORTED


:: ============================================================
:: CLOSE LEFTOVER VALHEIM LAUNCHER CMD WINDOWS
::
:: Launcher BAT files should use titles such as:
::
::     title ValheimServer-AlmostPerfect
::
::     title ValheimServer-Vanilla
::
::     title ValheimServer-Test
::
:: Any CMD window whose title begins with:
::
::     ValheimServer-
::
:: is closed here.
::
:: At this point all valheim_server.exe processes are already
:: gone, so this cannot interrupt Valheim's world-save process.
:: ============================================================

taskkill /FI "IMAGENAME eq cmd.exe" /FI "WINDOWTITLE eq ValheimServer-*" /F >NUL 2>&1

if errorlevel 1 goto NO_LAUNCHERS_FOUND


echo [OK] Leftover Valheim launcher windows closed.

goto CLEANUP_DONE



:: ============================================================
:: NO LAUNCHER WINDOWS FOUND
:: ============================================================

:NO_LAUNCHERS_FOUND

echo [INFO] No leftover Valheim launcher windows found.

goto CLEANUP_DONE



:: ============================================================
:: CLEANUP ABORTED
:: ============================================================

:CLEANUP_ABORTED

echo [WARNING] A Valheim server process is still running.
echo [WARNING] Launcher cleanup was skipped.

goto CLEANUP_DONE



:: ============================================================
:: CLEANUP COMPLETE
:: ============================================================

:CLEANUP_DONE

echo.
echo ============================================================
echo                 SHUTDOWN COMPLETE
echo ============================================================
echo.


exit /b 0



:: ============================================================
:: PID FILE ERROR
:: ============================================================

:PID_FILE_ERROR

echo.
echo ============================================================
echo                       ERROR
echo ============================================================
echo.
echo Unable to create the temporary Valheim PID list:
echo.
echo %PID_FILE%
echo.

pause
exit /b 1



:: ============================================================
:: PID PARSE ERROR
:: ============================================================

:PID_PARSE_ERROR

if exist "%PID_FILE%" del "%PID_FILE%" >NUL 2>&1

echo.
echo ============================================================
echo                       ERROR
echo ============================================================
echo.
echo Valheim was detected as running, but no server PID could
echo be extracted from TASKLIST.
echo.

pause
exit /b 1



:: ============================================================
:: SHUTDOWN TIMEOUT
:: ============================================================

:SHUTDOWN_TIMEOUT

if exist "%PID_FILE%" del "%PID_FILE%" >NUL 2>&1

echo.
echo ============================================================
echo                  SHUTDOWN TIMEOUT
echo ============================================================
echo.
echo One or more Valheim servers did not exit within
echo %SHUTDOWN_TIMEOUT% seconds.
echo.
echo No Valheim processes were force-killed.
echo.
echo Launcher windows will NOT be closed.
echo.
echo Remaining Valheim processes:
echo.

tasklist /FI "IMAGENAME eq %PROCESS_NAME%"

echo.
echo Inspect the remaining server console or server log before
echo terminating anything manually.
echo.
echo ============================================================
echo.

pause
exit /b 2



:: ============================================================
:: EMBEDDED POWERSHELL
::
:: Everything below this marker is read and executed by the
:: temporary PowerShell process used to send CTRL+C.
::
:: Normal CMD execution never reaches this section.
:: ============================================================

:POWERSHELL

$targetPid = [uint32]$env:VALHEIM_TARGET_PID

$signalDelay = [int]$env:VALHEIM_SIGNAL_DELAY


$source = @'
using System;
using System.Runtime.InteropServices;

public static class ValheimControl
{
    public const uint CTRL_C_EVENT = 0;


    [DllImport(
        "kernel32.dll",
        SetLastError = true
    )]
    public static extern bool FreeConsole();


    [DllImport(
        "kernel32.dll",
        SetLastError = true
    )]
    public static extern bool AttachConsole(
        uint dwProcessId
    );


    [DllImport(
        "kernel32.dll",
        SetLastError = true
    )]
    public static extern bool GenerateConsoleCtrlEvent(
        uint dwCtrlEvent,
        uint dwProcessGroupId
    );


    [DllImport(
        "kernel32.dll",
        SetLastError = true
    )]
    public static extern bool SetConsoleCtrlHandler(
        IntPtr HandlerRoutine,
        bool Add
    );


    public static void SendCtrlC(
        uint processId,
        int signalDelayMilliseconds
    )
    {
        // ----------------------------------------------------
        // Disconnect the temporary PowerShell process from
        // the shutdown BAT console.
        // ----------------------------------------------------

        FreeConsole();


        // ----------------------------------------------------
        // Attach directly to the console containing the target
        // valheim_server.exe process.
        // ----------------------------------------------------

        if (!AttachConsole(processId))
        {
            Environment.Exit(10);
            return;
        }


        // ----------------------------------------------------
        // Prevent the temporary PowerShell process from
        // terminating when it generates CTRL+C.
        // ----------------------------------------------------

        if (
            !SetConsoleCtrlHandler(
                IntPtr.Zero,
                true
            )
        )
        {
            FreeConsole();

            Environment.Exit(11);

            return;
        }


        // ----------------------------------------------------
        // Generate an actual CTRL+C console event.
        // ----------------------------------------------------

        if (
            !GenerateConsoleCtrlEvent(
                CTRL_C_EVENT,
                0
            )
        )
        {
            FreeConsole();

            Environment.Exit(12);

            return;
        }


        // ----------------------------------------------------
        // Allow Windows time to dispatch CTRL+C to processes
        // sharing the attached console.
        // ----------------------------------------------------

        System.Threading.Thread.Sleep(
            signalDelayMilliseconds
        );


        // ----------------------------------------------------
        // Detach from the Valheim console.
        // ----------------------------------------------------

        FreeConsole();


        // ----------------------------------------------------
        // Exit immediately.
        //
        // Do not return to PowerShell after FreeConsole().
        // PowerShell may otherwise attempt to use invalid
        // console handles.
        // ----------------------------------------------------

        Environment.Exit(0);
    }
}
'@


Add-Type -TypeDefinition $source


[ValheimControl]::SendCtrlC(
    $targetPid,
    $signalDelay
)