@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
set "RUNTIME=%ROOT%x64.Debug"
set "CONFIG=%RUNTIME%\gpk_config.json"
set "LOGDIR=%RUNTIME%\lls_process_broker_test_logs"
set "BACKUP=%LOGDIR%\gpk_config.before-tests.json"

if not exist "%RUNTIME%\lls.win32.exe" (
	echo ERROR: Missing "%RUNTIME%\lls.win32.exe".
	goto :failed
)
if not exist "%RUNTIME%\gpk_cgi_rest.exe" (
	echo ERROR: Missing "%RUNTIME%\gpk_cgi_rest.exe".
	goto :failed
)
if not exist "%CONFIG%" (
	echo ERROR: Missing "%CONFIG%".
	goto :failed
)
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
copy /Y "%CONFIG%" "%BACKUP%" >nul

set "REQUEST_METHOD=GET"
set "QUERY_STRING=m=lls_process_broker_test"
set "CONTENT_LENGTH=0"
set "CONTENT_TYPE=text/plain"

echo.
echo [1/2] Child stdout round trip
powershell.exe -NoLogo -NoProfile -Command "$p=$env:CONFIG; $j=Get-Content -Raw -LiteralPath $p | ConvertFrom-Json; $j.application.brt.process.executable_path='C:/Windows/System32/cmd.exe'; $j.application.brt.process.command_line_app_name='cmd.exe'; $j.application.brt.process.command_line_params='/D /C echo LLS_PROCESS_BROKER_OK'; [IO.File]::WriteAllText($p, ($j | ConvertTo-Json -Depth 100), (New-Object Text.UTF8Encoding($false)))"
if errorlevel 1 goto :restore_failed

set "LLS_STDOUT=%LOGDIR%\echo_lls_stdout.txt"
set "LLS_STDERR=%LOGDIR%\echo_lls_stderr.txt"
for /f %%P in ('powershell.exe -NoLogo -NoProfile -Command "$q=[char]34; $cmd=$q+$q+($env:RUNTIME+'\lls.win32.exe')+$q+' 1>'+$q+$env:LLS_STDOUT+$q+' 2>'+$q+$env:LLS_STDERR+$q+$q; $p=Start-Process -FilePath 'cmd.exe' -ArgumentList '/d','/s','/c',$cmd -WorkingDirectory $env:RUNTIME -WindowStyle Hidden -PassThru; $p.Id"') do set "LLS_PID=%%P"
powershell.exe -NoLogo -NoProfile -Command "Start-Sleep -Seconds 10"

set "CGI_STDOUT=%LOGDIR%\echo_cgi_stdout.txt"
set "CGI_STDERR=%LOGDIR%\echo_cgi_stderr.txt"
powershell.exe -NoLogo -NoProfile -Command "$p=Start-Process -FilePath ($env:RUNTIME+'\gpk_cgi_rest.exe') -WorkingDirectory $env:RUNTIME -WindowStyle Hidden -RedirectStandardOutput $env:CGI_STDOUT -RedirectStandardError $env:CGI_STDERR -PassThru; if(-not $p.WaitForExit(15000)) { taskkill.exe /PID $p.Id /T /F | Out-Null; exit 124 }; exit $p.ExitCode"
set "ECHO_RESULT=%ERRORLEVEL%"
taskkill.exe /PID %LLS_PID% /T /F >nul 2>nul
echo CGI exit code: %ECHO_RESULT%
echo Response:
type "%CGI_STDOUT%"

echo.
echo [2/2] Recursive CGI relay
powershell.exe -NoLogo -NoProfile -Command "$p=$env:CONFIG; $j=Get-Content -Raw -LiteralPath $p | ConvertFrom-Json; $j.application.brt.process.executable_path='./gpk_cgi_rest.exe'; $j.application.brt.process.command_line_app_name='./gpk_cgi_rest.exe'; $j.application.brt.process.command_line_params=''; [IO.File]::WriteAllText($p, ($j | ConvertTo-Json -Depth 100), (New-Object Text.UTF8Encoding($false)))"
if errorlevel 1 goto :restore_failed

set "LLS_STDOUT=%LOGDIR%\recursive_lls_stdout.txt"
set "LLS_STDERR=%LOGDIR%\recursive_lls_stderr.txt"
for /f %%P in ('powershell.exe -NoLogo -NoProfile -Command "$q=[char]34; $cmd=$q+$q+($env:RUNTIME+'\lls.win32.exe')+$q+' 1>'+$q+$env:LLS_STDOUT+$q+' 2>'+$q+$env:LLS_STDERR+$q+$q; $p=Start-Process -FilePath 'cmd.exe' -ArgumentList '/d','/s','/c',$cmd -WorkingDirectory $env:RUNTIME -WindowStyle Hidden -PassThru; $p.Id"') do set "LLS_PID=%%P"
powershell.exe -NoLogo -NoProfile -Command "Start-Sleep -Seconds 10"

set "CGI_STDOUT=%LOGDIR%\recursive_cgi_stdout.txt"
set "CGI_STDERR=%LOGDIR%\recursive_cgi_stderr.txt"
for /f %%P in ('powershell.exe -NoLogo -NoProfile -Command "$q=[char]34; $cmd=$q+$q+($env:RUNTIME+'\gpk_cgi_rest.exe')+$q+' 1>'+$q+$env:CGI_STDOUT+$q+' 2>'+$q+$env:CGI_STDERR+$q+$q; $p=Start-Process -FilePath 'cmd.exe' -ArgumentList '/d','/s','/c',$cmd -WorkingDirectory $env:RUNTIME -WindowStyle Hidden -PassThru; $p.Id"') do set "CGI_PID=%%P"
powershell.exe -NoLogo -NoProfile -Command "Start-Sleep -Seconds 10"
echo Terminating the observed recursive process trees:
taskkill.exe /PID %CGI_PID% /T /F
taskkill.exe /PID %LLS_PID% /T /F
echo.
echo Tail of the LLS log. A second PAYLOAD request would prove the child relayed to BRT:
powershell.exe -NoLogo -NoProfile -Command "Get-Content -LiteralPath $env:LLS_STDERR -Tail 120"

copy /Y "%BACKUP%" "%CONFIG%" >nul
echo.
echo Tests finished. Original Debug configuration restored.
echo Logs: "%LOGDIR%"
if /I not "%~1"=="nopause" pause
exit /b 0

:restore_failed
copy /Y "%BACKUP%" "%CONFIG%" >nul
echo ERROR: Test setup failed. Original Debug configuration restored.
goto :failed

:failed
if /I not "%~1"=="nopause" pause
exit /b 1
