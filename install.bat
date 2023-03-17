@ECHO OFF

CD /D "%~dp0"

SET /A "RAND = (%RANDOM% + 1) * (%RANDOM% + 1)"
IF "%MPV_CONF_PATH%"=="" SET MPV_CONF_PATH=%UserProfile%\AppData\Roaming\mpv
SET BACKUP_DIR=%UserProfile%\Downloads\mpv-%RAND%

IF EXIST "%MPV_CONF_PATH%" MOVE "%MPV_CONF_PATH%" "%BACKUP_DIR%" && ECHO %BACKUP_DIR%

MKDIR "%MPV_CONF_PATH%"

XCOPY fonts "%MPV_CONF_PATH%\fonts\"
XCOPY script-opts "%MPV_CONF_PATH%\script-opts\"
XCOPY scripts "%MPV_CONF_PATH%\scripts\"
COPY input.conf "%MPV_CONF_PATH%"
COPY mpv.conf "%MPV_CONF_PATH%"
IF EXIST "%BACKUP_DIR%\watch_later" MOVE "%BACKUP_DIR%\watch_later" "%MPV_CONF_PATH%\watch_later"
IF EXIST "%BACKUP_DIR%\.volume" COPY "%BACKUP_DIR%\.volume" "%MPV_CONF_PATH%"
IF NOT "%1" == "nvidia" GOTO :EOF
POWERSHELL -command "$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'; ((get-content mpv.conf) -replace '^# *nvidia *: *', '') > \"%MPV_CONF_PATH%\mpv.conf\""
:EOF
