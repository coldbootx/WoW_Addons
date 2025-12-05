Advanced Auto Invite v1.2
========================

A WoW Classic addon that automatically invites players to your party/raid when they whisper you a specific keyword.

Features:
---------
- Auto-invite players based on whisper keyword
- Configurable invite keyword (default: "inv")
- Personalized whisper confirmation messages using {name}
- Spam protection with configurable cooldown timer
- Security checks (cross-realm detection)
- Group capacity checking (prevents over-inviting)
- Easy slash commands for configuration
- Cross-realm player filtering

Installation:
-------------
1. Extract the addon folder to your WoW Classic AddOns directory
   (typically: World of Warcraft/_classic_era_/Interface/AddOns/)
2. Rename the folder to "AdvancedAutoInvite" (remove any version numbers)
3. Restart WoW Classic or type "/reload" in game

Usage:
------
- Type "/aai help" for all available commands
- Default keyword is "inv" - players whisper you "inv" to get invited
- You must be party/raid leader for auto-invites to work
- Use {name} in your whisper message to automatically include the player's name

Slash Commands:
/aai help                 - Show help menu
/aai version              - Show addon version
/aai toggle               - Enable/disable auto-invite
/aai setinv [word]        - Set the invite keyword
/aai whisper [on/off]     - Enable/disable whisper responses
/aai setmessage [text]    - Set custom whisper message
/aai spam [on/off]        - Enable/disable spam protection
/aai cooldown [seconds]   - Set spam cooldown (5-300)
/aai security [on/off]    - Enable/disable security checks
/aai status               - Show current settings
/aai clearcache          - Clear spam protection cache

Configuration Tips:
-------------------
- Keep your keyword simple but unique to avoid accidental triggers
- Set spam cooldown based on your needs (30 seconds recommended)
- Use {name} in your welcome message for personalization
- Security checks prevent cross-realm invites
- Spam protection stops players from spamming invite requests

Personalization:
----------------
Use {name} in your whisper message to automatically include the player's name:
Example: "Hello {name}, welcome to the party!" becomes "Hello PlayerName, welcome to the party!"

Compatibility:
--------------
- Designed for WoW Classic
- Compatible with most other addons
- Uses standard WoW Classic APIs

Support:
------
This addon is provided as-is.
For bugs or feature requests, please contact the author.

AUTHOR
------
Created for the WoW Classic community by Feroartt

LICENSE
-------
MIT: Free to use and modify.