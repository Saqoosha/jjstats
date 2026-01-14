# jjstats

macOS native app for viewing jj (Jujutsu) repository history.

## Tech Stack

- Swift 6.0 / SwiftUI
- macOS 14.0+
- XcodeGen for project generation

## Build

```bash
# Build (Debug)
./scripts/build.sh

# Build (Release)
./scripts/build.sh Release

# Run (after build)
open build/DerivedData/Build/Products/Debug/jjstats.app
```

### Using Swift Package Manager

```bash
swift build
swift run
```

Note: SPM build won't show Dock icon. Use xcodebuild for proper app bundle.

## Release Procedure

### Quick Release (recommended)

```bash
./scripts/release.sh 1.0.1
```

This script:
1. Bumps version in `project.yml`
2. Builds Release configuration
3. Signs and notarizes the app
4. Creates notarized DMG
5. Commits version bump with jj
6. Creates GitHub Release with DMG

### Manual Steps

#### 1. Bump Version

Edit `project.yml`:
```yaml
MARKETING_VERSION: "X.Y.Z"
CURRENT_PROJECT_VERSION: "N"
```

Then regenerate: `xcodegen generate`

#### 2. Build Notarized DMG

```bash
./scripts/package_dmg.sh
# Output: build/jjstats.dmg
```

#### 3. Create Tag & GitHub Release

```bash
jj describe -m "Release vX.Y.Z"
jj bookmark set main -r @
jj new
jj git push --bookmark main

# Create git tag
git tag vX.Y.Z
git push origin vX.Y.Z

gh release create vX.Y.Z build/jjstats.dmg \
  --title "jjstats X.Y.Z" \
  --notes "Release notes here"
```

### Release Notes Format

```markdown
## jjstats X.Y.Z

Brief description of this release.

### Features (for major releases)
- New feature 1
- New feature 2

### Changes
- Change or improvement 1
- Change or improvement 2

### Bug Fixes (if applicable)
- Fixed issue with X
```

### First-time Setup for Notarization

```bash
xcrun notarytool store-credentials "notarytool-profile" \
  --apple-id YOUR_APPLE_ID \
  --team-id G5G54TCH8W \
  --password APP_SPECIFIC_PASSWORD
```

## Version Control

This project uses `jj` (Jujutsu) instead of git. Use `jj` commands for all VCS operations.

## Project Structure

- `Sources/jjstats/` - Main app source
  - `Models/` - Data models (Commit, FileChange, JJRepository)
  - `Services/` - JJ CLI wrapper and FSEvents file watcher
  - `Views/` - SwiftUI views
- `scripts/` - Build and release scripts
  - `build.sh` - Build Debug/Release
  - `notarize.sh` - Sign and notarize app
  - `package_dmg.sh` - Create notarized DMG
  - `release.sh` - Full release workflow
- `project.yml` - XcodeGen project definition
- `Package.swift` - SPM manifest
