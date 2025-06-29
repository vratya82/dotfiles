-- ~/.xmonad/lib/Hooks.hs (Testversie om de pipe te debuggen)
module Hooks (myStartup, myLogHook) where

import XMonad
import System.IO (Handle, hPutStrLn)

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.SetWMName
import XMonad.Util.SpawnOnce (spawnOnce)

-- We importeren Wallpaper.hs tijdelijk NIET

myStartup :: X ()
myStartup = do
  spawnOnce "picom"
  spawnOnce "xscreensaver -nosplash"
  spawnOnce "~/scripts/random_wal.py"
  setWMName "LG3D"

-- EXTREEM VEREENVOUDIGDE LOGHOOK OM ALLEEN DE PIPE TE TESTEN
myLogHook :: Handle -> X ()
myLogHook xmproc = dynamicLogWithPP xmobarPP
      { ppOutput = hPutStrLn xmproc
      -- We sturen alleen de workspace-informatie, verder niets.
      , ppOrder  = \(ws:_) -> [ws]
      , ppSep    = ""
      , ppTitle  = \_ -> ""
      , ppLayout = \_ -> ""
      }
