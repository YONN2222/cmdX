# ✂️ cmdX

### 🧩 What is cmdX?

**cmdX** is a small macOS utility that adds the missing **Cmd + X** file-cut function to Finder — just like you know it from Windows. It makes moving files smoother, smarter, and faster.

Works perfectly on:
- 💻 **Apple Silicon (M1, M2, M3…)**
- 🧠 **Intel-based Macs**

### ⚙️ Features

- 🪄 Adds real **Cmd + X / Cmd + V** support for files  
- ⚡ Works natively inside Finder  
- 🧱 Lightweight, no background bloat  
- 🎯 Compatible with macOS Big Sur and later  

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

### ❤️ Credits

Built by [Yonn](https://github.com/YONN2222)  
Made for everyone tired of Finder’s missing “Cut” function with cmdX.
