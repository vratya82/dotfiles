-- ~/.xmonad/lib/Hooks.hs
module Hooks (myStartup, myLogHook) where

import XMonad
import System.IO (Handle, hPutStrLn)
import qualified XMonad.StackSet as W -- BELANGRIJKE IMPORT

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.SetWMName
import XMonad.Util.SpawnOnce (spawnOnce)

-- Importeer onze eigen wallpaper module
import Wallpaper (applyWallpaperForWS)

myStartup :: X ()
myStartup = do
  spawnOnce "picom"
  spawnOnce "xscreensaver -nosplash"
  spawnOnce "~/scripts/random_wal.py"
  setWMName "LG3D"

-- DIT IS DE CORRECTE IMPLEMENTATIE, GEBASEERD OP JE ORIGINELE CODE
myLogHook :: Handle -> X ()
myLogHook xmproc = do
    -- Actie 1: Haal de WindowSet op en voer de wallpaper functie uit met de huidige tag
    withWindowSet $ \ws ->
        applyWallpaperForWS (W.currentTag ws)

    -- Actie 2: Stuur de log-informatie naar xmobar
    dynamicLogWithPP xmobarPP
      { ppOutput = hPutStrLn xmproc
      , ppTitle = xmobarColor "#a6e3a1" "" . shorten 60
      , ppCurrent = xmobarColor "#89b4fa" "" . wrap "[" "]"
      , ppVisible = wrap "<" ">"
      , ppLayout = xmobarColor "#f38ba8" ""
      , ppSep = " | "
      , ppOrder = \[ws, l, t] -> [ws, l, t]
      }
