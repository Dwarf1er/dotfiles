obs = obslua

-- script properties
local source_name_life_total = "LifeTotal"
local source_name_commander_damage_1 = "CommanderDamage1"
local source_name_commander_damage_2 = "CommanderDamage2"
local source_name_commander_damage_3 = "CommanderDamage3"
local starting_life_total = 40

-- counters
local life_total = 40
local commander_damage_1 = 0
local commander_damage_2 = 0
local commander_damage_3 = 0

-- hotkeys
local hotkey_id_increase_life = obs.OBS_INVALID_HOTKEY_ID
local hotkey_id_decrease_life = obs.OBS_INVALID_HOTKEY_ID
local hotkey_id_increase_damage_1 = obs.OBS_INVALID_HOTKEY_ID
local hotkey_id_increase_damage_2 = obs.OBS_INVALID_HOTKEY_ID
local hotkey_id_increase_damage_3 = obs.OBS_INVALID_HOTKEY_ID
local hotkey_id_reset = obs.OBS_INVALID_HOTKEY_ID

-- set the script description
function script_description()
    return "A script to change the values of text sources with hotkeys. Useful for tracking life totals in MTG Commander.\n\n" ..
           "Instructions:\n" ..
           "1. Set the 'Life Total Text Source' to the name of your text source for your life total.\n" ..
           "2. Set the 'Commander Damage 1 Text Source' to the name of your text source for the damage counter from commander 1.\n" ..
           "3. Set the 'Commander Damage 2 Text Source' to the name of your text source for the damage counter from commander 2.\n" ..
           "4. Set the 'Commander Damage 3 Text Source' to the name of your text source for the damage counter from commander 3.\n" ..
           "5. Go to 'Settings' -> 'Hotkeys' and assign keys for all hotkeys that start with 'MTG'"
end

-- set the script properties
function script_properties()
    local props = obs.obs_properties_create()

    -- Add text fields for each source name
    obs.obs_properties_add_text(props, "source_name_life_total", "Life Total Text Source", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "source_name_commander_damage_1", "Commander Damage 1 Text Source", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "source_name_commander_damage_2", "Commander Damage 2 Text Source", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "source_name_commander_damage_3", "Commander Damage 3 Text Source", obs.OBS_TEXT_DEFAULT)

    -- Add integer field for starting life total
    obs.obs_properties_add_int(props, "starting_life_total", "Starting Life Total", 0, 100, 1)
    return props
end

-- general text source update
local function update_text_source(source_name, text)
    local source = obs.obs_get_source_by_name(source_name)
    if source ~= nil then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", text)
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    else
        print("Source not found: " .. source_name)
    end
end

-- increase life hotkey callback
local function increase_life(pressed)
    if pressed then
        life_total = life_total + 1
        update_text_source(source_name_life_total, tostring(life_total))
    end
end

-- decrease life hotkey callback
local function decrease_life(pressed)
    if pressed then
        life_total = life_total - 1
        update_text_source(source_name_life_total, tostring(life_total))
    end
end

-- increase commander damage 1 hotkey callback
local function increase_commander_damage_1(pressed)
    if pressed then
        commander_damage_1 = commander_damage_1 + 1
        life_total = life_total - 1
        update_text_source(source_name_commander_damage_1, tostring(commander_damage_1))
        update_text_source(source_name_life_total, tostring(life_total))
    end
end

-- increase commander damage 2 hotkey callback
local function increase_commander_damage_2(pressed)
    if pressed then
        commander_damage_2 = commander_damage_2 + 1
        life_total = life_total - 1
        update_text_source(source_name_commander_damage_2, tostring(commander_damage_2))
        update_text_source(source_name_life_total, tostring(life_total))
    end
end

-- increase commander damage 3 hotkey callback
local function increase_commander_damage_3(pressed)
    if pressed then
        commander_damage_3 = commander_damage_3 + 1
        life_total = life_total - 1
        update_text_source(source_name_commander_damage_3, tostring(commander_damage_3))
        update_text_source(source_name_life_total, tostring(life_total))
    end
end

-- reset all text sources to default values hotkey callback
local function reset_all(pressed)
    if pressed then
        life_total = starting_life_total
        commander_damage_1 = 0
        commander_damage_2 = 0
        commander_damage_3 = 0
        update_text_source(source_name_life_total, tostring(life_total))
        update_text_source(source_name_commander_damage_1, tostring(commander_damage_1))
        update_text_source(source_name_commander_damage_2, tostring(commander_damage_2))
        update_text_source(source_name_commander_damage_3, tostring(commander_damage_3))
    end
end

-- load the script settings and register the hotkeys
function script_load(settings)
    source_name_life_total = obs.obs_data_get_string(settings, "source_name_life_total")
    source_name_commander_damage_1 = obs.obs_data_get_string(settings, "source_name_commander_damage_1")
    source_name_commander_damage_2 = obs.obs_data_get_string(settings, "source_name_commander_damage_2")
    source_name_commander_damage_3 = obs.obs_data_get_string(settings, "source_name_commander_damage_3")
    starting_life_total = obs.obs_data_get_int(settings, "starting_life_total")

    life_total = starting_life_total

    hotkey_id_increase_life = obs.obs_hotkey_register_frontend("increase_life", "MTG Increase Life Total", increase_life)
    hotkey_id_decrease_life = obs.obs_hotkey_register_frontend("decrease_life", "MTG Decrease Life Total", decrease_life)
    hotkey_id_increase_damage_1 = obs.obs_hotkey_register_frontend("increase_damage_1", "MTG Increase Commander Damage 1", increase_commander_damage_1)
    hotkey_id_increase_damage_2 = obs.obs_hotkey_register_frontend("increase_damage_2", "MTG Increase Commander Damage 2", increase_commander_damage_2)
    hotkey_id_increase_damage_3 = obs.obs_hotkey_register_frontend("increase_damage_3", "MTG Increase Commander Damage 3", increase_commander_damage_3)
    hotkey_id_reset = obs.obs_hotkey_register_frontend("reset_all", "MTG Reset All Values", reset_all)

    local hotkey_save_array_increase_life = obs.obs_data_get_array(settings, "increase_life_hotkey")
    obs.obs_hotkey_load(hotkey_id_increase_life, hotkey_save_array_increase_life)
    obs.obs_data_array_release(hotkey_save_array_increase_life)

    local hotkey_save_array_decrease_life = obs.obs_data_get_array(settings, "decrease_life_hotkey")
    obs.obs_hotkey_load(hotkey_id_decrease_life, hotkey_save_array_decrease_life)
    obs.obs_data_array_release(hotkey_save_array_decrease_life)

    local hotkey_save_array_increase_damage_1 = obs.obs_data_get_array(settings, "increase_damage_1_hotkey")
    obs.obs_hotkey_load(hotkey_id_increase_damage_1, hotkey_save_array_increase_damage_1)
    obs.obs_data_array_release(hotkey_save_array_increase_damage_1)

    local hotkey_save_array_increase_damage_2 = obs.obs_data_get_array(settings, "increase_damage_2_hotkey")
    obs.obs_hotkey_load(hotkey_id_increase_damage_2, hotkey_save_array_increase_damage_2)
    obs.obs_data_array_release(hotkey_save_array_increase_damage_2)

    local hotkey_save_array_increase_damage_3 = obs.obs_data_get_array(settings, "increase_damage_3_hotkey")
    obs.obs_hotkey_load(hotkey_id_increase_damage_3, hotkey_save_array_increase_damage_3)
    obs.obs_data_array_release(hotkey_save_array_increase_damage_3)

    local hotkey_save_array_reset = obs.obs_data_get_array(settings, "reset_all_hotkey")
    obs.obs_hotkey_load(hotkey_id_reset, hotkey_save_array_reset)
    obs.obs_data_array_release(hotkey_save_array_reset)

    update_text_source(source_name_life_total, tostring(life_total))
    update_text_source(source_name_commander_damage_1, tostring(commander_damage_1))
    update_text_source(source_name_commander_damage_2, tostring(commander_damage_2))
    update_text_source(source_name_commander_damage_3, tostring(commander_damage_3))
end

-- save the script settings
function script_save(settings)
    obs.obs_data_set_string(settings, "source_name_life_total", source_name_life_total)
    obs.obs_data_set_string(settings, "source_name_commander_damage_1", source_name_commander_damage_1)
    obs.obs_data_set_string(settings, "source_name_commander_damage_2", source_name_commander_damage_2)
    obs.obs_data_set_string(settings, "source_name_commander_damage_3", source_name_commander_damage_3)
    obs.obs_data_set_int(settings, "starting_life_total", starting_life_total)

    local hotkey_save_array_increase_life = obs.obs_hotkey_save(hotkey_id_increase_life)
    obs.obs_data_set_array(settings, "increase_life_hotkey", hotkey_save_array_increase_life)
    obs.obs_data_array_release(hotkey_save_array_increase_life)

    local hotkey_save_array_decrease_life = obs.obs_hotkey_save(hotkey_id_decrease_life)
    obs.obs_data_set_array(settings, "decrease_life_hotkey", hotkey_save_array_decrease_life)
    obs.obs_data_array_release(hotkey_save_array_decrease_life)

    local hotkey_save_array_increase_damage_1 = obs.obs_hotkey_save(hotkey_id_increase_damage_1)
    obs.obs_data_set_array(settings, "increase_damage_1_hotkey", hotkey_save_array_increase_damage_1)
    obs.obs_data_array_release(hotkey_save_array_increase_damage_1)

    local hotkey_save_array_increase_damage_2 = obs.obs_hotkey_save(hotkey_id_increase_damage_2)
    obs.obs_data_set_array(settings, "increase_damage_2_hotkey", hotkey_save_array_increase_damage_2)
    obs.obs_data_array_release(hotkey_save_array_increase_damage_2)

    local hotkey_save_array_increase_damage_3 = obs.obs_hotkey_save(hotkey_id_increase_damage_3)
    obs.obs_data_set_array(settings, "increase_damage_3_hotkey", hotkey_save_array_increase_damage_3)
    obs.obs_data_array_release(hotkey_save_array_increase_damage_3)

    local hotkey_save_array_reset = obs.obs_hotkey_save(hotkey_id_reset)
    obs.obs_data_set_array(settings, "reset_all_hotkey", hotkey_save_array_reset)
    obs.obs_data_array_release(hotkey_save_array_reset)
end

-- update the script when properties change
function script_update(settings)
    source_name_life_total = obs.obs_data_get_string(settings, "source_name_life_total")
    source_name_commander_damage_1 = obs.obs_data_get_string(settings, "source_name_commander_damage_1")
    source_name_commander_damage_2 = obs.obs_data_get_string(settings, "source_name_commander_damage_2")
    source_name_commander_damage_3 = obs.obs_data_get_string(settings, "source_name_commander_damage_3")
    starting_life_total = obs.obs_data_get_int(settings, "starting_life_total")

    life_total = starting_life_total
    update_text_source(source_name_life_total, tostring(life_total))
    update_text_source(source_name_commander_damage_1, tostring(commander_damage_1))
    update_text_source(source_name_commander_damage_2, tostring(commander_damage_2))
    update_text_source(source_name_commander_damage_3, tostring(commander_damage_3))
end
