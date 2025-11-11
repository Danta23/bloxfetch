# 📊 BloxFetch

**BloxFetch** is a lightweight Lua module for Roblox Studio that simulates system information display—similar to Unix's `neofetch`. It’s designed for developers who want to add aesthetic diagnostics to their games, command bar UIs, or dev dashboards.

---

## 🎯 Purpose

BloxFetch mimics the look and feel of `neofetch`, providing simulated system info like user identity, engine version, and memory usage. It’s perfect for Roblox developers who want to add flair to their debugging tools or in-game terminals.

---

## ✨ Features

- 🧠 **Simulated System Info**: Displays user name, engine version, memory stats, and more
- 🎨 **Neofetch-style Output**: Clean, console-friendly formatting
- 🔌 **Easy Integration**: Plug into any command bar or GUI
- 🧱 **Modular Design**: Lightweight and customizable
- 🚀 **Compatible with CommandBar.lua**: Seamless pairing with advanced command bar UIs

---

## 📦 Installation

1. Clone or download this repository
2. Place the `BloxFetch.lua` module inside `ReplicatedStorage` in your Roblox project
3. Require the module from any LocalScript or command bar handler:

```lua
local BloxFetch = require(game:GetService("ReplicatedStorage"):WaitForChild("BloxFetch"))
```

---

## 🧪 Usage

Call the module’s main function to get system info:

```lua
print(BloxFetch.getInfo())
```

Or use it inside a command bar handler (e.g., in a custom dev console):

```lua
if command == "bloxfetch" then
    print(BloxFetch.getInfo())
```

Supports flags for specific information (check the module source for available flags, example):

```bash
bloxfetch --version
bloxfetch -v
```

---

## 📄 License

This project is licensed under the MIT License. Feel free to use, modify, and distribute.

---

## 🙌 Credits

  - Created by **Danta**
  - Inspired by Unix's **`neofetch`**
  - Built for **Roblox Studio** using **Lua**

<!-- end list -->

```
