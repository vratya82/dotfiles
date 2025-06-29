import qualified XMonad.StackSet as W
import XMonad
import System.Exit (exitWith, ExitCode(ExitSuccess))
import System.IO (hPutStrLn)

-- Hooks
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.SetWMName

-- Utils
import XMonad.Util.Run (spawnPipe)
import XMonad.Util.SpawnOnce
import XMonad.Util.EZConfig (additionalKeys)

-- Layouts
import XMonad.Layout.Spacing
import XMonad.Layout.Gaps
import XMonad.Layout.NoBorders
import XMonad.Layout.Grid
import XMonad.Layout.PerWorkspace (onWorkspace)

-- Terminal & Modifier
theTerminal :: String
theTerminal = "alacritty"

modKey :: KeyMask
modKey = mod4Mask -- Super/Windows key

-- Workspaces with Greek numeric names
myWorkspaces :: [String]
myWorkspaces =
  [ "α"  -- 1
  , "β"  -- 2
  , "γ"  -- 3
  , "δ"  -- 4
  , "ε"  -- 5
  , "ζ"  -- 6
  , "η"  -- 7
  , "θ"  -- 8
  , "ι"  -- 9
  ]

-- Layouts with per-workspace logic
theLayout = avoidStruts $
  gaps [(U,8), (D,8), (L,8), (R,8)] $
  spacing 8 $
  onWorkspace "θ" (noBorders Full) $
  Grid ||| tiled ||| Mirror tiled ||| noBorders Full
  where
    tiled = Tall 1 (3/100) (1/2)

-- Startup applications and session config
myStartup :: X ()
myStartup = do
  spawnOnce "picom &"
  spawnOnce "nitrogen --restore &"
  setWMName "LG3D"

-- Main config
main :: IO ()
main = do
  xmproc <- spawnPipe "xmobar ~/.xmobarrc"
  xmonad $ docks def
    { modMask = modKey
    , terminal = theTerminal
    , layoutHook = theLayout
    , borderWidth = 4
    , startupHook = myStartup
    , workspaces = myWorkspaces
    , focusFollowsMouse = False
    , clickJustFocuses = False
    , logHook = dynamicLogWithPP xmobarPP
        { ppOutput = hPutStrLn xmproc
        , ppTitle = xmobarColor "#a6e3a1" "" . shorten 60
        , ppCurrent = xmobarColor "#89b4fa" "" . wrap "[" "]"
        , ppVisible = wrap "<" ">"
        , ppLayout = xmobarColor "#f38ba8" ""
        , ppSep = " | "
        }
    }
    `additionalKeys`
    [ ((modKey, xK_Return), spawn theTerminal)                          -- MOD+Enter
    , ((modKey .|. shiftMask, xK_c), kill)                              -- MOD+Shift+C
    , ((modKey .|. mod1Mask, xK_q), io (exitWith ExitSuccess))         -- MOD+Alt+Q
    , ((modKey, xK_r), spawn "rofi -show run")                         -- MOD+r: launcher
    , ((modKey .|. shiftMask, xK_r), spawn "xmonad --recompile && xmonad --restart") -- MOD+Shift+R
    , ((modKey .|. shiftMask, xK_t), withFocused $ windows . W.sink)   -- MOD+Shift+T to re-tile
    ]

