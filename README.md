<div align="center">

```
╔═══════════════════════════════════════════╗
║                                           ║
║     █████╗ ██╗   ██╗██████╗  █████╗      ║
║    ██╔══██╗██║   ██║██╔══██╗██╔══██╗     ║
║    ███████║██║   ██║██████╔╝███████║     ║
║    ██╔══██║██║   ██║██╔══██╗██╔══██║     ║
║    ██║  ██║╚██████╔╝██║  ██║██║  ██║     ║
║    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝     ║
║                                           ║
╚═══════════════════════════════════════════╝
```

![Version](https://img.shields.io/badge/version-1.0.0-ff69b4?style=flat-square)
![License](https://img.shields.io/badge/license-private-red?style=flat-square)
![Platform](https://img.shields.io/badge/platform-termux%20%7C%20linux-00ff00?style=flat-square)

**Bottok License Bypass & Auto-Restart Wrapper**

</div>

---

## 🎯 What is AURA?

**AURA.SH** is a smart wrapper script that removes usage limitations from [Bottok](https://github.com/jfadev/bottok) by automatically restarting the bot whenever it stops. 

> Bottok normally has built-in limits that halt operation after certain usage. AURA bypasses this by detecting when Bottok stops and immediately relaunching it — giving you **unlimited, uninterrupted automation**.

---

## 🚀 How To Install
Requirements: [termux](https://termux.dev/en/)

1. Install Alpine in Termux
```bash
pkg update
pkg upgrade
pkg install wget -y
wget https://raw.githubusercontent.com/FuumaXyz/AURA/refs/heads/main/install-termux.sh
chmod +x install-termux.sh
./install-termux.sh
```

2. Run in Alpine terminal
```bash
wget https://raw.githubusercontent.com/FuumaXyz/AURA/refs/heads/main/install-alpine.sh
chmod +x install-alpine.sh
./install-alpine.sh
```

🎮 Usage
```proot-distro login alpine
cd tiktok
bash aura.sh
```

**AURA monitors Bottok 24/7:**
1. Starts Bottok with your chosen mode (Views/Hearts/Favorites)
2. Detects when Bottok stops (due to limitations)
3. Immediately relaunches Bottok automatically
4. Repeats endlessly — **no limits, no interruptions**

---

Menu
```
[1] Views      — Boost video views
[2] Hearts     — Boost hearts/likes  
[3] Favorites  — Boost favorites
[4] Settings   — Cookie & module management
[5] License    — View license info
[6] Exit       — Quit program
```

Settings
```
[1] Remove Cookies   — Reset cookies
[2] Set Cookies      — Input new cookies
[3] Extract Modules  — Reinstall node_modules
```

---

⚠️ Disclaimer

This tool is for **educational purposes only**. Users are responsible for complying with platform terms of service. The developer assumes no liability for misuse.

---

<div align="center">

Star this repo if it helps you!

Made with 💖 by **FuumaXyz**

</div>