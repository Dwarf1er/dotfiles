# OBS MTG Life Tracker Script

## Overview
This script allows you to track life totals and commander damage in Magic: The Gathering Commander games using OBS. Life totals and commander damage counters are displayed as text sources in your OBS scene and can be adjusted using hotkeys.

## Instructions

### Step 1: Add Text Sources
1. In OBS, add text sources to your scene with the following names:
   - `LifeTotal`
   - `CommanderDamage1`
   - `CommanderDamage2`
   - `CommanderDamage3`

### Step 2: Add the Script
1. Open OBS, go to `Tools` -> `Scripts`.
2. Click on the `+` button to add a new script.
3. Select the script file (`mtg-life-counter.lua`) and click `Open`.

### Step 3: Configure the Script
1. In the `Scripts` window, select the `mtg-life-counter` script.
2. If you used different names for your text sources, update the source names in the script properties.
3. Set the `Starting Life Total` to your desired initial life total (default is 40).

### Step 4: Set Hotkeys
1. Go to `Settings` -> `Hotkeys`.
2. In `Filter` search for `MTG` to list the hotkeys for this script
3. Assign keys for the following actions:
   - `MTG Increase Life Total` [recommendation: up arrow]
   - `MTG Decrease Life Total` [recommendation: down arrow]
   - `MTG Increase Commander Damage 1` [recommendation: 1]
   - `MTG Increase Commander Damage 2` [recommendation: 2]
   - `MTG Increase Commander Damage 3` [recommendation: 3]
   - `MTG Reset All Values` [recommendation: R]

### Usage
- Use the assigned hotkeys to increase/decrease the life total and commander damage counters.
- When the life total reaches 0 or any commander damage reaches 21, the life total will display a skull emoji.

Enjoy your game!

## Troubleshooting
- Ensure that the text source names match those configured in the script properties.
- Check that hotkeys are correctly assigned in OBS settings.
