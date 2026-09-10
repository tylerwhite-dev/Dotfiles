# Winget Cheat Sheet

## Package Management
- **Search for a package**: `winget search <name>`
- **Install a package**: `winget install <name>`
- **Uninstall a package**: `winget uninstall <name>`
- **List installed packages**: `winget list`
- **Package info**: `winget info <name>`

## Maintenance
- **Update all packages**: `winget upgrade --all`
- **Check for updates**: `winget upgrade`

## Sync (Import/Export)
- **Export current settings**: `winget export --output <file>.json`
- **Import from a file**: `winget import --import-file <file>.json`
