# PowerShell Script to Generate Images from Mermaid Diagrams
# Requires: Node.js and @mermaid-js/mermaid-cli installed globally
# Install: npm install -g @mermaid-js/mermaid-cli

Write-Host "=== Mermaid Diagram to Image Generator ===" -ForegroundColor Cyan
Write-Host ""

# Check if mmdc is installed
$mmdcInstalled = Get-Command mmdc -ErrorAction SilentlyContinue
if (-not $mmdcInstalled) {
    Write-Host "ERROR: mermaid-cli (mmdc) not found!" -ForegroundColor Red
    Write-Host "Please install it with: npm install -g @mermaid-js/mermaid-cli" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "Found mmdc: $($mmdcInstalled.Source)" -ForegroundColor Green
Write-Host ""

# Set the diagrams directory
$diagramsDir = $PSScriptRoot

# Function to extract mermaid blocks from markdown
function Extract-MermaidBlocks {
    param (
        [string]$FilePath,
        [string]$OutputDir
    )

    $content = Get-Content -Path $FilePath -Raw
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)

    # Find all mermaid code blocks (must start at line beginning)
    $pattern = '(?m)^```mermaid\s*\r?\n([\s\S]*?)^```'
    $matches = [regex]::Matches($content, $pattern)

    # Filter to only valid mermaid diagrams (skip empty or invalid blocks)
    $validMatches = @()
    foreach ($match in $matches) {
        $block = $match.Groups[1].Value.Trim()
        # Check if it's a valid mermaid diagram type
        if ($block.Length -gt 10 -and $block -match '^(graph|flowchart|sequenceDiagram|classDiagram|stateDiagram|erDiagram|gantt|pie|gitGraph|mindmap)') {
            $validMatches += $match
        }
    }

    if ($validMatches.Count -eq 0) {
        Write-Host "  No valid mermaid diagrams found" -ForegroundColor Yellow
        return
    }

    Write-Host "  Found $($validMatches.Count) valid mermaid diagram(s)" -ForegroundColor Green

    $index = 1
    foreach ($match in $validMatches) {
        $mermaidCode = $match.Groups[1].Value.Trim()

        # Create temporary mermaid file
        $tempMmdFile = Join-Path $OutputDir "$fileName-temp-$index.mmd"
        $outputPngFile = Join-Path $OutputDir "$fileName-$index.png"

        # Write mermaid code to temp file
        Set-Content -Path $tempMmdFile -Value $mermaidCode

        # Generate PNG using mmdc
        Write-Host "    Generating: $fileName-$index.png" -ForegroundColor Cyan

        try {
            & mmdc -i $tempMmdFile -o $outputPngFile -b transparent -w 2048 -H 2048

            if (Test-Path $outputPngFile) {
                Write-Host "    ✓ Generated: $fileName-$index.png" -ForegroundColor Green
            } else {
                Write-Host "    ✗ Failed to generate: $fileName-$index.png" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "    ✗ Error: $_" -ForegroundColor Red
        }
        finally {
            # Clean up temp file
            if (Test-Path $tempMmdFile) {
                Remove-Item $tempMmdFile -Force
            }
        }

        $index++
    }

    Write-Host ""
}

# Process all markdown files
$markdownFiles = Get-ChildItem -Path $diagramsDir -Filter "*.md" | Where-Object { $_.Name -ne "README.md" }

Write-Host "Processing $($markdownFiles.Count) markdown files..." -ForegroundColor Cyan
Write-Host ""

foreach ($file in $markdownFiles) {
    Write-Host "Processing: $($file.Name)" -ForegroundColor Cyan
    Extract-MermaidBlocks -FilePath $file.FullName -OutputDir $diagramsDir
}

Write-Host "=== Generation Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Images generated in: $diagramsDir" -ForegroundColor Green
