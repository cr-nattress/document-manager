# Image Generation Tools - Summary

**Created**: 2025-09-30
**Purpose**: Convert Mermaid diagrams to PNG images

---

## 📦 What Was Created

### 1. Scripts for Image Generation

| File | Platform | Description |
|------|----------|-------------|
| `generate-images.js` | Cross-platform | Node.js script (main implementation) |
| `generate-images.bat` | Windows | Batch file (double-click to run) |
| `generate-images.ps1` | Windows | PowerShell script (advanced) |
| `generate-images.sh` | Mac/Linux | Bash shell script |
| `IMAGE-GENERATION-GUIDE.md` | All | Comprehensive usage guide |

### 2. How They Work

All scripts:
1. **Scan** all `.md` files in the diagrams folder (except README.md)
2. **Extract** mermaid code blocks using regex pattern: `` ```mermaid ... ``` ``
3. **Generate** PNG images using `mmdc` (mermaid-cli)
4. **Name** images as `{filename}-{index}.png`
5. **Clean up** temporary files

---

## 🚀 Quick Start

### Installation (One-time setup)

```bash
# Install Node.js from https://nodejs.org
# Then install mermaid-cli globally:
npm install -g @mermaid-js/mermaid-cli

# Verify installation:
mmdc --version
```

### Running the Scripts

**Windows** (easiest):
```cmd
double-click generate-images.bat
```

**Mac/Linux**:
```bash
chmod +x generate-images.sh
./generate-images.sh
```

**Any platform**:
```bash
node generate-images.js
```

---

## 📊 Expected Output

Based on the current 9 diagram files, you should get approximately **33 PNG images**:

### Breakdown by File

| Source File | Images | Description |
|-------------|--------|-------------|
| `01-system-architecture.md` | 1 | Main architecture diagram |
| `02-database-erd.md` | 1 | Entity relationship diagram |
| `03-sequence-diagrams.md` | 7 | Upload, download, navigation, search, move, create, edit |
| `04-component-diagram.md` | 2 | Frontend and backend components |
| `05-data-flow-diagram.md` | 5 | Upload, download, search, tree, transformation |
| `06-state-diagrams.md` | 6 | Document, folder, search, upload, cache, API |
| `07-user-flow-diagrams.md` | 6 | Upload, search, create, edit, mobile, onboarding |
| `08-deployment-diagram.md` | 3 | Azure architecture, topology, CI/CD |
| `09-api-map.md` | 2 | Endpoint tree and details |
| **Total** | **~33** | **All diagrams as PNG images** |

### Image Specifications

- **Format**: PNG
- **Background**: Transparent
- **Max Dimensions**: 2048x2048 pixels
- **Quality**: High-resolution, suitable for presentations and documentation

---

## 🔧 Customization

### Change Image Settings

Edit the `mmdc` command in any script file:

```javascript
// Current settings (in generate-images.js)
mmdc -i input.mmd -o output.png -b transparent -w 2048 -H 2048

// Available options:
// -b : Background color (transparent, white, #RRGGBB)
// -w : Max width in pixels
// -H : Max height in pixels
// -t : Theme (default, forest, dark, neutral)
// -s : Scale factor (1, 2, 3)
// -f : Output format (png, svg, pdf)
```

### Examples

**White background**:
```bash
-b white
```

**Dark theme**:
```bash
-t dark
```

**SVG output**:
```bash
-f svg -o output.svg
```

**Higher resolution**:
```bash
-w 4096 -H 4096 -s 2
```

---

## ⚠️ Important Notes

### ✅ DO

- **Keep markdown files as source of truth** - edit diagrams in `.md` files
- **Regenerate images** when diagrams change
- **Version control markdown files** - they're text-based and diff-friendly
- **Use generated images** for presentations, wikis, PDFs

### ❌ DON'T

- **Don't edit PNG images directly** - changes will be lost on regeneration
- **Don't commit images to git** unless necessary - they're binary and large
- **Don't manually create .mmd files** - scripts handle this automatically

---

## 🐛 Common Issues

### "mmdc not found"

**Solution**: Install mermaid-cli
```bash
npm install -g @mermaid-js/mermaid-cli
```

### "Chromium download failed"

**Solution**: Install Puppeteer separately
```bash
npm install -g puppeteer
```

### "Permission denied" (Mac/Linux)

**Solution**: Make script executable
```bash
chmod +x generate-images.sh
```

### Images cut off or too small

**Solution**: Increase dimensions in script
```javascript
-w 4096 -H 4096
```

For more troubleshooting, see [IMAGE-GENERATION-GUIDE.md](./IMAGE-GENERATION-GUIDE.md)

---

## 📁 File Structure After Generation

```
diagrams/
├── 01-system-architecture.md          (source)
├── 01-system-architecture-1.png       (generated)
├── 02-database-erd.md                 (source)
├── 02-database-erd-1.png              (generated)
├── 03-sequence-diagrams.md            (source)
├── 03-sequence-diagrams-1.png         (generated)
├── 03-sequence-diagrams-2.png         (generated)
├── ... (all other generated images)
├── generate-images.js                 (script)
├── generate-images.bat                (script)
├── generate-images.ps1                (script)
├── generate-images.sh                 (script)
├── IMAGE-GENERATION-GUIDE.md          (guide)
├── GENERATION-SUMMARY.md              (this file)
└── README.md                          (index)
```

---

## 🎯 Use Cases

### When to Generate Images

1. **For presentations** - PowerPoint, Google Slides
2. **For documentation sites** - That don't support Mermaid
3. **For PDFs** - Technical reports, specifications
4. **For wikis** - Confluence, Notion (if Mermaid not supported)
5. **For emails** - Share diagrams as attachments
6. **For printing** - Physical documentation

### When to Use Markdown Mermaid

1. **GitHub/GitLab** - Auto-renders Mermaid
2. **VS Code** - Live preview with extension
3. **Documentation sites** - Most modern docs tools support Mermaid
4. **Version control** - Text-based, easy to diff and review

---

## 🔄 Workflow Recommendation

### Development Workflow

1. **Edit diagrams** in markdown files (`.md`)
2. **Preview** in VS Code or GitHub
3. **Generate images** when needed for specific use cases
4. **Keep both** markdown and images (markdown is source of truth)

### Documentation Workflow

1. **Use Mermaid in markdown** for documentation sites that support it
2. **Generate images** only for sites/formats that don't support Mermaid
3. **Regenerate images** whenever diagrams change
4. **Don't manually edit** generated images

---

## 📚 Additional Resources

- **Detailed Guide**: [IMAGE-GENERATION-GUIDE.md](./IMAGE-GENERATION-GUIDE.md)
- **Diagram Index**: [README.md](./README.md)
- **Mermaid Docs**: https://mermaid.js.org
- **Mermaid CLI**: https://github.com/mermaid-js/mermaid-cli
- **Online Editor**: https://mermaid.live

---

## ✨ Summary

You now have:

✅ **4 different scripts** to generate images (choose the one that works for you)
✅ **Comprehensive guide** with troubleshooting and customization
✅ **Automatic extraction** of all Mermaid diagrams from markdown
✅ **High-quality PNG output** ready for any use case
✅ **Consistent naming** for easy identification
✅ **Cross-platform support** (Windows, Mac, Linux)

**Next step**: Run one of the scripts to generate your diagram images!

```bash
# Windows
generate-images.bat

# Mac/Linux
./generate-images.sh

# Any platform
node generate-images.js
```

---

**Questions?** Check [IMAGE-GENERATION-GUIDE.md](./IMAGE-GENERATION-GUIDE.md) for detailed information.
