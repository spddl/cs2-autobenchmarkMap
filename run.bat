@echo off

SET filename=benchmark

:loop
cls

go build -buildvcs=false -o %filename%.exe

@REM IF %ERRORLEVEL% EQU 0 %filename%.exe
IF %ERRORLEVEL% EQU 0 %filename%.exe -name demotest

pause
goto loop