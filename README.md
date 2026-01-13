# ✂️ cmdX
[![GitHub Repo stars](https://img.shields.io/github/stars/YONN2222/cmdX)](https://github.com/YONN2222/cmdX)
[![GitHub Downloads (all assets, latest release)](https://img.shields.io/github/downloads/YONN2222/cmdX/total?label=Downloads&color=%236495ED)](https://github.com/YONN2222/cmdX/releases)
[![GitHub Issues](https://img.shields.io/github/issues/YONN2222/cmdX?logoColor=FF0000&label=Issues&color=FF0000)](https://github.com/YONN2222/cmdX/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/YONN2222/cmdX?logoColor=007F00&label=Pull%20Requests&color=007F00)](https://github.com/YONN2222/cmdX/pulls)



### 🧩 What is cmdX?

**cmdX** is a small macOS utility that adds the missing **Cmd + X** file-cut function to Finder, just like you know it from Windows. It makes moving files smoother, smarter, and faster.

Works perfectly on:
- 💻 **Apple Silicon (M1, M2, M3, M4...)**
- 🧠 **Intel-based Macs**

### ⚙️ Features

- 🪄 Adds **Cmd + X / Cmd + V** support for files  
- ⚡ Works natively inside Finder  
- 🧱 Lightweight, no background bloat  
- 🎯 Compatible with macOS Big Sur and later


### ✨ Install

You can install **cmdX** in two ways:

**From GitHub Releases**
Grab the latest build directly from the releases page:

> https://github.com/YONN2222/cmdX/releases

**Via Homebrew**
Thanks to [thedavidwenk](https://github.com/thedavidwenk), you can also install cmdX through Homebrew:

```sh
brew tap thedavidwenk/cmdx
brew install cmdx
```

Repository:  
> https://github.com/thedavidwenk/homebrew-cmdx



### 🧑‍💻 Usage

1. Open Finder  
2. Select a file  
3. Press **Cmd + X** to cut  
4. Navigate to a new folder  
5. Press **Cmd + V** to paste (move)  

### 🧰 Build It Yourself

1. **Clone the repository**
   ```bash
   git clone https://github.com/YONN2222/cmdX.git
   cd cmdX
   ```

2. **Open the project in Xcode**
   ```bash
   open cmdX.xcodeproj
   ```

3. **Build the app**
   ```bash
   xcodebuild -scheme cmdX -configuration Release
   ```

### 🧠 Note

You need to grant **Accessibility permissions** to cmdX under **System Settings → Privacy & Security → Accessibility**.

### ⭐ Star it

If you like this projekt, feel free to star it!

### ❤️ Credits

Built by [Yonn](https://github.com/YONN2222)  
Made for everyone tired of Finder’s missing “Cut” function with cmdX.
