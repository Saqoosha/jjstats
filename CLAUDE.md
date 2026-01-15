# jjstats

macOS native app for viewing jj (Jujutsu) repository history.

## Tech Stack

- Swift 6.0 / SwiftUI
- macOS 14.0+
- XcodeGen for project generation
- jj (Jujutsu) 0.25.0+ for version control

## Build

```bash
# Build (Debug)
./scripts/build.sh

# Build (Release)
./scripts/build.sh Release

# Run (after build)
open build/DerivedData/Build/Products/Debug/jjstats.app
```

**Important:** Do NOT use `swift build` or `swift run` for this project. Always use `./scripts/build.sh` which uses xcodebuild for proper app bundle with resources and entitlements.

## Release Procedure

See `.claude/commands/release.md` for detailed workflow, or run:

```bash
./scripts/release.sh <version>
```

## Version Control

This project uses `jj` (Jujutsu) instead of git. Use `jj` commands for all VCS operations.

### PR Workflow with jj

```bash
# 1. Create bookmark (branch) pointing to your commit
jj bookmark create <branch-name> -r @-

# 2. Push to remote (--allow-new for new branches)
jj git push --bookmark <branch-name> --allow-new

# 3. Create PR with gh CLI
gh pr create --base main --head <branch-name>
```

After PR is merged (with squash):

```bash
# 1. Fetch remote changes
jj git fetch

# 2. Rebase working copy onto updated main
jj rebase -d main

# 3. Abandon the now-empty original commit (squash creates new commit on GitHub)
jj abandon <original-commit>

# 4. Delete the remote branch
jj git push --deleted
```

Note: Squash merge creates a new commit on GitHub, leaving the original local commit orphaned. Use `--rebase` or `--merge` instead of `--squash` for simpler cleanup.

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
