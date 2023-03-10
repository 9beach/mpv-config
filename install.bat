@ECHO OFF

CD /D "%~dp0"

SET /A "RAND = (%RANDOM% + 1) * (%RANDOM% + 1)"
SET MPV_CONF_PATH=%UserProfile%\AppData\Roaming\mpv
SET BACKUP_DIR=%UserProfile%\Downloads\mpv-%RAND%

MOVE %MPV_CONF_PATH% %BACKUP_DIR% 2> NULL && ECHO %BACKUP_DIR%

MKDIR %MPV_CONF_PATH%

XCOPY fonts %MPV_CONF_PATH%\fonts\
XCOPY script-opts %MPV_CONF_PATH%\script-opts\
XCOPY scripts %MPV_CONF_PATH%\scripts\
COPY input.conf %MPV_CONF_PATH%
COPY mpv.conf %MPV_CONF_PATH%
XCOPY %BACKUP_DIR%\watch_later %MPV_CONF_PATH%\watch_later\ 2> NULL
COPY %BACKUP_DIR%\.volume" %MPV_CONF_PATH% 2> NULL

IF NOT "%1" == "nvidia" GOTO :EOF

POWERSHELL -command "$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'; ((get-content mpv.conf) -replace '^# *nvidia *: *', '') > %MPV_CONF_PATH%\mpv.conf"

:EOF
