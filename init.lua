ptracker = {
    player_timer = {},
    player_hud_id = {},
}

local tracked_player = "Hello World!"

local function formspec_error(name, message)
    minetest.chat_send_player(name,
    minetest.colorize("#FF0000", message))
end

minetest.register_tool("ptracker:tracker", {
    description = "Player Tracker",
    inventory_image = "tracker.png",
    on_use = function(itemstack, user, pointed_thing)
        local name = user:get_player_name()
        local timer = ptracker.player_timer[name] or 0

        if timer > 0 then
            formspec_error(name, "Still tracking a player!")
            return
        end

        local formspec = {
            "formspec_version[4]",
            "size[6,5.3]",
            "label[0.375,0.5;Player Tracker]",
            "field[0.375,1.5;5.25,0.8;tracked_player;Player Being Tracked:;]",
            "field[0.375,3;5.25,0.8;duration;Duration of Tracking;]",
            "button[1.5,4.3;3,0.8;track;Track]",
        }
        local formspec = table.concat(formspec, "")

        minetest.show_formspec(name, "ptracker:tracker", formspec)
    end
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "ptracker:tracker" then
        return
    end

    local enter_in_field = fields.key_enter_field
    if fields.track or enter_in_field == "tracked_player" or enter_in_field == "duration" then
        local name = player:get_player_name()
        tracked_player = fields.tracked_player

        minetest.close_formspec(name, "ptracker:tracker")

        if not minetest.player_exists(tracked_player) then
            formspec_error(name, "Player is not real!")
            return
        end

        local tracked_player_ref = minetest.get_player_by_name(tracked_player)

        if not tracked_player_ref then
            formspec_error(name, "Player is not online!")
            return
        end
        
        
        if tonumber(fields.duration) == nil then
            ptracker.player_timer[name] = 10
        else
            ptracker.player_timer[name] = tonumber(fields.duration)
        end

        local timer = ptracker.player_timer[name]

        minetest.chat_send_player(name,
        minetest.colorize("#80FF00", "Tracking " .. tracked_player .. " for " .. tostring(timer) .. " seconds."))

        local function tracker_waypoint()
            return player:hud_add({
                hud_elem_type = "waypoint",
                name = "Player Being Tracked:",
                text = "m",
                number = 0x85FF00,
                world_pos = tracked_player_ref:get_pos()

            })
        end

        ptracker.player_hud_id[name] = tracker_waypoint()

        minetest.after(timer, function()
            player:hud_remove(ptracker.player_hud_id[name])
            formspec_error(name, "Stopped tracking " .. tracked_player .. ".")
            ptracker.player_hud_id[name] = nil
            ptracker.player_timer[name] = -1
        end)
    end
end)

minetest.register_globalstep(function(dtime)
    for _, player in pairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local hud_id = ptracker.player_hud_id[name]
        if ptracker.player_timer[name] ~= 0 and hud_id ~= nil then
            local tracked_player_ref = minetest.get_player_by_name(tracked_player)
            local pos = tracked_player_ref:get_pos()
            player:hud_change(hud_id, "world_pos", pos)
            player:hud_change(hud_id, "name", "Player Being Tracked: " .. minetest.pos_to_string(pos, 1))
        end
    end
end)

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    ptracker.player_timer[name] = nil
end)
