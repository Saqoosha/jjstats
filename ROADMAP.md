# jjstats Roadmap

## Completed

### v1.x - Current
- [x] Commit list with change ID, description, timestamp
- [x] File changes and diff viewer
- [x] Bookmark badges with sync status
- [x] Tag badges
- [x] GPG signature verification status
- [x] Auto-refresh via FSEvents file watcher
- [x] **Commit dependency graph** - Visual DAG showing parent-child relationships

## Planned Features

### jj-Specific Features

#### Operation Log (`jj op log`)
- View operation history (every jj command creates an operation)
- Undo/redo operations
- Compare repository state between operations
- Restore to previous operation state

#### Conflict Visualization
- Highlight commits with unresolved conflicts
- Show conflict markers in diff view
- List conflicted files
- Integration with `jj resolve`

#### Revset Query
- Search bar with revset syntax support
- Filter commits using expressions like:
  - `@-` (parent of working copy)
  - `trunk()..@` (commits since trunk)
  - `conflicts()` (commits with conflicts)
  - `bookmarks()` (commits with bookmarks)
- Syntax highlighting and autocomplete

#### Obslog (`jj obslog`)
- View rewrite history for a specific commit
- Track how commits evolved through rebases/amends
- Navigate between commit versions

#### Immutable Commits
- Visual distinction between mutable and immutable commits
- Show immutable boundary (e.g., `trunk()`)
- Warn before operations that would modify immutable commits

### Interactive Operations

#### Describe Editor
- Edit commit messages inline
- Multi-line description support
- Preview changes before applying

#### Squash/Split
- Squash commits with drag-and-drop or context menu
- Split commits by selecting files/hunks
- Interactive file selection

#### Rebase
- Drag-and-drop rebase between commits
- Visual rebase preview
- Conflict resolution workflow

#### Bookmark Management
- Create/delete/rename bookmarks
- Track/untrack remote bookmarks
- Push bookmarks to remote

### UI Improvements

#### Graph Enhancements
- Color-coded branches
- Collapsed/expanded view for long histories
- Zoom in/out

#### Search and Filter
- Full-text search in commit messages
- Filter by author, date range, file path
- Save and recall filters

#### Multiple Repositories
- Tab-based multi-repo support
- Recent repositories list
- Repository favorites

### Settings

- Configurable jj binary path
- Custom color themes
- Graph style options (line thickness, node size)
- Default revset for initial view

## Contributing

Feature requests and contributions welcome! Priority is given to jj-specific features that differentiate this app from generic Git GUIs.
