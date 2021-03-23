{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}

module Smos.Notify where

import Conduit
import Control.Monad
import qualified Data.Conduit.Combinators as C
import qualified Data.Map as M
import Data.Text (Text)
import qualified Data.Text as T
import Data.Time
import Path
import Path.IO
import Smos.Data
import Smos.Notify.OptParse
import Smos.Report.Archive
import Smos.Report.Config
import Smos.Report.ShouldPrint
import Smos.Report.Streaming
import System.Exit
import System.IO
import System.Process
import Text.Time.Pretty

smosNotify :: IO ()
smosNotify = do
  Settings {..} <- getSettings
  notifySendExecutable <- findNotifySend
  mPlayExecutable <- findPlay
  now <- getZonedTime
  wd <- resolveDirWorkflowDir setDirectorySettings
  ns <-
    runConduit $
      streamSmosFilesFromWorkflowRel HideArchive setDirectorySettings
        .| parseSmosFilesRel wd
        .| printShouldPrint (PrintWarning stderr)
        .| smosFileEntries
        .| C.concatMap (uncurry (parseNotification now))
        .| sinkList
  unless (null ns) $ do
    mapM_ (displayNotification notifySendExecutable) ns
    mapM_ playDing mPlayExecutable

data Notification = Notification
  { notificationSummary :: Text,
    notificationBody :: Text
  }
  deriving (Show, Eq)

parseNotification :: ZonedTime -> Path Rel File -> Entry -> Maybe Notification
parseNotification now _ e = do
  guard (not (isDone (entryState e)))
  beginTS <- M.lookup "BEGIN" (entryTimestamps e)
  let nowUTC = zonedTimeToUTC now
  let beginUTC = localTimeToUTC (zonedTimeZone now) $ timestampLocalTime beginTS
  let d = diffUTCTime beginUTC nowUTC
  let minutesAhead = 120
      timestampIsSoon = d >= 0 && d <= minutesAhead * 60
  guard timestampIsSoon
  pure $
    Notification
      { notificationSummary = T.pack $ "Event " <> prettyTimeAuto nowUTC beginUTC,
        notificationBody = headerText (entryHeader e)
      }

isDone :: Maybe TodoState -> Bool
isDone (Just "DONE") = True
isDone (Just "CANCELLED") = True
isDone (Just "FAILED") = True
isDone _ = False

findNotifySend :: IO (Path Abs File)
findNotifySend = do
  rp <- parseRelFile "notify-send"
  me <- findExecutable rp
  case me of
    Nothing -> die "could not find a notify-send executable."
    Just e -> pure e

findPlay :: IO (Maybe (Path Abs File))
findPlay = do
  rp <- parseRelFile "play"
  findExecutable rp

displayNotification :: Path Abs File -> Notification -> IO ()
displayNotification e Notification {..} = do
  callProcess
    (fromAbsFile e)
    [ "--urgency=critical",
      "--app-name=smos",
      "--icon=/home/syd/src/cs-syd.eu/site/logo/positive/logo.png",
      T.unpack notificationSummary,
      T.unpack notificationBody
    ]

playDing :: Path Abs File -> IO ()
playDing e = callProcess (fromAbsFile e) ["/home/syd/downloads/174027__robni7__news-ting.wav"]
