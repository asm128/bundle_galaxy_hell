@echo off

set "directories=.\obj .\x64.Debug .\x64.Release .\Win32.Debug .\Win32.Release .\gpk_games\.vs .\gpk\.vs"

for %%i in (%directories%) do (
    rd /s /q "%%i"
)