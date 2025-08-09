# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a vfox plugin for managing multiple Elixir versions across Windows, Linux, and macOS platforms. The plugin integrates with vfox (version-fox), a universal SDK version management tool.

## Code Architecture and Structure

- **Plugin Entry Point**: `metadata.lua` - Contains plugin metadata like name, version, and compatibility requirements
- **Core Logic**: `lib/elixir_utils.lua` - Utility functions for version management, HTTP requests, and platform-specific operations
- **Hook System**: The `hooks/` directory contains Lua files that implement the vfox plugin interface:
  - `available.lua` - Lists available Elixir versions
  - `pre_install.lua` - Handles version validation and download URL generation
  - `post_install.lua` - Performs post-installation tasks like compilation
  - `pre_use.lua` - Validates version before activation
  - `env_keys.lua` - Configures environment variables for installed versions

## Common Development Commands

### Testing

```bash
# The project uses GitHub Actions for E2E testing across platforms
# Tests are defined in .github/workflows/e2e_test.yaml

# Mise E2E tests are defined in .github/workflows/mise_e2e_test.yaml

# To run tests locally, you would need to:
# 1. Install vfox or mise
# 2. Add the plugin
# 3. Install and test Elixir versions
```

### Version Management

```bash
# Update Elixir versions list
# Done via GitHub Actions workflow in .github/workflows/update_elixir_versions.yaml

# The versions are stored in assets/versions.txt (Unix) and assets/versions_win.txt (Windows)
```

## Key Implementation Details

1. **Multi-platform Support**: The plugin handles different installation methods for Windows (pre-built installers) and Unix-like systems (source compilation)

2. **Mirror Support**: Can install from official Elixir releases or pre-built versions from hex.pm (controlled by VFOX_ELIXIR_MIRROR environment variable)

3. **Dependency Management**: Requires Erlang/OTP to be installed before Elixir installation

4. **Installation Process**:
   - Unix/Linux: Downloads source code and compiles with `make`
   - Windows: Downloads and executes official installer
   - Hex mirror: Downloads pre-built binaries

## Plugin Interface

The plugin implements the standard vfox plugin interface through the hook files:

- `PLUGIN:Available()` - Returns list of available versions
- `PLUGIN:PreInstall()` - Prepares for installation
- `PLUGIN:PostInstall()` - Performs post-installation tasks
- `PLUGIN:PreUse()` - Validates before version activation
- `PLUGIN:EnvKeys()` - Sets up environment variables

This architecture allows the plugin to integrate seamlessly with vfox's version management system while handling the specific requirements of Elixir installation across different platforms.
