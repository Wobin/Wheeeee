local mod = get_mod("Wheeeee")
local audio = get_mod("Audio")

local audio_files = nil
mod.version = "2.0"

mod.on_game_state_changed = function(status, state_name)
	if state_name == "GameplayStateRun" and status == "enter" and not audio_files then
      mod.init()
  end
end

mod.init = function()
  audio_files = audio.new_files_handler({"Voicy_Tom Scream.mp3"})
end

local acceptable_locations = {}
acceptable_locations["coop_complete_objective"] = true
acceptable_locations["survival"] = true
acceptable_locations["shooting_range"] = true

mod.on_all_mods_loaded = function()
  mod:info(mod.version)  

  audio.hook_sound("play_player_combat_experience_catapulted", function(_, name, delta)            
      if (delta == nil or delta > 0.1) and (audio_files and audio_files:count() > 0) then                      
          audio.play_file(audio_files:random(), {audio_type = "sfx"})
        end
      return true
    end)

    local game_mode_manager = Managers.state.game_mode			
    if game_mode_manager then        
	    if acceptable_locations[game_mode_manager:game_mode_name()] then
        mod.init()
      end
    end
end