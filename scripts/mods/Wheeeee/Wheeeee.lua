local mod = get_mod("Wheeeee")
local Audio = get_mod("Audio")
local MiniAudio = get_mod("MiniAudioAddon")
local Unit = rawget(_G, "Unit")

mod.version = "2.4"

-- Validate MiniAudio dependencies early (like ElevatorMusic does)
if not MiniAudio or not MiniAudio.playlist_manager then
    mod:echo("[Wheeeee] MiniAudioAddon with playlist_manager required for spatial audio")
end

local PlaylistManager = MiniAudio and MiniAudio.playlist_manager
local IOUtils = MiniAudio and MiniAudio.IOUtils

local PLAYLIST_ID = "wheeeee_catapult"
local play_counter = 0

-- Register playlist at file load time (like ElevatorMusic)
if PlaylistManager then
    PlaylistManager.register(PLAYLIST_ID, {
        mod = mod,
        resolve_folder = function()
            if IOUtils and IOUtils.resolve_mod_audio_folder then
                mod:echo("resolving folder")
                local folder = IOUtils.resolve_mod_audio_folder(mod, "audio")
                if folder then
                    return folder
                end
            end
            return string.format("mods/%s/audio", mod:get_name())
        end,
        log_prefix = "[Wheeeee]",
    })
end

-- Check if a unit is alive
local function is_unit_alive(unit)
    if not unit then return false end
    return Unit.alive(unit)
end

-- Get unit directly from stack level 5
local function get_unit_from_stack_level_5()
    if not debug.getinfo(5) then
        return nil
    end
    
    local v = 1
    while true do
        local name, value = debug.getlocal(5, v)
        if not name then
            return nil
        end
        if is_unit_alive(value) then
            return value
        end
        v = v + 1
    end
end

-- Get position from unit
local function get_position(unit)
    return unit and Unit.world_position(unit, 1) or nil
end

-- Play spatial sound using MiniAudio api.play with playlist
local function play_spatial_sound(unit)
    if not MiniAudio or not MiniAudio.api or not PlaylistManager or not is_unit_alive(unit) then
        return false
    end
    
    local pos = get_position(unit)
    if not pos then
        return false
    end
    
    -- Get random track from playlist (force_scan on first call like ElevatorMusic)
    local audio_path = PlaylistManager.next(PLAYLIST_ID, { random = true, force_scan = true })
    if not audio_path then
        return false
    end
    
    play_counter = play_counter + 1
    local track_id = string.format("wheeeee_%d", play_counter)
    
    local ok = MiniAudio.api.play({
        id = track_id,
        path = audio_path,
        loop = false,
        volume = 0.1,
        profile = { min_distance = 1, max_distance = 50, rolloff = "linear" },
        source = {
            position = { pos.x, pos.y, pos.z },
            forward = { 0, 0, 1 },
            velocity = { 0, 0, 0 },
        },
    })
    
    return ok
end

local acceptable_locations = {
    coop_complete_objective = true,
    survival = true,
    shooting_range = true,
}

mod.on_all_mods_loaded = function()
    mod:info(mod.version)
    
    if Audio then
        Audio.hook_sound("play_player_combat_experience_catapulted", function(_, name, delta)
            if delta and delta < 0.1 then
                return true
            end
            
            local unit = get_unit_from_stack_level_5()
            
            if MiniAudio and PlaylistManager and unit then
                play_spatial_sound(unit)
            elseif Audio then
                -- Fallback to Audio mod
                Audio.play_file("Voicy_Tom Scream.mp3", { audio_type = "sfx" })
            end
            
            return true
        end)
    end
end

-- Rescan playlist when mod is enabled (like ElevatorMusic does)
mod.on_enabled = function()
    if PlaylistManager then
        PlaylistManager.force_scan(PLAYLIST_ID)
    end
end