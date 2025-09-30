-- ~/.xmonad/lib/Layouts.hs
module Layouts where

import XMonad -- De hoofdmodule exporteert Tall, Mirror, en Full

import XMonad.Layout.Spacing
import XMonad.Layout.Gaps
import XMonad.Layout.NoBorders
import XMonad.Layout.Grid
import XMonad.Layout.PerWorkspace (onWorkspace)
import XMonad.Hooks.ManageDocks (avoidStruts)
import XMonad.Layout.LayoutCombinators ((|||)) -- Enige specifieke import die we nodig hebben

theLayout = avoidStruts $
  gaps [(U,8), (D,8), (L,8), (R,8)] $
  spacing 8 $
  onWorkspace "θ" (noBorders Full) $
  Grid ||| tiled ||| Mirror tiled ||| noBorders Full 
  where
    tiled = Tall 1 (3/100) (1/2)
