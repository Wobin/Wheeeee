local mod = get_mod("Wheeeee")

mod.version = "2.0"

local Unit = rawget(_G, "Unit")
local unit_alive = Unit and Unit.alive
local math_random = math.random

local AUDIO_DIR = "mods/Wheeeee/audio/"
local EXTENSIONS = { "mp3", "ogg", "oga", "opus", "wav", "flac", "m4a", "aac" }
local FOLLOW_THROTTLE = 0.1

local sa = nil
local tracks = nil
local active = setmetatable({}, { __mode = "k" })

local function build_playlist()
	local list = {}

	if not sa then
		return list
	end

	for _, ext in ipairs(EXTENSIONS) do
		local ok, result = pcall(sa.glob, AUDIO_DIR .. "*." .. ext)

		if ok and result then
			for _, path in ipairs(result:list()) do
				list[#list + 1] = path
			end
		end
	end

	return list
end

local function get_tracks()
	if not tracks or #tracks == 0 then
		tracks = build_playlist()
	end

	return tracks
end

local function play_scream(unit)
	if not sa then
		return
	end

	local list = get_tracks()

	if not list or #list == 0 then
		return
	end

	local path = list[math_random(1, #list)]
	local set_position = sa.set_position

	if unit and unit_alive(unit) then
		local since_update = 0

		local follow = set_position and function(pid, dt)
			since_update = since_update + dt

			if since_update < FOLLOW_THROTTLE then
				return
			end

			since_update = 0

			if unit_alive(unit) then
				pcall(set_position, pid, unit)
			end
		end or nil

		local ok, id = pcall(sa.play_file, path, {
			audio_type = "sfx",
			volume = 100,
			loop = false,
			on_update = follow,
		}, unit)

		if ok and type(id) == "number" then
			active[unit] = id
		end
	else
		pcall(sa.play_file, path, {
			audio_type = "sfx",
			volume = 100,
			loop = false,
		})
	end
end

mod.on_all_mods_loaded = function()
	sa = get_mod("SimpleAudio")

	if not sa then
		mod:error("Wheeeee requires the SimpleAudio mod to be installed and enabled.")

		return
	end

	mod:info(mod.version)

	tracks = build_playlist()

	mod:hook_safe("PlayerCharacterStateCatapulted", "on_enter", function(self, unit)
		play_scream(unit)
	end)

	mod:hook_safe("PlayerCharacterStateCatapulted", "on_exit", function(self, unit)
		local id = active[unit]

		if id then
			active[unit] = nil

			if sa.stop_file then
				pcall(sa.stop_file, id)
			end
		end
	end)
end
