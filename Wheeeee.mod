return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Wheeeee` encountered an error loading the Darktide Mod Framework.")

		new_mod("Wheeeee", {
			mod_script       = "Wheeeee/scripts/mods/Wheeeee/Wheeeee",
			mod_data         = "Wheeeee/scripts/mods/Wheeeee/Wheeeee_data",
			mod_localization = "Wheeeee/scripts/mods/Wheeeee/Wheeeee_localization",
		})
	end,
	packages = {},
}
