========================================
Advanced Auto Invite 
========================================

Author: Feroartt
Version: 1.6
License: MIT
CurseForge: https://www.curseforge.com/wow/addons/advancedautoinvite

====================
DESCRIPTION
====================

Advanced Auto Invite is a World of Warcraft Classic Era addon that automatically
invites players to your group when they whisper you a configurable keyword.

Features:
• Auto-invite based on configurable keyword (default: "inv")
• Whisper response with customizable message
• Spam protection with configurable cooldown
• Auto-convert party to raid when full
• GUI configuration panel
• Permission checks (only group leaders can invite)
• Connected realm support
• Slash command interface

====================
INSTALLATION
====================

1. Download the addon from CurseForge
2. Extract to your WoW Classic Era AddOns folder:
   - Windows: \_classic_era_\Interface\AddOns\
   - Mac: ~/Applications/World of Warcraft/_classic_era_/Interface/AddOns/
3. Rename folder to "AdvancedAutoInvite" (remove version number if present)
4. Launch WoW Classic Era
5. Enable "Advanced Auto Invite" in the AddOns menu

====================
BASIC USAGE
====================

1. Type /aai config to open the configuration panel
2. Configure your settings:
   - Enable/Disable auto-invite
   - Set your keyword (default: "inv")
   - Customize whisper response
   - Adjust spam protection settings
   - Enable auto-raid conversion
3. Players can now whisper you your keyword to get invited

Example:
- Player whispers you: "inv"
- Addon automatically invites them to your group
- Sends welcome whisper (if enabled)

====================
SLASH COMMANDS
====================

/aai help         - Show all commands
/aai config       - Open configuration GUI
/aai toggle       - Toggle auto-invite on/off
/aai status       - Show current status
/aai clearcache   - Clear spam protection cache

====================
KEYWORD MATCHING
====================

The addon matches the keyword in several ways:
- Exact match: "inv"
- Start of message: "inv me" or "invite"
- Case insensitive: "INV", "Inv", "iNv"

Spaces are trimmed from the message before matching.

====================
PERMISSIONS
====================

The addon respects group leadership:
- Solo players can always invite
- Only group/raid leaders can invite others
- Non-leaders cannot invite even with keyword

====================
SPAM PROTECTION
====================

Prevents players from spamming invites:
- Tracks when players were last invited
- Configurable cooldown (5-300 seconds)
- Can be disabled in settings

====================
AUTO RAID CONVERSION
====================

When enabled:
- Automatically converts party to raid when full (5 players)
- Only works if you are party leader
- Helps avoid "party is full" issues

====================
WHISPER RESPONSES
====================

Customizable message with placeholders:
- {name} - Replaced with player's name
- Example: "Hello {name}, welcome to the party!"

====================
TROUBLESHOOTING
====================

Q: Addon isn't inviting players
A: 1. Check if auto-invite is enabled (/aai status)
   2. Verify you have invite permissions
   3. Check if group/raid is full
   4. Ensure keyword is configured correctly

Q: Players say they're not getting invited
A: 1. They must whisper the exact keyword
   2. They may be on spam cooldown
   3. They might already be in group

Q: GUI isn't showing
A: 1. Type /aai config
   2. Reload UI (/reload)
   3. Check for errors in chat

Q: Connected realm issues
A: The addon handles connected realms automatically

====================
SAVED VARIABLES
====================

Settings are saved in:
WTF\Account\<Account>\SavedVariables\AdvancedAutoInvite.lua

To reset settings:
1. Delete the above file
2. Reload UI

====================
SUPPORT
====================

Report bugs or request features on CurseForge:
https://www.curseforge.com/wow/addons/advancedautoinvite

====================
AUTHOR
====================

Created for the WoW Classic community by Feroartt

====================
LICENSE
====================

MIT License - See LICENSE file for details