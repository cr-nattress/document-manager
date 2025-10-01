@echo off
REM Batch script to generate images from Mermaid diagrams
REM Requires: Node.js and @mermaid-js/mermaid-cli installed globally

echo.
echo === Mermaid Diagram to Image Generator ===
echo.

REM Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Node.js not found!
    echo Please install Node.js from https://nodejs.org
    echo.
    pause
    exit /b 1
)

REM Check if mmdc is installed
where mmdc >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: mermaid-cli (mmdc) not found!
    echo Please install it with: npm install -g @mermaid-js/mermaid-cli
    echo.
    pause
    exit /b 1
)

echo Found Node.js and mermaid-cli
echo.

REM Run the Node.js script
node "%~dp0generate-images.js"

echo.
pause
