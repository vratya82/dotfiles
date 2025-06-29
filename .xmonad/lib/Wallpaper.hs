-- ~/.xmonad/lib/Wallpaper.hs
module Wallpaper (applyWallpaperForWS) where

import XMonad (X, spawn)
import qualified Data.Map as M

-- Importeer onze eigen constantes
import Constants (myWorkspaces)

-- Pad naar de wallpaper directory
wallpaperDir :: FilePath
wallpaperDir = "/home/vratya/.xmonad/wallpapers/"

-- Genereert de map van workspaces naar wallpaper-bestanden
wallpaperMap :: M.Map String FilePath
wallpaperMap = M.fromList $
  zip myWorkspaces [wallpaperDir ++ show n ++ ".png" | n <- [1..(length myWorkspaces)]]

-- Helper functie om 'wal' te draaien
updateWallpaper :: FilePath -> X ()
updateWallpaper path = spawn $ "wal -q -i " ++ quote path
  where quote s = "\"" ++ s ++ "\""

-- Helper functie om Xresources en xmobar te herladen
reloadXResourcesAndXmobar :: X ()
reloadXResourcesAndXmobar = do
  spawn "xrdb ~/.Xresources"
  spawn "pkill -USR1 xmobar"

-- De hoofdfunctie die we exporteren: past de wallpaper toe voor een workspace
applyWallpaperForWS :: String -> X ()
applyWallpaperForWS ws = case M.lookup ws wallpaperMap of
  Just path -> do
    updateWallpaper path
    reloadXResourcesAndXmobar
  Nothing -> return ()
