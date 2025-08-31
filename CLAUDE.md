# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a SwiftUI macOS application using SwiftData for persistence. The app follows Apple's modern SwiftUI patterns with the @main app entry point and uses ModelContainer for data management.

## Build and Development Commands

### Building the Project
```bash
# Build for Debug
xcodebuild -project Nawawi.xcodeproj -scheme Nawawi -configuration Debug build

# Build for Release
xcodebuild -project Nawawi.xcodeproj -scheme Nawawi -configuration Release build

# Clean build folder
xcodebuild -project Nawawi.xcodeproj -scheme Nawawi clean
```

### Running Tests
```bash
# Run unit tests
xcodebuild test -project Nawawi.xcodeproj -scheme Nawawi -destination 'platform=macOS'

# Run UI tests
xcodebuild test -project Nawawi.xcodeproj -target NawawiUITests -destination 'platform=macOS'

# Run a specific test
xcodebuild test -project Nawawi.xcodeproj -scheme Nawawi -only-testing:NawawiTests/[TestClassName]/[testMethodName]
```

### Opening in Xcode
```bash
open Nawawi.xcodeproj
```

## Architecture

### Core Components
- **NawawiApp.swift**: Main app entry point defining the SwiftUI App structure with SwiftData ModelContainer configuration
- **ContentView.swift**: Primary view using NavigationSplitView pattern with list/detail interface
- **Item.swift**: SwiftData @Model class representing the core data entity

### Data Layer
- Uses SwiftData with ModelContainer for persistence
- Schema defined with Item model
- ModelConfiguration set to persist data (not in-memory only)

### UI Pattern
- NavigationSplitView for macOS-optimized list/detail interface
- SwiftUI environment injection for modelContext
- @Query property wrapper for reactive data fetching