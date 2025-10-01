#!/usr/bin/env node

/**
 * Node.js Script to Generate Images from Mermaid Diagrams
 * Requires: @mermaid-js/mermaid-cli installed globally or locally
 * Install: npm install -g @mermaid-js/mermaid-cli
 *
 * Usage: node generate-images.js
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

console.log('\n=== Mermaid Diagram to Image Generator ===\n');

// Check if mmdc is installed
try {
  execSync('mmdc --version', { stdio: 'pipe' });
  console.log('✓ Found mermaid-cli (mmdc)\n');
} catch (error) {
  console.error('✗ ERROR: mermaid-cli (mmdc) not found!');
  console.error('Please install it with: npm install -g @mermaid-js/mermaid-cli\n');
  process.exit(1);
}

const diagramsDir = __dirname;

/**
 * Extract all mermaid code blocks from a markdown file
 */
function extractMermaidBlocks(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const fileName = path.basename(filePath, '.md');

  // Regex to find mermaid code blocks
  // Must start at beginning of line and have actual diagram content
  const mermaidRegex = /^```mermaid\s*\n([\s\S]*?)^```/gm;
  const matches = [];
  let match;

  while ((match = mermaidRegex.exec(content)) !== null) {
    const block = match[1].trim();

    // Skip empty blocks or blocks that are just comments/whitespace
    if (block.length > 10 && /^(graph|flowchart|sequenceDiagram|classDiagram|stateDiagram|erDiagram|gantt|pie|gitGraph|mindmap)/.test(block)) {
      matches.push(block);
    }
  }

  return { fileName, blocks: matches };
}

/**
 * Generate PNG image from mermaid code
 */
function generateImage(mermaidCode, outputPath) {
  const tempMmdFile = outputPath.replace('.png', '.mmd');

  try {
    // Write mermaid code to temp file
    fs.writeFileSync(tempMmdFile, mermaidCode, 'utf8');

    // Generate PNG using mmdc
    execSync(
      `mmdc -i "${tempMmdFile}" -o "${outputPath}" -b transparent -w 2048 -H 2048`,
      { stdio: 'pipe' }
    );

    // Check if file was created
    if (fs.existsSync(outputPath)) {
      return true;
    }
    return false;
  } catch (error) {
    console.error(`    ✗ Error: ${error.message}`);
    return false;
  } finally {
    // Clean up temp file
    if (fs.existsSync(tempMmdFile)) {
      fs.unlinkSync(tempMmdFile);
    }
  }
}

/**
 * Process all markdown files in the diagrams directory
 */
function processMarkdownFiles() {
  const files = fs.readdirSync(diagramsDir)
    .filter(file => file.endsWith('.md') && file !== 'README.md')
    .map(file => path.join(diagramsDir, file));

  console.log(`Processing ${files.length} markdown files...\n`);

  let totalGenerated = 0;
  let totalFailed = 0;

  files.forEach(filePath => {
    const fileName = path.basename(filePath);
    console.log(`Processing: ${fileName}`);

    const { fileName: baseFileName, blocks } = extractMermaidBlocks(filePath);

    if (blocks.length === 0) {
      console.log('  No mermaid diagrams found\n');
      return;
    }

    console.log(`  Found ${blocks.length} mermaid diagram(s)`);

    blocks.forEach((block, index) => {
      const outputFileName = `${baseFileName}-${index + 1}.png`;
      const outputPath = path.join(diagramsDir, outputFileName);

      console.log(`    Generating: ${outputFileName}`);

      if (generateImage(block, outputPath)) {
        console.log(`    ✓ Generated: ${outputFileName}`);
        totalGenerated++;
      } else {
        console.log(`    ✗ Failed: ${outputFileName}`);
        totalFailed++;
      }
    });

    console.log('');
  });

  return { totalGenerated, totalFailed };
}

// Main execution
try {
  const { totalGenerated, totalFailed } = processMarkdownFiles();

  console.log('=== Generation Complete ===\n');
  console.log(`✓ Successfully generated: ${totalGenerated} images`);
  if (totalFailed > 0) {
    console.log(`✗ Failed to generate: ${totalFailed} images`);
  }
  console.log(`\nImages saved in: ${diagramsDir}\n`);
} catch (error) {
  console.error('\n✗ Unexpected error:', error.message);
  process.exit(1);
}
