# Copilot Instructions for Extended Discord SourceMod Plugin

## Repository Overview

This repository contains **Extended Discord**, a SourcePawn plugin for SourceMod that provides additional functionality for Discord webhooks and Steam integration. The plugin extends the DiscordWebhookAPI with features like Steam avatar fetching and enhanced error logging.

### Key Components
- **Main Plugin**: `addons/sourcemod/scripting/Extended_Discord.sp`
- **Include File**: `addons/sourcemod/scripting/include/ExtendedDiscord.inc`
- **Build Config**: `sourceknight.yaml` (SourceKnight build system)
- **Dependencies**: SourceMod 1.11+ and DiscordWebhookAPI

## Technical Environment

### Language & Platform
- **Language**: SourcePawn (Source engine scripting language)
- **Platform**: SourceMod 1.11+ (latest stable recommended)
- **Compiler**: SourcePawn compiler via SourceKnight build system
- **Build Tool**: SourceKnight (modern SourcePawn package manager and build system)

### Dependencies
- SourceMod 1.11.0+ (base framework)
- DiscordWebhookAPI plugin (external dependency)
- Steam Web API (for avatar fetching functionality)

## Code Style & Standards

### SourcePawn Specific Guidelines
```sourcepawn
#pragma semicolon 1        // Always required
#pragma newdecls required  // Always required for modern SourcePawn
```

### Naming Conventions
- **Functions**: PascalCase (`GetClientSteamAvatar`)
- **Global Variables**: Prefix with `g_` and use camelCase (`g_sClientAvatar`)
- **Local Variables**: camelCase (`iClient`, `steamID`)
- **ConVars**: Use descriptive names (`g_cvSteamAPI`)
- **Native Functions**: Use plugin prefix (`ExtendedDiscord_LogError`)

### Code Quality Standards
- Use tabs for indentation (4 spaces equivalent)
- Delete trailing spaces
- Use descriptive variable and function names
- Proper error handling for all API calls
- Memory management: Always `delete` handles, don't check for null before delete
- Use `StringMap`/`ArrayList` instead of arrays where appropriate
- **Never use `.Clear()`** on StringMap/ArrayList (causes memory leaks) - use `delete` and create new instances

### HTTP and External API Best Practices
- All Steam API calls must use HTTPRequest with proper error handling
- Always validate HTTP response status before processing
- Use proper JSON parsing with memory cleanup (`delete json` objects)
- Handle disconnected clients in async callbacks (`GetClientOfUserId` validation)

## Project Structure

### Standard SourceMod Directory Layout
```
addons/sourcemod/
├── scripting/
│   ├── Extended_Discord.sp          # Main plugin source
│   └── include/
│       └── ExtendedDiscord.inc      # Native function definitions
├── plugins/                         # Compiled .smx files (build output)
├── configs/                         # Configuration files (if needed)
├── translations/                    # Language files (if needed)
└── logs/discord/                    # Runtime log directory
```

### Core Plugin Structure
```sourcepawn
// Required includes at top
#include <sourcemod>
#include <discordWebhookAPI>

// Required pragmas
#pragma newdecls required
#pragma semicolon 1

// Global variables with proper naming
Handle g_hFwd_OnErrorLogged = INVALID_HANDLE;
ConVar g_cvSteamAPI;
char g_sClientAvatar[MAXPLAYERS + 1][PLATFORM_MAX_PATH];

// Plugin info block
public Plugin myinfo = { /* ... */ };

// Load natives and library registration
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)

// Initialization
public void OnPluginStart()

// Client events
public void OnClientPostAdminCheck(int iClient)
public void OnClientDisconnect(int iClient)
```

## Build & Development Process

### Using SourceKnight Build System
The project uses SourceKnight for modern SourcePawn development:

```bash
# Install SourceKnight (if not available)
pip install sourceknight

# Build the plugin
sourceknight build

# Clean build artifacts
sourceknight clean
```

### Build Configuration (`sourceknight.yaml`)
- Automatically downloads SourceMod dependencies
- Manages external plugin dependencies (DiscordWebhookAPI)
- Compiles to `/addons/sourcemod/plugins`
- Handles include path resolution

### Development Workflow
1. Make changes to `.sp` or `.inc` files
2. Run `sourceknight build` to compile
3. Test on development server
4. Commit changes (CI will build and release automatically)

## Native Functions & API Design

### Creating Native Functions
```sourcepawn
// In plugin source (Extended_Discord.sp)
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("ExtendedDiscord_LogError", Native_LogError);
    CreateNative("ExtendedDiscord_GetAvatarLink", Native_GetAvatarLink);
    RegPluginLibrary("ExtendedDiscord");
    return APLRes_Success;
}

// Native implementation
public int Native_LogError(Handle plugin, int numParams)
{
    char sBuffer[2048];
    FormatNativeString(0, 1, 2, sizeof(sBuffer), _, sBuffer);
    // Implementation...
    return 1;
}
```

### Include File Documentation (`ExtendedDiscord.inc`)
Document all native functions with:
- Clear description
- Parameter details with types
- Return value specification
- Usage examples if complex

```sourcepawn
/*********************************************************
 * Log a message into logs/discord/errors.log
 *
 * @param format    Message to log
 * @noreturn
 *********************************************************/
native void ExtendedDiscord_LogError(const char[] format, any ...);
```

## Performance & Best Practices

### Performance Considerations
- Minimize operations in frequently called functions (`OnGameFrame`, timer callbacks)
- Cache expensive operations (Steam API responses stored in `g_sClientAvatar`)
- Use efficient data structures (StringMap for key-value lookups)
- Avoid string operations in hot code paths
- Consider server tick rate impact

### Memory Management
```sourcepawn
// Good: Proper cleanup of JSON objects
JSONObject json = view_as<JSONObject>(response.Data);
if (json == null) return;

JSONObject responseObj = view_as<JSONObject>(json.Get("response"));
delete json;  // Clean up immediately after use

// Handle arrays and nested objects
JSONArray players = view_as<JSONArray>(responseObj.Get("players"));
delete responseObj;

if (players != null) {
    // Use array, then clean up
    delete players;
}
```

### Error Handling Patterns
```sourcepawn
// HTTP Response validation
if (response.Status != HTTPStatus_OK)
    return;

// Client validation in async callbacks
int iClient = GetClientOfUserId(userid);
if (iClient < 1) {
    delete dataHandle;  // Clean up before return
    return;
}

// ConVar validation
if (!g_sAPIKey[0]) {
    LogError("Invalid or no STEAM API Key specified.");
    return;
}
```

## Testing & Validation

### Manual Testing Checklist
- Load plugin on development server
- Test Steam avatar fetching for multiple clients
- Verify error logging functionality
- Test ConVar changes (discord_apikey)
- Validate client connect/disconnect handling
- Check memory usage with `sm_memory` command

### Integration Testing
- Test with DiscordWebhookAPI plugin loaded
- Verify native function calls from other plugins
- Test forward calls (`ExtendedDiscord_OnErrorLogged`)
- Validate Steam API integration with real API key

### Common Issues to Check
- Steam API key configuration
- HTTP request timeouts
- JSON parsing errors
- Client index validation
- Memory leaks from uncleaned handles

## CI/CD & Version Control

### Automated Build Process
- GitHub Actions automatically builds on push/PR
- Uses SourceKnight for compilation
- Creates release artifacts
- Manages version tagging (`latest` for main branch)

### Commit Guidelines
- Use descriptive commit messages
- Follow semantic versioning for releases
- Update plugin version in `myinfo` block for releases
- Don't commit build artifacts (`.smx` files are gitignored)

### Release Process
- Tag commits for versioned releases
- CI automatically creates GitHub releases
- Artifacts include compiled plugins and dependencies

## Configuration & Deployment

### ConVar Configuration
```sourcepawn
// Required ConVar for Steam API functionality
discord_apikey "your_steam_api_key_here"  // Get from https://steamcommunity.com/dev/apikey
```

### Plugin Dependencies
Ensure these are loaded before Extended_Discord:
- `discordWebhookAPI.smx` (required dependency)

### Log File Management
- Error logs: `logs/discord/errors.log`
- Ensure log directory exists and is writable
- Monitor log size in production environments

## Troubleshooting Common Issues

### Build Errors
- Ensure SourceKnight dependencies are up to date
- Check include paths for DiscordWebhookAPI
- Verify SourceMod version compatibility

### Runtime Errors
- Check Steam API key validity and permissions
- Verify DiscordWebhookAPI plugin is loaded
- Monitor server logs for HTTP request failures
- Validate client authentication timing

### Performance Issues
- Monitor `g_sClientAvatar` array usage
- Check HTTP request frequency
- Review timer usage and cleanup
- Use SourceMod profiler for performance analysis

## Additional Resources

- [SourceMod Documentation](https://docs.sourcemod.net/)
- [SourcePawn Language Reference](https://docs.sourcemod.net/api/)
- [SourceKnight Documentation](https://github.com/srcdslab/sourceknight)
- [Steam Web API Documentation](https://developer.valvesoftware.com/wiki/Steam_Web_API)