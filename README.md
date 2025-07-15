# Kong 🦍

![Godot 3.6](https://img.shields.io/badge/Godot-3.6-blue)
![License](https://img.shields.io/github/license/AshinMc/Kong)
![Status](https://img.shields.io/badge/status-active-brightgreen)

<p align="center">
  <img src="https://raw.githubusercontent.com/AshinMc/Kong/main/icon.png" alt="Kong Logo" width="200" height="200">
</p>

> A powerful Godot-based server solution for multiplayer game development

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

Kong is a versatile server framework built with Godot 3.6, designed to simplify multiplayer game development. It provides both a mini server for testing and a full server solution for production environments, making it easy to scale your multiplayer projects.

## ✨ Features

- **Flexible Deployment Options**: Run as a mini server or dedicated server
- **Easy Configuration**: Simple setup with minimal coding required
- **Scalable Architecture**: Designed to handle multiple concurrent connections
- **Built on Godot**: Leverages Godot's powerful networking capabilities
- **Cross-Platform Support**: Works on Windows, macOS, and Linux

## 📋 Requirements

- Godot 3.6 (for development)
- Windows, macOS, or Linux (for running exports)
- Minimum 2GB RAM (recommended 4GB+ for production servers)

## 🚀 Installation

### Option 1: Using Godot 3.6

1. **Install Godot 3.6**
   - Download Godot 3.6 from the [official website](https://godotengine.org/download)
   - Choose the Standard version (not Mono/C#)

2. **Clone this repository**
   ```bash
   git clone https://github.com/AshinMc/Kong.git
   cd Kong
   ```

3. **Open the project in Godot**
   - Launch Godot 3.6
   - Click "Import"
   - Navigate to the cloned repository folder
   - Open the `project.godot` file

4. **Run the project**
   - Click the "Play" button in the top-right corner of the Godot editor
   - Select your preferred server mode (mini or full)

### Option 2: Using Pre-built Exports

1. **Download the latest exports**
   - Navigate to the `/exports` folder in this repository
   - Choose either the mini server or full server executable based on your needs

2. **Mini Server Setup**
   - Extract the mini server archive to your desired location
   - Run the executable (`Kong_MiniServer.exe` on Windows, `Kong_MiniServer.x86_64` on Linux)
   - The mini server includes a basic web interface accessible at `http://localhost:8080`

3. **Full Server Setup**
   - Extract the server-only archive to your deployment environment
   - Configure the server by editing the `config.json` file
   - Run the executable (`Kong_Server.exe` on Windows, `Kong_Server.x86_64` on Linux)
   - For production use, consider setting up a service/daemon for automatic startup

## 💻 Usage

### Mini Server

The mini server is perfect for development and testing. It provides:

```bash
# Starting the mini server on default port
./Kong_MiniServer

# Starting with a custom port
./Kong_MiniServer --port=9000

# Starting with debug logging
./Kong_MiniServer --debug
```

The mini server includes a web dashboard accessible at `http://localhost:8080` (or your custom port) where you can monitor connections, view logs, and adjust settings in real-time.

### Full Server

The full server is optimized for production environments:

```bash
# Starting the server with default configuration
./Kong_Server

# Specifying a custom configuration file
./Kong_Server --config=my_config.json

# Running in headless mode (no console output)
./Kong_Server --headless
```

For advanced configuration, edit the `config.json` file to adjust:
- Maximum connections
- Network timeout values
- Resource allocation
- Authentication requirements
- Logging detail level

## 📖 Documentation

For detailed documentation, check out the [Wiki](https://github.com/AshinMc/Kong/wiki) or the `/docs` folder in this repository.

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