{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}

module Smos.Web.Server.OptParse.Types where

import Autodocodec
import Control.Monad.Logger
import Data.Text (Text)
import GHC.Generics (Generic)
import Path
import Servant.Client
import Text.Read

data Arguments
  = Arguments Command Flags
  deriving (Show, Eq)

data Instructions
  = Instructions Dispatch Settings

newtype Command
  = CommandServe ServeFlags
  deriving (Show, Eq)

data ServeFlags = ServeFlags
  { serveFlagLogLevel :: !(Maybe LogLevel),
    serveFlagPort :: !(Maybe Int),
    serveFlagDocsUrl :: !(Maybe String),
    serveFlagAPIUrl :: !(Maybe String),
    serveFlagWebUrl :: !(Maybe String),
    serveFlagDataDir :: !(Maybe FilePath),
    serveFlagGoogleAnalyticsTracking :: !(Maybe String),
    serveFlagGoogleSearchConsoleVerification :: !(Maybe String)
  }
  deriving (Show, Eq)

data Flags = Flags
  { flagConfigFile :: !(Maybe FilePath)
  }
  deriving (Show, Eq, Generic)

data Environment = Environment
  { envConfigFile :: !(Maybe FilePath),
    envLogLevel :: !(Maybe LogLevel),
    envPort :: !(Maybe Int),
    envDocsUrl :: !(Maybe String),
    envAPIUrl :: !(Maybe String),
    envWebUrl :: !(Maybe String),
    envDataDir :: !(Maybe FilePath),
    envGoogleAnalyticsTracking :: !(Maybe String),
    envGoogleSearchConsoleVerification :: !(Maybe String)
  }
  deriving (Show, Eq, Generic)

data Configuration = Configuration
  { confLogLevel :: !(Maybe LogLevel),
    confPort :: !(Maybe Int),
    confDocsUrl :: !(Maybe String),
    confAPIUrl :: !(Maybe String),
    confWebUrl :: !(Maybe String),
    confDataDir :: !(Maybe FilePath),
    confGoogleAnalyticsTracking :: !(Maybe String),
    confGoogleSearchConsoleVerification :: !(Maybe String)
  }
  deriving (Show, Eq, Generic)

instance HasCodec Configuration where
  codec =
    object "Configuration" $
      Configuration
        <$> optionalFieldWith "log-level" (bimapCodec parseLogLevel renderLogLevel codec) "The minimal severity for log messages" .= confLogLevel
        <*> optionalField "port" "The port on which to serve web requests" .= confPort
        <*> optionalField "docs-url" "The url for the documentation site to refer to" .= confDocsUrl
        <*> optionalField "api-url" "The url for the api to use" .= confAPIUrl
        <*> optionalField "web-url" "The url that this web server is served from" .= confWebUrl
        <*> optionalField "data-dir" "The directory to store workflows during editing" .= confDataDir
        <*> optionalField "google-analytics-tracking" "The google analytics tracking code" .= confGoogleAnalyticsTracking
        <*> optionalField "google-search-console-verification" "The google search console verification code" .= confGoogleSearchConsoleVerification

newtype Dispatch
  = DispatchServe ServeSettings
  deriving (Show, Eq, Generic)

data ServeSettings = ServeSettings
  { serveSetLogLevel :: !LogLevel,
    serveSetPort :: !Int,
    serveSetDocsUrl :: !(Maybe BaseUrl),
    serveSetAPIUrl :: !BaseUrl,
    serveSetWebUrl :: !BaseUrl,
    serveSetDataDir :: !(Path Abs Dir),
    serveSetGoogleAnalyticsTracking :: !(Maybe Text),
    serveSetGoogleSearchConsoleVerification :: !(Maybe Text)
  }
  deriving (Show, Eq, Generic)

data Settings
  = Settings
  deriving (Show, Eq, Generic)

parseLogLevel :: String -> Either String LogLevel
parseLogLevel s = case readMaybe $ "Level" <> s of
  Nothing -> Left $ unwords ["Unknown log level: " <> show s]
  Just ll -> Right ll

renderLogLevel :: LogLevel -> String
renderLogLevel = drop 5 . show
