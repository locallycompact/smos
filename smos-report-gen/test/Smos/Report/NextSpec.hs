{-# LANGUAGE TypeApplications #-}

module Smos.Report.NextSpec where

import Smos.Report.Archive.Gen ()
import Smos.Report.Filter.Gen ()
import Smos.Report.Next
import Smos.Report.Next.Gen ()
import Smos.Report.TestUtils
import Test.Hspec
import Test.Hspec.QuickCheck
import Test.Validity
import Test.Validity.Aeson

spec :: Spec
spec = do
  genValidSpec @NextActionReport
  jsonSpecOnValid @NextActionReport
  genValidSpec @NextActionEntry
  jsonSpecOnValid @NextActionEntry
  modifyMaxSuccess (`div` 10) $ describe "produceNextActionReport" $ it "produces valid reports for interesting stores"
    $ forAllValid
    $ \mFilter ->
      forAllValid $ \ha ->
        withInterestingStore $ \dc -> do
          nar <- produceNextActionReport mFilter ha dc
          shouldBeValid nar
