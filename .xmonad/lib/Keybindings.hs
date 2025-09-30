-- ~/.xmonad/lib/Keybindings.hs
module Keybindings where

import XMonad
import System.Exit (exitWith, ExitCode(ExitSuccess))
import qualified XMonad.StackSet as W

-- Importeer onze eigen constantes
import Constants

myKeys =
    [ ((modKey, xK_Return), spawn theTerminal)
    , ((modKey .|. shiftMask, xK_c), kill)
    , ((modKey .|. mod1Mask, xK_q), io (exitWith ExitSuccess))
    , ((modKey, xK_r), spawn "rofi -show drun")
    , ((modKey .|. shiftMask, xK_r), spawn "xmonad --recompile && xmonad --restart")
    , ((modKey .|. shiftMask, xK_t), withFocused $ windows . W.sink)
    , ((modKey, xK_f), withFocused (\w -> windows (W.float w (W.RationalRect 0 0 1 1))))

    -- Screenshot keybinding (PrintScreen)
    , ((0, xK_Print), spawn "scrot ~/Pictures//screenshots/screenshot-%Y-%m-%d-%H%M%S.png")

    -- Applicatie-sneltoetsen
    , ((modKey, xK_F1), spawn "chromium")
    , ((modKey, xK_F2), spawn "thunderbird")
    , ((modKey, xK_F3), spawn "thunar")
    , ((modKey, xK_F4), spawn "keepassxc")
    , ((modKey, xK_F5), spawn "virt-manager")
    , ((modKey, xK_F6), spawn "calibre")
    , ((modKey, xK_F7), spawn "anki")
    , ((modKey, xK_F8), spawn "obsidian")
    , ((modKey, xK_F9), spawn (theTerminal ++ " -e bmon"))
    , ((modKey, xK_F10), spawn (theTerminal ++ " -e htop"))
    , ((modKey, xK_F11), spawn "syncthing")
    , ((modKey, xK_F12), spawn "xscreensaver-command -lock")
    ]
