import XMonad
import XMonad.Hooks.ManageDocks (docks, avoidStruts)
import XMonad.Hooks.EwmhDesktops (ewmh, ewmhFullscreen)
import XMonad.Hooks.DynamicLog (dynamicLogWithPP, xmobarPP, PP(..))
import XMonad.Layout.Grid (Grid(..))
import XMonad.Layout.NoBorders (smartBorders)
import XMonad.Layout.ResizableTile (ResizableTall(..))
import XMonad.Layout.SimplestFloat (simplestFloat)
import XMonad.Layout.Spacing (spacingRaw, Border(..))
import XMonad.Layout.Spiral (spiral)
import XMonad.Layout.Tabbed (simpleTabbed)
import XMonad.Layout.ThreeColumns (ThreeCol(..))
import XMonad.Layout.TwoPane (TwoPane(..))
import XMonad.Util.EZConfig (additionalKeys)
import XMonad.Util.Run (spawnPipe)
import XMonad.Util.SpawnOnce (spawnOnce)
import System.Exit (exitWith, ExitCode(ExitSuccess))
import System.IO (hPutStrLn)
import qualified Data.Map as M
import qualified XMonad.StackSet as W

myTerminal :: String
myTerminal = "alacritty"

myModMask :: KeyMask
myModMask = mod4Mask

myWorkspaces :: [String]
myWorkspaces = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX"]

wallpaperCommand :: String
wallpaperCommand = "bash ~/dotfiles/xmonad/rotate-wallpaper-fade.sh"

startupWallpaperCommand :: String
startupWallpaperCommand = "feh --recursive --randomize --bg-fill ~/wallpapers"

toggleFullFloat :: Window -> X ()
toggleFullFloat w = windows $ \s ->
  if M.member w (W.floating s)
     then W.sink w s
     else W.float w (W.RationalRect 0 0 1 1) s

unfloatOrNextLayout :: X ()
unfloatOrNextLayout = do
  ws <- gets windowset
  case W.peek ws of
    Just w | M.member w (W.floating ws) -> windows (W.sink w)
    _                                    -> sendMessage NextLayout

myKeys =
    [ ((myModMask,               xK_Return), spawn myTerminal)
    , ((myModMask .|. shiftMask, xK_c),      kill)
    , ((myModMask .|. mod1Mask,  xK_q),      io (exitWith ExitSuccess))
    , ((myModMask,               xK_r),      spawn "rofi -show drun")
    , ((myModMask .|. shiftMask, xK_r),      spawn "xmonad --recompile && xmonad --restart")
    , ((myModMask .|. shiftMask, xK_t),      withFocused $ windows . W.sink)
    , ((myModMask,               xK_f),      withFocused toggleFullFloat)
    , ((myModMask,               xK_space),  unfloatOrNextLayout)
    , ((myModMask,               xK_w),      spawn wallpaperCommand)

    , ((0,                       xK_Print),  spawn "scrot ~/Pictures/screenshots/screenshot-%Y-%m-%d-%H%M%S.png")

    , ((myModMask, xK_F1),  spawn "firefox")
    , ((myModMask, xK_F2),  spawn "thunderbird")
    , ((myModMask, xK_F3),  spawn "thunar")
    , ((myModMask, xK_F4),  spawn "keepassxc")
    , ((myModMask, xK_F5),  spawn "virt-manager")
    , ((myModMask, xK_F6),  spawn "calibre")
    , ((myModMask, xK_F7),  spawn "anki")
    , ((myModMask, xK_F8),  spawn "obsidian")
    , ((myModMask, xK_F9),  spawn (myTerminal ++ " -e bmon"))
    , ((myModMask, xK_F10), spawn (myTerminal ++ " -e htop"))
    , ((myModMask, xK_F11), spawn "syncthing")
    , ((myModMask, xK_F12), spawn "xscreensaver-command -lock")
    ]

myLayout = smartBorders
         $ spacingRaw False (Border 5 5 5 5) True (Border 5 5 5 5) True
         $ Grid
       ||| Tall 1 (3/100) (1/2)
       ||| Mirror (Tall 1 (3/100) (1/2))
       ||| ThreeColMid 1 (3/100) (1/2)
       ||| spiral (6/7)
       ||| ResizableTall 1 (3/100) (1/2) []
       ||| TwoPane (3/100) (1/2)
       ||| simpleTabbed
       ||| simplestFloat
       ||| Full

main :: IO ()
main = do
  xmproc <- spawnPipe "xmobar ~/.config/xmobar/xmobarrc"
  xmonad
    $ ewmhFullscreen
    $ ewmh
    $ docks
    $ def
       { terminal    = myTerminal
       , modMask     = myModMask
       , workspaces  = myWorkspaces
       , borderWidth = 0
       , layoutHook  = avoidStruts myLayout
       , logHook     = dynamicLogWithPP xmobarPP { ppOutput = hPutStrLn xmproc }
       , startupHook = do
           spawnOnce "picom"
           spawnOnce startupWallpaperCommand
       }
      `additionalKeys` myKeys
