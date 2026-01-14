# Release jjstats

Release a new version of jjstats with auto-generated release notes.

## Arguments

- `$ARGUMENTS` - Version number (e.g., 1.0.1)

## Task

1. **Run release script**
   ```bash
   ./scripts/release.sh $ARGUMENTS
   ```
   This builds, notarizes, creates DMG, commits, tags, and creates GitHub Release.

2. **Get the diff from previous tag**
   ```bash
   # Find previous tag
   git tag --sort=-version:refname | head -2 | tail -1

   # Get diff
   git diff <previous_tag>..v$ARGUMENTS
   ```

3. **Analyze the diff and generate release notes**
   Based on the code changes, write a release note following this format:

   ```markdown
   ## jjstats X.Y.Z

   Brief description of this release.

   ### Features (if new features added)
   - New feature description

   ### Changes (if improvements made)
   - Change or improvement description

   ### Bug Fixes (if bugs fixed)
   - Fixed issue description

   ### Requirements
   - macOS 14.0 (Sonoma) or later
   - jj (Jujutsu) installed at `/opt/homebrew/bin/jj`

   ### Installation
   1. Download `jjstats.dmg`
   2. Open the DMG and drag jjstats to Applications
   3. Launch and select a jj repository folder
   ```

4. **Update GitHub Release**
   ```bash
   gh release edit v$ARGUMENTS --notes "<generated notes>"
   ```

5. **Show the release URL**
   ```
   https://github.com/Saqoosha/jjstats/releases/tag/v$ARGUMENTS
   ```

## Notes

- Commit messages should describe what changed and why
- The agent will read the actual code diff to understand changes
- Release notes should be user-friendly, not just commit messages
