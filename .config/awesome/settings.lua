local settings = {}

-- Globals
settings.HOME   = os.getenv("HOME")
settings.CONFIG = settings.HOME .. "/.config/awesome/"

settings.theme = "neo" -- Theme to load

-- Key Modifiers
settings.keys = { super = "Mod4", alt = "Mod1", ctrl = "Control", shift = "Shift" }

-- Lock command
settings.lock_cmd = "i3lock -c1f67b1 -u -i " .. settings.CONFIG .. "lock.png"

settings.autoruns = { -- Ensures the programs are running in the background.
    -- "unclutter -root",
    "compton -i 0.95", -- -i 0.8
    "fcitx",
    "flameshot",
    "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1",
    "xautolock -time 5 -locker \"" .. settings.lock_cmd .. "\""
}

return settings
