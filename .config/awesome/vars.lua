local os = os

return {
    chosen_theme = "deepfocus",
    modkey = "Mod4",
    altkey = "Mod1",
    terminal = "urxvt",
    editor = os.getenv("EDITOR") or "nano",
    guieditor = "code",
    browser = "chromium"
}
