# Manual Installations Guide

This document tracks applications and tools that require manual installation (not available via Homebrew or other package managers). Each entry includes installation instructions, version tracking, and configuration notes.

## 📱 Applications

### Docker Desktop

- **Purpose**: Container platform for development
- **Download URL**: https://docs.docker.com/desktop/mac/install/
- **Current Version**: 4.25.0 (as of 2024-01)
- **Installation Method**: Download .dmg file and install
- **Configuration Notes**:
  - Set memory to at least 4.1GB for Kubernetes
  - Enable Kubernetes in Docker Desktop settings
  - Configure resource limits based on your system

### Obsidian

- **Purpose**: Knowledge management and note-taking
- **Download URL**: https://obsidian.md/
- **Current Version**: 1.5.3 (as of 2024-01)
- **Installation Method**: Download .dmg file and install
- **Configuration Notes**:
  - Sync vault with iCloud or Git
  - Install community plugins as needed
  - Configure theme and appearance

### Notion

- **Purpose**: All-in-one workspace
- **Download URL**: https://www.notion.so/desktop
- **Current Version**: 2.1.23 (as of 2024-01)
- **Installation Method**: Download from website or Mac App Store
- **Configuration Notes**:
  - Sign in with your account
  - Configure workspace settings
  - Set up integrations as needed

### Spotify

- **Purpose**: Music streaming
- **Download URL**: https://www.spotify.com/download/mac/
- **Current Version**: 8.8.0.718 (as of 2024-01)
- **Installation Method**: Download .dmg file and install
- **Configuration Notes**:
  - Sign in with your account
  - Configure audio settings
  - Set up keyboard shortcuts

### Zoom

- **Purpose**: Video conferencing
- **Download URL**: https://zoom.us/download
- **Current Version**: 5.17.5.3390 (as of 2024-01)
- **Installation Method**: Download .pkg file and install
- **Configuration Notes**:
  - Sign in with your account
  - Configure audio/video settings
  - Set up meeting preferences

### Google Chrome

- **Purpose**: Web browser
- **Download URL**: https://www.google.com/chrome/
- **Current Version**: 120.0.6099.109 (as of 2024-01)
- **Installation Method**: Download .dmg file and install
- **Configuration Notes**:
  - Sign in with Google account
  - Install essential extensions
  - Configure sync settings

### Firefox

- **Purpose**: Web browser
- **Download URL**: https://www.mozilla.org/firefox/new/
- **Current Version**: 121.0 (as of 2024-01)
- **Installation Method**: Download .dmg file and install
- **Configuration Notes**:
  - Sign in with Firefox account
  - Install essential extensions
  - Configure privacy settings

## 🛠️ Development Tools

### XCode (Full Version)

- **Purpose**: iOS/macOS development IDE
- **Download URL**: Mac App Store
- **Current Version**: 15.2 (as of 2024-01)
- **Installation Method**: Download from Mac App Store
- **Configuration Notes**:
  - Accept license agreement
  - Install additional components as needed
  - Configure developer account

### Android Studio

- **Purpose**: Android development IDE
- **Download URL**: https://developer.android.com/studio
- **Current Version**: Hedgehog | 2023.1.1 (as of 2024-01)
- **Installation Method**: Download .dmg file and install
- **Configuration Notes**:
  - Install Android SDK
  - Configure emulator
  - Set up developer account

### Flutter SDK

- **Purpose**: Cross-platform mobile development
- **Download URL**: https://docs.flutter.dev/get-started/install/macos
- **Current Version**: 3.19.3 (as of 2024-01)
- **Installation Method**: Download and extract to ~/development/flutter
- **Configuration Notes**:

  ```bash
  # Add to PATH in ~/.zprofile
  export PATH="$PATH:$HOME/development/flutter/bin"

  # Run flutter doctor to verify installation
  flutter doctor
  ```

## ☁️ Cloud Tools

### Google Cloud SDK

- **Purpose**: Google Cloud Platform CLI tools
- **Download URL**: https://cloud.google.com/sdk/docs/install
- **Current Version**: 455.0.0 (as of 2024-01)
- **Installation Method**: Download .tar.gz and run install script
- **Configuration Notes**:

  ```bash
  # Initialize gcloud
  gcloud init

  # Install additional components
  gcloud components install kubectl
  gcloud components install docker-credential-gcr
  ```

### Azure CLI

- **Purpose**: Microsoft Azure CLI tools
- **Download URL**: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-macos
- **Current Version**: 2.57.0 (as of 2024-01)
- **Installation Method**: Download .pkg file and install
- **Configuration Notes**:

  ```bash
  # Sign in to Azure
  az login

  # Set default subscription
  az account set --subscription <subscription-id>
  ```

## 📋 Installation Checklist

### First Time Setup

- [ ] Install Docker Desktop
- [ ] Install Obsidian
- [ ] Install Notion
- [ ] Install Spotify
- [ ] Install Zoom
- [ ] Install Google Chrome
- [ ] Install Firefox
- [ ] Install XCode (if needed)
- [ ] Install Android Studio (if needed)
- [ ] Install Flutter SDK (if needed)
- [ ] Install Google Cloud SDK (if needed)
- [ ] Install Azure CLI (if needed)

### Configuration Tasks

- [ ] Configure Docker Desktop memory settings
- [ ] Set up Obsidian vault and plugins
- [ ] Configure Notion workspace
- [ ] Set up Spotify account and preferences
- [ ] Configure Zoom audio/video settings
- [ ] Install browser extensions
- [ ] Set up development accounts
- [ ] Configure cloud CLI tools

## 🔄 Update Process

### Monthly Updates

1. Check for updates to all manually installed applications
2. Download and install new versions
3. Update this document with new version numbers
4. Test functionality after updates

### Version Tracking

- Update version numbers in this document when installing new versions
- Note any breaking changes or configuration updates
- Document any new features or requirements

## 🚨 Troubleshooting

### Common Issues

#### Docker Desktop

- **Issue**: Kubernetes not starting
- **Solution**: Increase memory allocation to at least 4.1GB
- **Issue**: Permission denied errors
- **Solution**: Ensure Docker Desktop has necessary permissions

#### Obsidian

- **Issue**: Sync conflicts
- **Solution**: Resolve conflicts manually or use Git for version control
- **Issue**: Plugin compatibility
- **Solution**: Update plugins or disable incompatible ones

#### Development Tools

- **Issue**: PATH not set correctly
- **Solution**: Add tools to PATH in ~/.zprofile
- **Issue**: License/account issues
- **Solution**: Verify developer accounts and licenses

## 📝 Notes

- Keep this document updated with current versions
- Document any custom configurations or workarounds
- Note any dependencies between tools
- Track any issues encountered during installation

## 🔗 Useful Links

- [Docker Desktop Documentation](https://docs.docker.com/desktop/)
- [Obsidian Documentation](https://help.obsidian.md/)
- [Notion Help Center](https://www.notion.so/help)
- [Flutter Documentation](https://docs.flutter.dev/)
- [Google Cloud Documentation](https://cloud.google.com/docs)
- [Azure Documentation](https://docs.microsoft.com/en-us/azure/)
