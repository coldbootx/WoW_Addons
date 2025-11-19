README.txt - GoldFarm Addon for World of Warcraft
=================================================

Addon Name: GoldFarm
Version: 1.0.2 (Patched)
Description: Gold tracking and farming statistics addon
Type: Session-based gold income monitoring

OVERVIEW
--------
GoldFarm is a comprehensive gold tracking addon that monitors your income
from various sources during gameplay sessions. It provides real-time
statistics and gold-per-hour calculations to help optimize your
farming efficiency.

FEATURES
--------
1. Session Tracking:
   - Automatic session creation with timestamps
   - Start/stop session functionality
   - Session reset capability

2. Income Sources:
   - Gold looted from monsters and containers
   - Items sold to vendors
   - Repair cost tracking (new in v1.0.2)
   - Net profit calculation

3. Performance Metrics:
   - Gold per hour (GPH) calculation (new feature)
   - Session duration tracking
   - Real-time profit monitoring

4. Data Management:
   - Session data persistence
   - Export functionality
   - Historical session tracking

INSTALLATION
------------
1. Extract the addon folder to your World of Warcraft AddOns directory:
   - Windows: World of Warcraft\_retail_\Interface\AddOns\
   - Mac: World of Warcraft/_retail_/Interface/AddOns/

2. Ensure folder structure is:
   /AddOns/
     └── GoldFarm/
         ├── GoldFarm.toc
         └── GoldFarm.lua

3. Log into the game - the addon loads automatically

CONFIGURATION OPTIONS
----------------------
- guiVisible: Toggle GUI display (default: true)
- minimapButton: Control minimap button visibility and position
- Automatic session management

INCOME SOURCES TRACKED
----------------------
✓ Gold looted directly
✓ Vendor item sales
✓ Repair costs (deducted from profit)
✓ Net total calculation
✓ Gold per hour (GPH) metrics

SLASH COMMANDS:
/goldfarm help     - Show command help
/goldfarm start    - Start new tracking session
/goldfarm stop     - Stop current session
/goldfarm reset    - Reset current session data
/goldfarm show     - Show the GUI
/goldfarm hide     - Hide the GUI
/goldfarm export   - Export current session data
/goldfarm version  - Show version information

Shortcuts:
/gf help  - Same as /goldfarm help

NEW IN VERSION 1.0.2
------------------------
1. Enhanced Repair Tracking:
   - Proper repair cost calculation
   - Accurate net profit reporting

2. Gold Per Hour Calculation:
   - Real-time GPH updates
   - Session-based efficiency metrics

DATA PERSISTENCE
----------------
- Session data automatically saved between game sessions
- Multiple session history maintained
- Current session preserved during logout

DISPLAYED INFORMATION
---------------------
- Session name and duration
- Gold looted from all sources
- Items sold to vendors
- Repair expenses
- Net profit total
- Gold per hour rate

COMPATIBILITY
-------------
- World of Warcraft Retail
- Requires modern WoW API support
- Compatible with most other addons

TROUBLESHOOTING
----------------
1. Data not tracking:
   - Ensure session is running (/goldfarm start)
   - Check if GUI is visible (/goldfarm show)

2. Incorrect calculations:
   - Use /goldfarm reset to clear current session
   - Ensure addon is properly installed

3. GUI not appearing:
   - Use /goldfarm show to force display
   - Check minimap for GoldFarm button

PERFORMANCE NOTES
------------------
- Lightweight design with minimal performance impact
- Efficient event handling system
- Optimized update intervals

AUTHOR & SUPPORT
----------------
This addon is provided as-is. For issues or suggestions, check the
original distribution source.

VERSION HISTORY
---------------
v1.0.2 - Added proper repair tracking, gold per hour calculation
v1.0.1 - Improved session management, added export functionality
v1.0.0 - Initial release with basic gold tracking

ENJOY OPTIMIZING YOUR GOLD FARMING EFFICIENCY!