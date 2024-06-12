obs = obslua

life_total = 40
source_name = "LifeTotal"

hotkey_id_increase = obs.OBS_INVALID_HOTKEY_ID
hotkey_id_decrease = obs.OBS_INVALID_HOTKEY_ID

function update_life_total()
    local source = obs.obs_get_source_by_name(source_name)
    if source ~= nil then
        local settings = obs.obs_data_create()
        obs.obs_data_set_string(settings, "text", tostring(life_total))
        obs.obs_source_update(source, settings)
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    else
        print("Source not found: " .. source_name)
    end
end

function increase_life_total(pressed)
    if pressed then
        life_total = life_total + 1
        update_life_total()
        print("Life total increased to " .. life_total)
    end
end

function decrease_life_total(pressed)
    if pressed then
        life_total = life_total - 1
        update_life_total()
        print("Life total decreased to " .. life_total)
    end
end

function script_description()
    return "A script to change the value of a text source with up and down arrow keys. Useful for tracking life totals in MTG Commander.\n\n" ..
           "Instructions:\n" ..
           "1. Set the 'Text Source' to the name of your text source.\n" ..
           "2. Go to 'Settings' -> 'Hotkeys' and assign keys for 'Increase Life Total' and 'Decrease Life Total'."
end

function script_load(settings)
    hotkey_id_increase = obs.obs_hotkey_register_frontend("increase_life_total", "Increase Life Total", increase_life_total)
    hotkey_id_decrease = obs.obs_hotkey_register_frontend("decrease_life_total", "Decrease Life Total", decrease_life_total)
    local hotkey_save_array_increase = obs.obs_data_get_array(settings, "increase_life_total_hotkey")
    obs.obs_hotkey_load(hotkey_id_increase, hotkey_save_array_increase)
    obs.obs_data_array_release(hotkey_save_array_increase)
    local hotkey_save_array_decrease = obs.obs_data_get_array(settings, "decrease_life_total_hotkey")
    obs.obs_hotkey_load(hotkey_id_decrease, hotkey_save_array_decrease)
    obs.obs_data_array_release(hotkey_save_array_decrease)
    update_life_total()
end

function script_update(settings)
    source_name = obs.obs_data_get_string(settings, "source_name")
    update_life_total()
end

function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_text(props, "source_name", "Text Source", obs.OBS_TEXT_DEFAULT)
    return props
end

function script_save(settings)
    local hotkey_save_array_increase = obs.obs_hotkey_save(hotkey_id_increase)
    obs.obs_data_set_array(settings, "increase_life_total_hotkey", hotkey_save_array_increase)
    obs.obs_data_array_release(hotkey_save_array_increase)

    local hotkey_save_array_decrease = obs.obs_hotkey_save(hotkey_id_decrease)
    obs.obs_data_set_array(settings, "decrease_life_total_hotkey", hotkey_save_array_decrease)
    obs.obs_data_array_release(hotkey_save_array_decrease)
end
