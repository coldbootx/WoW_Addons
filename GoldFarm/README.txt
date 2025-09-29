# GoldFarm Addon

## Overview
GoldFarm is a World of Warcraft addon that helps you track gold earned during farming sessions. It monitors looted gold, group loot, vendor sales, and repair costs to give you a complete picture of your gold-making activities.

## Installation
1. Download the GoldFarm addon
2. Extract the folder into your World of Warcraft\_retail_\Interface\AddOns directory
   (or World of Warcraft\_classic_\Interface\AddOns for Classic WoW)
3. Make sure the folder is named "GoldFarm" (remove any -master or version suffixes)
4. Launch or restart World of Warcraft
5. Ensure the addon is enabled in the addon list before entering the game

## Features
- Track gold earned from looting
- Monitor group loot contributions
- Track vendor sales (items and junk)
- Account for repair costs
- Session-based tracking with timer
- Movable GUI display
- Minimap button for quick access
- Export session data for record keeping

## Commands
All commands can be accessed using either `/goldfarm` or the shorter `/gf` prefix:

- `/goldfarm help` - Show available commands
- `/goldfarm start` - Start a new tracking session
- `/goldfarm stop` - Stop the current session and save it
- `/goldfarm reset` - Reset the current session data
- `/goldfarm show` - Show the GUI display
- `/goldfarm hide` - Hide the GUI display
- `/goldfarm export` - Export session data to chat
- `/goldfarm version` - Show addon version

## Using the Addon

### Starting a Session
1. Type `/goldfarm start` or click the gold coin minimap button to begin tracking
2. The addon will start monitoring all gold-related activities
3. The GUI will display your current session information

### During a Session
The addon automatically tracks:
- Gold from monster loot
- Gold from group loot
- Gold earned from selling items to vendors
- Gold spent on repairs

### Ending a Session
1. Type `/goldfarm stop` or click the minimap button again
2. Your session will be saved and tracking will stop
3. You can view the results in the GUI or export them with `/goldfarm export`

### GUI Display
- The GUI shows your current gold and session statistics
- To move the GUI: Hold Shift + Left-click and drag
- The display updates in real-time during an active session

### Minimap Button
- Left-click: Start/Stop session
- Right-click: Reset current session
- The button shows green when a session is active and red when inactive

## Support
If you encounter any issues or have suggestions for improvements, please report them on the project's GitHub page or contact the author.

## Credits
GoldFarm addon created by [Your Name]