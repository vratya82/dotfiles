-- ~/.xmonad/xmonad.hs
import XMonad
import XMonad.Hooks.ManageDocks (docks)
import XMonad.Hooks.EwmhDesktops (ewmh, ewmhFullscreen)
import XMonad.Util.Run (spawnPipe)
import XMonad.Util.EZConfig (additionalKeys)

-- Importeer AL onze eigen modules
import Constants
import Keybindings
import Layouts
import Hooks

main :: IO ()
main = do
  xmproc <- spawnPipe "xmobar ~/.xmonad/xmobar/.xmobarrc"
  xmonad $ ewmhFullscreen . ewmh $ docks def
    { terminal           = theTerminal
    , modMask            = modKey
    , workspaces         = myWorkspaces
    , borderWidth        = 4
    , normalBorderColor  = colorNormalBorder
    , focusedBorderColor = colorFocusedBorder
    
    -- De volgende drie regels gebruiken functies uit onze modules
    , layoutHook         = theLayout
    , startupHook        = myStartup
    , logHook            = myLogHook xmproc

    , focusFollowsMouse  = False
    , clickJustFocuses   = False
    }
    `additionalKeys` myKeys
