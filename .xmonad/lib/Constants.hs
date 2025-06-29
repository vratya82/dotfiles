-- ~/.xmonad/lib/Constants.hs
module Constants where

import XMonad (KeyMask, mod4Mask)

theTerminal :: String
theTerminal = "alacritty"

modKey :: KeyMask
modKey = mod4Mask

myWorkspaces :: [String]
myWorkspaces =
  [ "ἓν", "δύο", "τρεῖς", "τέτταρες", "πέντε",
    "ἕξ", "ἑπτά", "ὀκτώ", "ἐννέα"]

colorNormalBorder, colorFocusedBorder :: String
colorNormalBorder  = "#44475a"
colorFocusedBorder = "#a6adc8"
