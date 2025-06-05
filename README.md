<div align="center">
  <img src="Kefir/Assets.xcassets/AppIcon.appiconset/icon_256.png" alt="Kefir Logo" width="128" height="128">
</div>

# Kefir - KEF Speaker Control for macOS

A native macOS menubar application for controlling KEF wireless speakers (LSX II, LS50 Wireless II, LS60) with real-time updates and elegant interface.

![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green)

## Features

### 🎵 Real-Time Control
- **Live Status Updates** - Volume, source, and playback state sync automatically
- **Now Playing Display** - Album art, track info, and progress for streaming sources
- **Instant Response** - Changes reflect immediately in the interface

### 🎛️ Complete Speaker Management
- **Volume Control** - Draggable slider, +/- buttons, and mute toggle
- **Source Switching** - Quick access to all input sources (Wi-Fi, Bluetooth, TV, Optical, etc.)
- **Power Management** - Turn speakers on/off directly from the menubar
- **Speaker Profiles** - Save multiple speakers and switch between them

### 🎪 Mini Player
- **Floating Window** - Compact controls that stay on top
- **Hover Effects** - Reveals controls when you hover over track info
- **Playback Controls** - Play/pause, previous/next for streaming sources
- **Visual Feedback** - Animated sound waves for active playback

### ⌨️ Global Shortcuts
- **Volume Up/Down** - Adjust volume from anywhere
- **Mute Toggle** - Quick mute/unmute
- **Playback Control** - Play/pause, skip tracks globally

### 🎨 Modern Interface
- **Native macOS Design** - Follows system appearance (light/dark mode)
- **Visual Effects** - Translucent backgrounds and smooth animations
- **Accessibility** - Full VoiceOver support and keyboard navigation

## Screenshots

![Kefir Screenshot](Resources/promo.jpeg)

### Main Popover
- Volume control with live updates
- Now playing information with album art
- Source selection buttons
- Power controls

### Mini Player
- Compact floating window
- Hover-to-reveal controls
- Real-time track information

## Installation

### Requirements
- macOS 13.0 or later
- KEF wireless speakers on the same network
- Network connectivity to speakers

### Building from Source

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/kef.git
   cd kef/Kefir
   ```

2. **Open in Xcode**
   ```bash
   open Kefir.xcodeproj
   ```

3. **Build and run**
   - Select the Kefir scheme
   - Press Cmd+R to build and run

### Dependencies
- [SwiftKEF](https://github.com/melonamin/SwiftKEF) - KEF speaker control library
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) - Global keyboard shortcuts

## Setup

### First Launch
1. Launch Kefir.app
2. Grant accessibility permissions for global shortcuts (optional)
3. Click the menubar icon and select "Settings"
4. Add your first speaker with its IP address

### Adding Speakers
1. Find your speaker's IP address (check your router or KEF app)
2. Click the menubar icon → Settings → Add Speaker
3. Enter a friendly name and IP address
4. The first speaker is automatically set as default

### Configuring Shortcuts
1. Go to Settings → Keyboard Shortcuts
2. Set your preferred key combinations
3. Common shortcuts:
   - Volume Up: `Option + Up Arrow`
   - Volume Down: `Option + Down Arrow`
   - Mute: `Option + M`
   - Play/Pause: `Option + Space`

## Usage

### Basic Controls
- **Volume**: Drag the slider or use +/- buttons
- **Mute**: Click the speaker icon or use the keyboard shortcut
- **Power**: Toggle speaker power from the menubar
- **Source**: Click source buttons to switch inputs

### Streaming Playback
When using Wi-Fi or Bluetooth sources:
- Track information appears automatically
- Use playback controls (previous/play/pause/next)
- Progress bar shows current position
- Album art displays when available

### Mini Player
- Access via menubar → "Show Mini Player"
- Drag to reposition anywhere on screen
- Hover to reveal controls
- Close button appears on hover

### Multiple Speakers
- Switch between speakers in Settings
- Each speaker remembers its last state
- Set a default speaker for automatic connection

## Architecture

### MVVM Pattern
```
AppState (ViewModel)
├── SpeakerConnectionManager
├── VolumeManager
├── SourceManager
├── PlaybackStateManager
├── ErrorManager
└── ConfigurationManager
```

### Key Components

#### Models
- **AppState** - Central coordinator managing all app state
- **VolumeManager** - Volume and mute state management
- **SourceManager** - Input source handling with display names
- **PlaybackStateManager** - Track info and playback state
- **SpeakerConnectionManager** - Network communication with speakers
- **ErrorManager** - Centralized error handling and user notifications
- **ConfigurationManager** - Speaker profiles and settings persistence

#### Views
- **PopoverView** - Main interface with adaptive content
- **ConnectedView** - Controls for active speakers
- **NowPlayingCard** - Rich media controls for streaming
- **VolumeCard** - Dedicated volume control interface
- **MiniPlayerView** - Floating player window
- **SettingsView** - Speaker management and preferences

### Real-Time Updates
- **Polling System** - Regular status checks with the speaker
- **Event Streaming** - Async sequence of speaker events
- **Combine Framework** - Reactive state propagation
- **Manager Coordination** - Updates flow through specialized managers

## Development

### Project Structure
```
Kefir/
├── KefirApp.swift              # App entry point
├── Constants.swift             # App-wide constants
├── Models/                     # Data models and business logic
│   ├── AppState.swift          # Main app state coordinator
│   ├── VolumeManager.swift     # Volume control logic
│   ├── SourceManager.swift     # Source management
│   ├── PlaybackStateManager.swift # Track and playback state
│   ├── SpeakerConnectionManager.swift # Network communication
│   ├── ErrorManager.swift      # Error handling
│   └── ConfigurationManager.swift # Settings persistence
├── Views/                      # SwiftUI interface components
│   ├── Popover/               # Main popover interface
│   ├── MiniPlayer/            # Floating player window
│   ├── Settings/              # Configuration screens
│   └── Shared/                # Reusable UI components
└── Assets.xcassets/           # Images and colors
```

### Building and Testing

#### Build Commands
```bash
# Debug build
xcodebuild -scheme Kefir -configuration Debug build

# Release build
xcodebuild -scheme Kefir -configuration Release build

# Run tests
xcodebuild -scheme Kefir test
```

#### Code Style
- Swift 6.0 with strict concurrency
- SwiftUI for all interface components
- Async/await for network operations
- Actor isolation for thread safety
- Comprehensive error handling

### Contributing

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Follow** existing code patterns and architecture
4. **Test** your changes thoroughly
5. **Commit** with clear messages (`git commit -m 'Add amazing feature'`)
6. **Push** to your branch (`git push origin feature/amazing-feature`)
7. **Open** a Pull Request

### Testing
- Unit tests for all manager classes
- SwiftUI preview providers for visual components
- Integration tests with mock speaker connections
- Manual testing with actual KEF speakers

## Troubleshooting

### Common Issues

**App doesn't detect speaker**
- Verify speaker and Mac are on same network
- Check speaker IP address in router settings
- Try pinging the speaker: `ping [speaker-ip]`

**Global shortcuts don't work**
- Grant accessibility permissions in System Preferences
- Check for conflicting shortcuts in other apps
- Restart the app after granting permissions

**Volume changes don't appear**
- Check network connection to speaker
- Verify speaker is powered on
- Look for error messages in the interface

**Real-time updates are slow**
- Check network latency to speaker
- Reduce polling interval in settings (if available)
- Restart the app to reset connections

## License

MIT License - see [LICENSE](../LICENSE) file for details.

## Acknowledgments

- KEF for creating excellent wireless speakers
- SwiftKEF library for the networking foundation
- Apple for SwiftUI and modern Swift features

---

🎵 Made for music lovers who appreciate both great sound and great software