 [ ((modKey, xK_Return), spawn theTerminal)                          -- MOD+Enter
    , ((modKey .|. shiftMask, xK_c), kill)                              -- MOD+Shift+C
    , ((modKey .|. mod1Mask, xK_q), io (exitWith ExitSuccess))         -- MOD+Alt+Q
    , ((modKey, xK_r), spawn "rofi -show run")                         -- MOD+r: launcher
    , ((modKey .|. shiftMask, xK_r), spawn "xmonad --recompile && xmonad --restart") -- MOD+Shift+R
    , ((modKey .|. shiftMask, xK_t), withFocused $ windows . W.sink)   -- MOD+Shift+T to re-tile
    , ((modKey, xK_F1), spawn "firefox")
    , ((modKey, xK_F2), spawn "thunar")
    , ((modKey, xK_F3), spawn theTerminal)
    , ((modKey, xK_F4), spawn (theTerminal ++ " -e nvim"))
    , ((modKey, xK_F5), spawn "rofi -show drun")
    , ((modKey, xK_F6), spawn (theTerminal ++ " -e ranger"))
    , ((modKey, xK_F7), spawn "mpv")
    , ((modKey, xK_F8), spawn "pavucontrol")
    , ((modKey, xK_F9), spawn (theTerminal ++ " -e htop"))
    , ((modKey, xK_F10), spawn "telegram-desktop")
    , ((modKey, xK_F11), spawn "betterlockscreen -l")
    , ((modKey, xK_F12), spawn "picom-toggle")  -- optional script
    ]
