# Life-System AMX Mod X Plugin

## Overview
This plugin, named Life-System, adds a life-sharing functionality to Counter-Strike servers using AMX Mod X. Players can offer their lives to teammates, promoting teamwork and strategic play. The plugin includes commands and menus for easy interaction.

## Features
- Players can offer their lives to teammates.
- Command to revive specific players or entire teams.
- Interactive menus for easy navigation.


## Configuration
The plugin provides two cvars for configuration:
- `life_enable`: Enable or disable the life-sharing feature (default is 1).
- `life_players`: Minimum number of players alive required to offer lives (default is 2).

## Commands
- `/life <player>`: Offer your life to a specific player.
- `/lifemenu`: Open an interactive menu to offer lives to teammates.
- `/amx_revive <player/@T/@CT>`: Admin command to revive players or teams.

## Notes
- Admins have immunity and can use the revive command without restrictions.
- Players cannot offer lives if the total number of alive players is below the configured threshold.

Feel free to report any issues or provide feedback on the [GitHub repository](https://github.com/yourusername/Life-System-Plugin). Contributions are welcome!