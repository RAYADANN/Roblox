@echo off
setlocal EnableExtensions

rem Workspace copy: Cursor expands .\mcp.bat to <workspace>\mcp.bat
call "%USERPROFILE%\.cursor\roblox-studio-mcp.bat" %*
exit /b %ERRORLEVEL%
