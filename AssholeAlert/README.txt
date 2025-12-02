README.txt - AssholeAlert Addon for World of Warcraft
====================================================

Addon Name: AssholeAlert
Description: Player proximity detection and alert system
Type: Integrated flashing-text alert only (no GUI frame)

OVERVIEW
--------
AssholeAlert is a lightweight addon that monitors for nearby players
and triggers visual alerts when specific tracked players are detected.
The addon uses flashing text at the top of the screen for maximum visibility.

FEATURES
--------
1. Detection System:
   - Real-time player proximity monitoring
   - Nameplate-based detection with GUID fallback
   - Zone-based filtering (excludes safe areas)
   - Configurable detection distance

2. Alert System:
   - Flashing text alerts at top center of screen
   - Color-coded chat notifications
   - Optional sound alerts
   - Alert cooldown system to prevent spam

3. Visual Elements:
   - Large, outlined text with scaling
   - Multiple flash cycles for attention
   - High frame strata for visibility

CONFIGURATION OPTIONS
---------------------
- checkInterval: Detection scan interval (default: 1.0 seconds)
- alertDistance: Detection range in yards (default: 500)
- alertCooldown: Minimum time between alerts (default: 3 seconds)
- enableSound: Toggle sound alerts
- enableFlashing: Toggle flashing text
- enableZoneFiltering: Toggle zone-based detection
- enableGUIDFallback: Use GUID when player detection is uncertain
- enableDetectAny: Alert on any named nameplate (including NPCs)
- enableNameplateRangeFallback: Use nameplate visibility as range indicator

INSTALLATION
------------
1. Extract the addon folder to your World of Warcraft AddOns directory:
   - Windows: World of Warcraft\_retail_\Interface\AddOns\
   - Mac: World of Warcraft/_retail_/Interface/AddOns/

2. Ensure folder structure is:
   /AddOns/
     └── AssholeAlert/
         ├── AssholeAlert.toc
         └── AssholeAlert.lua

USAGE
-----
The addon automatically starts monitoring when you log into the game.

SLASH COMMANDS:
/aa help          - Show command help
/aa add <name>    - Add player to tracking list
/aa remove <name> - Remove player from tracking list
/aa list          - Show all tracked players
/aa clear         - Clear the tracking list
/aa test          - Test the alert system
/aa scan          - Force immediate detection scan
/aa zone          - Show current zone information
/aa nameplatefix  - Attempt to enable player nameplates via CVars
/aa any on|off    - Enable/disable any-nameplate detection
/aa range <yards> - Set alert detection distance

DEFAULT EXCLUDED ZONES
----------------------
- Orgrimmar
- Ironforge
- Thunder Bluff
- Undercity

(Note: Stormwind City and Darnassus are commented out but can be enabled)

TRACKING MECHANICS
------------------
- Player names are normalized to uppercase for consistent matching
- Realm suffixes are automatically stripped
- Names are validated for length and format
- Detection works in combat and while moving

DETECTION MODES
---------------
1. Normal Mode (default):
   - Only alerts for players in the tracking list
   - Uses precise position calculations when available

2. Noisy Detection Mode (/aa any on):
   - Alerts on any named nameplate (including NPCs)
   - Useful for general player awareness

PERFORMANCE NOTES
-----------------
- Lightweight design with configurable update intervals
- Debug mode disabled by default (can be enabled in code)
- Minimal impact on game performance

TROUBLESHOOTING
---------------
1. Alerts not triggering:
   - Check if current zone is excluded
   - Verify player is in tracking list (/aa list)
   - Ensure nameplates are enabled (use /aa nameplatefix)
   - Check distance settings (/aa range)

2. Player not detected:
   - Ensure player nameplates are visible
   - Try enabling GUID fallback (in code)
   - Use noisy detection mode (/aa any on)

3. Performance issues:
   - Increase checkInterval in configuration
   - Disable sound alerts if not needed

SECURITY & PRIVACY
------------------
- Only monitors publicly visible nameplates
- Does not access any private player data
- Compliant with WoW addon policies

VERSION INFORMATION
-------------------
Current version features integrated flashing-text alert system only.
Previous GUI frame functionality has been removed.

COMPATIBILITY
-------------
- World of Warcraft Retail
- Requires modern WoW API support

AUTHOR NOTES
------------
Created for the WoW Classic community by Feroartt

SUPPORT
-------
For issues or feature requests, check the addon's distribution source.
