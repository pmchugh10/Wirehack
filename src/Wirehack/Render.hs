{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE FlexibleInstances #-}

module Wirehack.Render
  ( Renderable(..)
  ) where

import Control.Applicative
import Control.Lens hiding (Empty)
import qualified Data.Text.Lazy as T
import Data.Vector (Vector)
import Graphics.Vty as V
import Wirehack.Cell (Cell(..), Component(..))
import Wirehack.Power (hasPower)
import Wirehack.Space (Bounds, ISpace(..), Space(..), focus)

class Attrs a where
  attrs :: a -> V.Attr

instance Attrs Cell where
  attrs Cell {_component = Empty} = V.defAttr
  attrs cell =
    V.withForeColor V.defAttr $
    if hasPower cell
      then V.green
      else V.red

class Renderable a where
  render :: a -> V.Image

instance Bounds w h => Renderable (ISpace w h Cell) where
  render spc = foldr (V.vertJoin . foldInner) V.emptyImage $ images
    where
      foldInner :: Vector V.Image -> V.Image
      foldInner = foldr V.horizJoin V.emptyImage
      cellAttrs = (focus <>~ highlighting) . fmap attrs $ spc
      highlighting = V.withStyle V.currentAttr V.reverseVideo
      displayedComponents = T.pack . show <$> spc
      ISpace _ (Space images) = liftA2 V.text cellAttrs displayedComponents
