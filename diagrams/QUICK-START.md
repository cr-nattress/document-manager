# Quick Start Guide - Diagram Images

**Generate PNG images from all Mermaid diagrams in 3 easy steps!**

---

## ⚡ Super Quick Start (Windows)

```cmd
cd diagrams
generate-images.bat
```

That's it! Double-click or run from command line.

---

## 📋 Prerequisites (One-Time Setup)

### Step 1: Install Node.js
Download from: https://nodejs.org (choose LTS version)

### Step 2: Install Mermaid CLI
```bash
npm install -g @mermaid-js/mermaid-cli
```

### Step 3: Verify Installation
```bash
mmdc --version
```

If you see a version number, you're ready! ✅

---

## 🚀 Generate Images

### Windows Users

**Option 1** (Easiest):
```cmd
generate-images.bat
```

**Option 2** (PowerShell):
```powershell
.\generate-images.ps1
```

**Option 3** (Node.js):
```cmd
node generate-images.js
```

### Mac / Linux Users

**Option 1** (Shell script):
```bash
chmod +x generate-images.sh
./generate-images.sh
```

**Option 2** (Node.js):
```bash
node generate-images.js
```

---

## 📊 What You'll Get

After running the script:
- ✅ ~33 PNG images generated
- ✅ High resolution (2048x2048)
- ✅ Transparent backgrounds
- ✅ Named like: `01-system-architecture-1.png`

Example output:
```
01-system-architecture-1.png
02-database-erd-1.png
03-sequence-diagrams-1.png
03-sequence-diagrams-2.png
... (and so on)
```

---

## 🐛 Quick Troubleshooting

### "mmdc not found"
**Fix**: Install mermaid-cli
```bash
npm install -g @mermaid-js/mermaid-cli
```

### "Permission denied" (Mac/Linux)
**Fix**: Make script executable
```bash
chmod +x generate-images.sh
```

### "Node not found"
**Fix**: Install Node.js from https://nodejs.org

---

## 📚 Need More Help?

- **Detailed Guide**: See [IMAGE-GENERATION-GUIDE.md](./IMAGE-GENERATION-GUIDE.md)
- **Diagram Index**: See [README.md](./README.md)
- **Recent Fixes**: See [FIXES-AND-UPDATES.md](./FIXES-AND-UPDATES.md)

---

## ✅ Success Checklist

Before running:
- [ ] Node.js installed
- [ ] mermaid-cli installed (`npm install -g @mermaid-js/mermaid-cli`)
- [ ] In the `diagrams/` directory
- [ ] Run one of the scripts above

After running:
- [ ] Check for PNG files in diagrams folder
- [ ] Verify images look correct
- [ ] Use images in presentations/documentation as needed

---

**That's it! You now have all your diagrams as images. 🎉**
