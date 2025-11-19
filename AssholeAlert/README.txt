AssholeAlert - README

What it does:
- Scans nearby nameplates for players and alerts you (flashing text + chat + optional sound) when a tracked player is detected.

Installation:
- Place the `AssholeAlert` folder into:
  `...\\World of Warcraft\\_classic_era_\\Interface\\AddOns\\`
- Make sure the `AssholeAlert.toc` file contains the saved-variables line:
  `## SavedVariables: AssholeAlertDB`
  Without this line, tracked names will not persist across reloads/logouts.
- Reload UI (`/reload`) after installing.

Usage (slash commands):
- ` /aa help` : Show help and available commands.
- ` /aa add <playername>` : Add a player to the tracking list. Realm suffix (Name-Realm) is accepted and stripped.
- ` /aa remove <playername>` : Remove a player from the tracking list.
- ` /aa list` : Show tracked players.
- ` /aa clear` : Clear the tracking list.
- ` /aa test` : Trigger a test alert (visual + sound if enabled).
- ` /aa scan` : Force an immediate scan.
- ` /aa nameplatefix` : Attempt to set nameplate CVars so enemy nameplates are visible.
- ` /aa any on|off` : Enable/disable "any-nameplate" detection (noisy mode). Default: OFF.
- ` /aa range <yards>` : Set detection distance in yards (default: 30).

Defaults and config:
- Default detection distance: 30 yards.
- `enableDetectAny` (noisy any-nameplate detection): OFF by default.
- `alertWhenEmpty`: OFF by default (the addon will not auto-alert just because your tracked list is empty).
- Saved config and tracked players are stored in the global `AssholeAlertDB` table.

Saved Variables:
- The addon saves to `AssholeAlertDB` with two fields:
  - `config` : runtime config values (alertDistance, enableDetectAny, etc.)
  - `trackedPlayers` : table of normalized tracked names (uppercase keys)
- Changes are written on calls that update data (Add/Remove/Clear/SetDetectAny), but the client writes saved-variable files to disk on `/reload` or logout.

Name handling and restrictions:
- Names are validated and normalized to uppercase when saved.
- The validator only accepts basic A–Z characters (no punctuation or accented letters). If you need broader support, the validator can be relaxed.
- You may add names with realm suffixes (Name-Realm); the addon strips suffixes when saving.

Troubleshooting:
- Saved list not persisting: confirm `AssholeAlert.toc` includes `## SavedVariables: AssholeAlertDB`, then add a name and `/reload` to force write-to-disk.
- No nameplates detected: run ` /aa nameplatefix`, check interface -> names/nameplates settings, or disable third-party nameplate addons.
- No alerts despite tracked names: confirm tracked names with ` /aa list`, ensure you are within set range (`/aa range`), and ensure nameplates for enemies are visible to the client.
- If UnitPosition is unavailable (Classic client quirk), the addon uses a nameplate-range fallback if enabled.

Privacy / Safety:
- The addon only reads nameplate/unit info provided by the client (UnitName, UnitGUID, UnitIsPlayer, UnitPosition) and stores tracked names locally in `AssholeAlertDB` on your machine.

Advanced / Next steps (optional):
- Add a lightweight manual diagnostics command that prints counts (nameplates found, tracked players) instead of verbose dumps.
- Add combat-log fallback to detect tracked players when nameplates are hidden.
