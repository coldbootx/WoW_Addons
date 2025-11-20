AdvancedAutoInvite v1.0 - WoW Classic Addon
===========================================

A lightweight addon that automatically invites players to your party when they whisper you a specific keyword.

FEATURES
--------
• Auto-invite players based on whisper keyword
• Configurable invite keyword (default: "inv")
• Toggle auto-invite on/off
• Settings persist between game sessions
• Colorful chat feedback
• Short command alias (/aai)

INSTALLATION
------------
1. Extract the addon folder to your WoW Classic AddOns directory:
   World of Warcraft\_classic_\Interface\AddOns\

2. The folder structure should look like:
   \Interface\AddOns\AdvancedAutoInvite\AdvancedAutoInvite.lua
   \Interface\AddOns\AdvancedAutoInvite\AdvancedAutoInvite.toc
   \Interface\AddOns\AdvancedAutoInvite\readme.txt

USAGE
-----
BASIC USAGE:
- When auto-invite is enabled, any player who whispers you the exact keyword will be automatically invited
- Works when you are solo or party leader
- Default keyword is "inv" (exact match only)

SLASH COMMANDS:
/advancedautoinvite help     - Show help message
/advancedautoinvite version  - Show addon version
/advancedautoinvite setinv   - Set invite keyword
/advancedautoinvite toggle   - Enable/disable auto-invite
/advancedautoinvite status   - Show current settings

SHORT ALIAS:
/aai [command]              - Same as /advancedautoinvite

EXAMPLES:
/advancedautoinvite setinv invite
/advancedautoinvite toggle
/aai status

CONFIGURATION
-------------
The addon automatically saves your settings:
- Invite keyword
- Auto-invite enabled/disabled status

These are stored in the WoW saved variables and will persist between game sessions.

CHAT KEYWORD EXAMPLES:
Player whispers you: "inv"          → Auto-invited
Player whispers you: "invite"       → Not invited (unless keyword changed)
Player whispers you: "inv me"       → Not invited (exact match only)
Player whispers you: "INV"          → Auto-invited (case insensitive)
Player whispers you: "inv for nax" → Not invited (exact match only)

REQUIREMENTS
------------
• World of Warcraft: Classic
• No dependencies

SUPPORT
-------
If you encounter any issues:
1. Make sure the addon is enabled in your addons list
2. Type "/aai status" to check current settings
3. Verify you are solo or party leader

VERSION HISTORY
---------------
v1.0 - Initial release
- Auto-invite functionality
- Configurable keyword
- Persistent settings
- Colorful UI feedback
- Exact keyword matching

AUTHOR
------
Created for the WoW Classic community by Feroartt

LICENSE
-------
MIT: Free to use and modify.