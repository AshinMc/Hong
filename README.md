# Kong 🦍

![Godot 3.6](https://img.shields.io/badge/Godot-3.6-blue)
![License](https://img.shields.io/github/license/AshinMc/Kong)
![Status](https://img.shields.io/badge/status-active-brightgreen)

<p align="center">
  <img src="https://raw.githubusercontent.com/AshinMc/Kong/main/icon.png" alt="Kong Logo" width="200" height="200">
</p>

> A two player one character Godot game concept

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
  - [Option 1: Using Godot 3.6](#option-1-using-godot-36)
  - [Option 2: Using Pre-built Exports](#option-2-using-pre-built-exports)
- [Usage](#usage)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

## 🔍 Overview

Kong is a two player one character Godot game concept built with Godot 3.6. It provides both a mini server for casual gameplay and a full server solution for debugging environments.

## ✨ Features

- **Flexible Options**: Run buit exports or run latest project with game engine
- **Easy Setup**: Simple setup 
- **Built on Godot**: Leverages Godot's powerful networking capabilities
- **Cross-Platform Support**: Works on Windows, macOS, and Linux (if using game engine)

## 📋 Requirements

- Godot 3.6 (for development)
- Windows, macOS, or Linux (for running exports )

## 🚀 Installation

### Option 1: Using Godot 3.6

1. **Clone this repository**
   ```bash
   git clone https://github.com/AshinMc/Kong.git
   cd Kong
   ```
2. **Install Godot 3.6**
   - Download Godot 3.6 from the [official website](https://godotengine.org/download)
   - Create /godot in the cloned repository
   - Extract file into the godot folder

3. **Open the project in Godot**
   - Launch Godot 3.6
   - Click "Import"
   - Navigate to the cloned repository folder
   - Open the `project.godot` file

4. **Run the project**
   - Click the "Play" or "Edit" button in the top-right corner of the Godot editor
   - Select your preferred server mode (mini or debug)

### Option 2: Using Pre-built Exports

1. **Download the latest exports**
   - Navigate to the `/exports` folder in this repository
   - Choose the game executable based on your needs

2. **Mini Server Setup**
   - Extract the mini server archive to your desired location
   - Run the bat script file.
   - The mini server includes a basic web interface accessible at `http://localhost:8080`

3. **Debug Server Setup**
   - Extract the server-only archive to your desired location
   - Configure the server by editing the `config.json` file
   - Run the bat script file.
   - Includes html visualisation with lots of logging and fancy formatting

## 💻 Usage

### Gameplay/Testing Mode

1. Run Kong executable twice (each for both players)
2. Run mini_server.bat (shows a minimal console)

### Debug Mode

1. Run start_game.bat


## 📖 Documentation

For detailed documentation, check out the [Wiki](https://github.com/AshinMc/Kong/wiki) or the `/docs` folder in this repository. # Not updated yet

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

<p align="center">
  Made with ❤️ by <a href="https://github.com/AshinMc">AshinMc</a>
</p>
```

If you find Kong useful, please consider giving it a star! ⭐
