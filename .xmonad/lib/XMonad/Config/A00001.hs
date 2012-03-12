{-# LANGUAGE
     DeriveDataTypeable,
     FlexibleContexts,
     FlexibleInstances,
     MultiParamTypeClasses,
     NoMonomorphismRestriction,
     PatternGuards,
     ScopedTypeVariables,
     TypeSynonymInstances,
     UndecidableInstances
     #-}
{-# OPTIONS_GHC -W -fno-warn-missing-signatures -fwarn-unused-imports #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  XMonad.Config.A00001
-- Copyright   :  (c) Thomas Frössman 2010-2011
-- License     :  BSD3-style (see LICENSE)
--
-- Maintainer  :  thomasf@jossystem.se
-- Stability   :  unstable
-- Portability :  unportable
--
-- This module specifies my xmonad defaults.
--
-- Requires a patched xmonad and xmonad-contrib
--
--
-- References and inspirations:
-- http://xmonad.org/xmonad-docs/xmonad-contrib/src/
-- http://xmonad.org/xmonad-docs/xmonad-contrib/src/XMonad-Config.html
-- http://xmonad.org/xmonad-docs/xmonad-contrib/src/XMonad-Config-Arossato.html
-- http://www.haskell.org/haskellwiki/Xmonad/Config_archive/Mntnoe%27s_xmonad.hs
-- http://snipt.net/doitian
-- http://phraktured.net/terminal-colors/
-- http://hpaste.org/fastcgi/hpaste.fcgi/view?id=25565
--
-----------------------------------------------------------------------------
module XMonad.Config.A00001
    ( -- * Usage
      -- $usage
      autoConfig
    ) where

import           Control.Monad
import           Control.Monad.Reader
import           Data.List
import qualified Data.Map                        as M
import           Data.Monoid
import           Data.Ratio                      ((%))
import           Foreign.C.Types                 (CInt)
import           Graphics.X11.Xinerama
import           System.IO
import qualified System.IO.UTF8
import           System.Posix.Unistd             (getSystemID, nodeName)
import           XMonad                          hiding ( (|||) )
import           XMonad.Actions.Commands
import           XMonad.Actions.CycleWS
import           XMonad.Actions.GroupNavigation
import           XMonad.Actions.Navigation2D
import           XMonad.Actions.PerWorkspaceKeys
import           XMonad.Actions.TopicSpace
import           XMonad.Actions.UpdatePointer
import           XMonad.Actions.WindowBringer    (gotoMenuArgs, bringMenuArgs)
import           XMonad.Config.Gnome
import           XMonad.Hooks.DynamicLog
import           XMonad.Hooks.EwmhDesktops       (ewmh, fullscreenEventHook)
import           XMonad.Hooks.ManageDocks        (avoidStruts, manageDocks, docksEventHook)
import           XMonad.Hooks.ManageHelpers
import           XMonad.Hooks.ServerMode
import           XMonad.Hooks.UrgencyHook
import           XMonad.Layout.Accordion
import           XMonad.Layout.Decoration
import           XMonad.Layout.DwmStyle
import           XMonad.Layout.IM2
import           XMonad.Layout.Magnifier
import           XMonad.Layout.SimpleFloat
import           XMonad.Layout.Spiral
import           XMonad.Layout.Tabbed
import           XMonad.Prompt
import           XMonad.Prompt.Workspace
import           XMonad.Prompt.XMonad
import qualified XMonad.StackSet                 as W
import           XMonad.Util.EZConfig
import           XMonad.Util.NamedActions
import           XMonad.Util.NamedScratchpad
import           XMonad.Util.NamedWindows        (getName)
import           XMonad.Util.Run
import           XMonad.Util.Scratchpad          (scratchpadFilterOutWorkspace)
import           XMonad.Util.Themes
import           XMonad.Util.WindowProperties
import           XMonad.Util.WorkspaceCompare
import           XMonad.Layout.DragPane
import           XMonad.Layout.Grid
import           XMonad.Layout.ThreeColumns
import           XMonad.Layout.LayoutHints
import           XMonad.Layout.WindowArranger
import           XMonad.Layout.LayoutCombinators
import           XMonad.Layout.BorderResize
import           XMonad.Layout.NoBorders         (noBorders)
import           XMonad.Layout.Gaps
import           XMonad.Layout.Reflect
import           XMonad.Layout.PerWorkspace      (onWorkspace)
import           XMonad.Layout.Named
import           XMonad.Layout.LimitWindows

--myTerminal = "urxvtcd"
myTerminal = "urxvt"
myShell = "bash"

myFocusFollowsMouse = False
myBorderWidth   = 1
myModMask = mod4Mask


-- Border colors for unfocused and focused windows, respectively.
--
myNormalBorderColor  = "#000"
myFocusedBorderColor = "#202020"

-- The default number of workspaces (virtual screens) and their names.
-- By default we use numeric strings, but any string may be used as a
-- workspace name. The number of workspaces is determined by the length
-- of this list.
--
-- A tagging example:
--
-- > workspaces = ["web", "irc", "code" ] ++ map show [4..9]

--myWorkspaces = ["1.mix","2.im","3.web","4.web2","5.code","6.code2","7.code3","8.write","9.gimp","10.mix2"]

------------------------------------------------------------------------
-- Layouts:

-- You can specify and transform your layouts by modifying these values.
-- If you change layout bindings be sure to use 'mod-shift-space' after
-- restarting (with 'mod-q') to reset your layout state to the new
-- defaults, as xmonad preserves your old layout settings by default.
--
-- * NOTE: XMonad.Hooks.EwmhDesktops users must remove the obsolete
-- ewmhDesktopsLayout modifier from layoutHook. It no longer exists.
-- Instead use the 'ewmh' function from that module to modify your
-- defaultConfig as a whole. (See also logHook, handleEventHook, and
-- startupHook ewmh notes.)
--
-- The available layouts.  Note that each layout is separated by |||,
-- which denotes layout choice.
--

myLayoutHook =        
  onWorkspace "chat" (chatL ||| fullTabL) $
  onWorkspace "dotfiles" xmonadL $
  onWorkspace "nodes" fullTabL $
  onWorkspace "reading" fullTabL $
  onWorkspace "music" (fullTabL ||| tiledL ) $
  --tiledMirrorL ||| tiledL ||| spiralL ||| magnifiedL ||| four ||| accordionL  ||| decorated ||| fullTabL ||| fullL
  tiledMirrorL ||| tiledL ||| spiralL ||| fullTabL ||| fullL ||| threeCol
  where
    -- normal layouts
    tiledL=named "tile" ( avoidStruts $  deco kavonBluesTheme $ layoutHintsToCenter tiled )           
    tiledMirrorL=named "tile mirror" ( avoidStruts $ deco kavonBluesTheme $ layoutHintsToCenter (Mirror tiled))
    fullTabL=named "fulltab"  ( avoidStruts $ noBorders $ tabbed shrinkText (theme kavonForestTheme))
    fullL=named "full" ( noBorders $ Full)
    spiralL=named "spiral" ( noBorders $ deco kavonFireTheme $ avoidStruts $ spiral (6/7))
    threeCol=named "3Col" ( noBorders $ avoidStruts $ ThreeColMid 1 (3/100) (1/2))

    --workspace specific layouts
    chatL = named ":)" ( avoidStruts $ withIMs ratio rosters chatLayout)
      where
        chatLayout      = Grid
        ratio           = 1%7
        rosters         = [skypeRoster, pidginRoster]
        pidginRoster    = And (ClassName "Pidgin") (Role "buddy_list")
        skypeRoster     = (ClassName "Skype") `And` (Not (Title "Options")) `And` (Not (Role "Chats")) `And` (Not (Role "CallWindowForm"))

    xmonadL = named ";>" (  avoidStruts $ noBorders $ layoutHintsToCenter (Mirror $ Tall 1 (3/100) (4/5)) )

    deco t   = decoration shrinkText (theme t) Dwm
    tiled   = noBorders $ Tall 1 (3/100) (4/5)

-----------------------------------------------------------------------
-- Window rules:

-- Execute arbitrary actions and WindowSet manipulations when managing
-- a new window. You can use this to, for example, always float a
-- particular program, or have a client always appear on a particular
-- workspace.
--
-- To find the property name associated with a program, use
-- > xprop | grep WM_CLASS
-- and click on the client you're interested in.
--
-- To match on the WM_NAME, you can use 'title' in the same way that
-- 'className' and 'resource' are used below.

myManageHook :: ManageHook

myManageHook =  composeOne
  [ resource            =? "Do"                -?> doIgnore
  , resource            =? "desktop_window"    -?> doIgnore
  , resource            =? "kdesktop"          -?> doIgnore
  , className           =? "Unity-2d-panel"    -?> doIgnore
  , className           =? "Unity-2d-launcher" -?> doFloat
  , className           =? "Xfce4-notifyd"     -?> doIgnore
  , className           =? "Xfdesktop"         -?> doIgnore
  , className           =? "Orage"             -?> doFloat
  , className    =? "Xfce4-settings-manager"   -?> doCenterFloat
  , className           =? "Xfce4-appfinder"   -?> doCenterFloat
  , className           =? "Pinentry"          -?> doCenterFloat
  , transience
  , isFullscreen                               -?> doFullFloat
  , resource            =? "empathy"           -?> doF (W.shift "chat")
  , resource            =? "xchat"             -?> doF (W.shift "chat")
  , className           =? "Pidgin"            -?> doF (W.shift "chat")

  , className           =? "Nicotine.py"       -?> doF (W.shift "fileshare")
  , className           =? "Transmission-gtk"  -?> doF (W.shift "fileshare")

  , resource            =? "xmessage"          -?> doCenterFloat
  , className           =? "feh"               -?> doFloat
  , className           =? "MPlayer"           -?> doFloat
  ] <+> namedScratchpadManageHook (myScratchPads)
  where
    role = stringProperty "WM_WINDOW_ROLE"


------------------------------------------------------------------------
-- Event handling

-- Defines a <custom handler function for X Events. The function should
-- return (All True) if the default handler is to be run afterwards. To
-- combine event hooks use mappend or mconcat from Data.Monoid.
--
-- * NOTE: EwmhDesktops users should use the 'ewmh' function from
-- XMonad.Hooks.EwmhDesktops to modify their defaultConfig as a whole.
-- It will add EWMH event handling to your custom event hooks by
-- combining them with ewmhDesktopsEventHook.
--
myEventHook = serverModeEventHook <+> fullscreenEventHook

------------------------------------------------------------------------
-- Status bars and logging

-- Perform an arbitrary action on each internal state change or X event.
-- See the 'XMonad.Hooks.DynamicLog' extension for examples.
--
--
-- * NOTE: EwmhDesktops users should use the 'ewmh' function from
-- XMonad.Hooks.EwmhDesktops to modify their defaultConfig as a whole.
-- It will add EWMH logHook actions to your custom log hook by
-- combining it with ewmhDesktopsLogHook.
--

myXmobarLogHook h = dynamicLogWithPP defaultPP
  { ppCurrent = xmobarColor "orange" "" . wrap "[" "]"
  , ppTitle   = xmobarColor "magenta"  "" . shorten 40
  , ppVisible = wrap "(" ")"
  , ppOutput  = hPutStrLn h
  , ppSort = fmap (.scratchpadFilterOutWorkspace) $ ppSort defaultPP
  }

myDzenLogHook h = dynamicLogWithPP $ myPP h


myPP h = defaultPP
  { ppCurrent           =   dzenColor "#eee" "#111" . padWs
  , ppVisible           =   dzenColor "#8F8F67" "#111" . padWs
  , ppHidden            =   const ""
  , ppUrgent            =   dzenColor "red" "#111" . padWs
  , ppWsSep             =   " "
  , ppSep               =   " | "
  , ppTitle             =   (" " ++) . dzenColor "#AFAF87" "#111" . dzenEscape
  , ppLayout = dzenColor "#777777" "" .
               (\x -> case x of
                   "Full" -> "^fg(#777777)^i(/home/petar/.dzen/full.xbm)"
                   "ResizableTall" -> "^fg(#777777)^i(/home/petar/.dzen/tall.xbm)"
                   "Tall" -> "^fg(#777777)^i(/home/petar/.dzen/tall.xbm)"
                   "Mirror ResizableTall" -> "^fg(#777777)^i(/home/petar/.dzen/mtall.xbm)"
                   "Hinted Mirror ResizableTall" -> "^fg(#777777)^i(/home/petar/.dzen/layout-mirror-bottom.xbm)"
                   "Spiral" -> "[sP]"
                   "Grid" -> "^fg(#777777)^i(/home/petar/.dzen/grid.xbm)"
                   "IM Grid" -> "[iM]"
                   "SimplestFloat" -> "[sfL]"
                   _ -> x
               )
  , ppOutput            =   hPutStrLn h
  }
  where
    padWs ws = if ws == "NSP" then "" else pad ws


-- move mouse pointer to bottom right of the current window
movePointer=(updatePointer (Relative 0.99 0.99))


------------------------------------------------------------------------
-- Startup hook

-- Perform an arbitrary action each time xmonad starts or is restarted
-- with mod-q.  Used by, e.g., XMonad.Layout.PerWorkspace to initialize
-- per-workspace layout choices.
--
-- By default, do nothing.
--
-- * NOTE: EwmhDesktops users should use the 'ewmh' function from
-- XMonad.Hooks.EwmhDesktops to modify their defaultConfig as a whole.

-- It will add initialization of EstaWMH support to your custom startup
-- hook by combining it with ewmhDesktopsStartup.

myStartupHook = do
  return ()

------------------------------------------------------------------------
-- Keyboard configuration:

altMask=mod1Mask

killWindows= 
  [ ("chat", 
     do
       spawn "pkill -9 xchat"
       spawn "pkill -9 pidgin"
    )
  , ("",kill) 
  ]

myKeys conf@(XConfig {XMonad.modMask = modm}) =
  [ subtitle "Application launching"    
  , ((modm.|. shiftMask,                              xK_Return), addName "launch terminal"                                       $ spawnShell)

  , subtitle "misc"
  , ((modm.|. shiftMask,                              xK_c),      addName "kill active window"                                    $ bindOn killWindows)

  , subtitle "Cyclic window focus"
  , ((modm,                                           xK_j),      addName "Next window on workspace"                              $ (windows W.focusDown) >> movePointer)
  , ((modm,                                           xK_k),      addName "Previous window on workspace"                          $ (windows W.focusUp) >> movePointer)
  , ((modm.|. altMask,                                xK_j),      addName "Next of same window className"                         $ (nextMatchWithThis Forward className) >> movePointer)
  , ((modm.|. altMask,                                xK_k),      addName "Previous of same window className"                     $ (nextMatchWithThis Backward className) >> movePointer)

  , subtitle "Cyclic window swap"
  , ((modm.|. shiftMask,                              xK_j),      addName "Swap the focused window with the next window"          $ (windows W.swapDown) >> movePointer)
  , ((modm.|. shiftMask,                              xK_k),      addName "Swap the focused window with the previous window"      $ (windows W.swapUp) >> movePointer)

  , subtitle "Directional window focus"
  , ((modm,                                           xK_Left),   addName ""                                                      $ (windowGo L False) >> movePointer)
  , ((modm,                                           xK_Right),  addName ""                                                      $ (windowGo R False) >> movePointer)
  , ((modm,                                           xK_Up),     addName ""                                                      $ (windowGo U False) >> movePointer)
  , ((modm,                                           xK_Down),   addName ""                                                      $ (windowGo D False) >> movePointer)

  , subtitle "Directional window swap"
  , ((modm.|. controlMask,                            xK_Left),   addName ""                                                      $ (windowSwap L False) >> movePointer)
  , ((modm.|. controlMask,                            xK_Right),  addName ""                                                      $ (windowSwap R False) >> movePointer)
  , ((modm.|. controlMask,                            xK_Up),     addName ""                                                      $ (windowSwap U False) >> movePointer)
  , ((modm.|. controlMask,                            xK_Down),   addName ""                                                      $ (windowSwap D False) >> movePointer)

  , subtitle "Directional window send"
  , ((modm.|. controlMask.|. altMask,                 xK_Left),   addName ""                                                      $ (windowToScreen L False) >> movePointer)
  , ((modm.|. controlMask.|. altMask,                 xK_Right),  addName ""                                                      $ (windowToScreen R False) >> movePointer)
  , ((modm.|. controlMask.|. altMask,                 xK_Up),     addName ""                                                      $ (windowToScreen U False) >> movePointer)
  , ((modm.|. controlMask.|. altMask,                 xK_Down),   addName ""                                                      $ (windowToScreen D False) >> movePointer)

  , subtitle "Go to workspace"
  , ((modm,                                           xK_n),      addName "Goto workspace prompt"                                 $ promptedGoto)
  , ((modm,                                           xK_o),      addName "Goto open window in workspace by name"                 $ gotoMenuArgs ["-l 23"] )

  , ((modm.|. controlMask.|. shiftMask,               xK_Right),  addName "Next non empty workspace"                              $ (nextNonEmptyWorkspace) >> movePointer)
  , ((modm.|. controlMask.|. shiftMask,               xK_Left),   addName "Previous non empty workspace"                          $ (prevNonEmptyWorkspace) >> movePointer)
  , ((modm.|. controlMask.|. shiftMask,               xK_Up),     addName "Go to next empty workspace"                            $ (nextEmptyWorkspace) >> movePointer)
  , ((modm.|. controlMask.|. shiftMask,               xK_Down),   addName "Go to previous empty workspace"                        $ (prevEmptyWorkspace) >> movePointer)

  , subtitle "Move window to workspace"
  , ((modm.|. controlMask.|. shiftMask,               xK_n),      addName "Move the currently focused window to workspace prompt" $ promptedShift)
  , ((modm.|. controlMask.|. shiftMask,               xK_o),      addName "Bring window by search into current workspace"         $ bringMenuArgs ["-l 23"])

  , subtitle "Layout control"
  , ((modm,                                           xK_space),  addName "Switch to the next window layout"                      $ sendMessage NextLayout)
  , ((modm,                                           xK_m),      addName "Move focus to master window"                           $ (windows W.focusMaster) >> movePointer)
  , ((modm,                                           xK_Return), addName "Swap the focused window and the master window"         $ (windows W.swapMaster) >> movePointer)
  , ((modm,                                           xK_h),      addName "Shrink the master area"                                $ (sendMessage Shrink) >> movePointer)
  , ((modm,                                           xK_l),      addName "Expand the master area"                                $ (sendMessage Expand) >> movePointer)
  , ((modm,                                           xK_comma),  addName "Increment the number of windows in the master area"    $ (sendMessage (IncMasterN 1)) >> movePointer)
  , ((modm,                                           xK_period), addName "Deincrement the number of windows in the master area"  $ (sendMessage (IncMasterN (-1))) >> movePointer)

  , subtitle "Other window operations"
  , ((modm,                                           xK_t),      addName "Push the window into tiling mode"                      $ (withFocused $ windows . W.sink) >> movePointer)

  , subtitle "other"

  , ((modm.|. altMask,                              xK_t),      addName "terminal scratch pad"                                  $ terminalPad )
  , ((modm.|. altMask,                              xK_2),      addName "do current topic action"                               $ currentTopicAction myTopicConfig)
  , ((modm.|. altMask,                              xK_9),      addName "xmonad prompt"                                         $ xmonadPrompt myXPConfig)
  --, ((modm.|. altMask,                              xK_8),      addName "xmonad dmenu prompt"                                   $ defaultCommands >>= runCommand )
  , ((modm.|. altMask,                              xK_6),      addName "wincmds"                                         $ workspaceCommands >>= runCommand )
  ]

emptyKeys = \c -> mkKeymap c $
  [
    --("M-S-<Return>", spawn $ terminal c)
  ]

------------------------------------------------------------------------
-- Mouse bindings: default actions bound to mouse events
--
myMouseBindings (XConfig {XMonad.modMask = modm}) = M.fromList $
  -- mod-button1, Set the window to floating mode and move by dragging
  [ ((modm, button1), (\w -> focus w >> mouseMoveWindow w
                                     >> windows W.shiftMaster))
  -- mod-button2, Raise the window to the top of the stack
  , ((modm, button2), (\w -> focus w >> windows W.shiftMaster))
  -- mod-button3, Set the window to floating mode and resize by dragging
  , ((modm, button3), (\w -> focus w >> mouseResizeWindow w
                                     >> windows W.shiftMaster))
  -- you may also bind events to the mouse scroll wheel (button4 and button5)
  ]


myXPConfig = defaultXPConfig
  { position = Top
  , fgColor = "#ffffff"
  , bgColor = "#202020"
  , fgHLight = "#ffffff"
  , bgHLight = "#3465a4"
  , promptBorderWidth = 0
  , autoComplete = Just 500000
  }

------------------------------------------------------------------------
-- Topics

myTopics :: [Topic]
myTopics =
  [ "m1.misc", "m2.misc"
  , "chat", "nodes"
  , "w1.web", "w2.web", "w3.web", "w4.web"
  , "calendar", "mail", "reading"
  , "fileshare"
  , "music", "movie"
  , "sm.server:medeltiden", "ss.server:snowfish"
  , "wordpress"
  , "d1.dev", "d2.dev", "d3.dev", "d4.dev", "d5.dev", "d6.dev"
  , "eclipse"
  , "dotfiles"
  , "dashboard"
  , "virtualbox"
  ]

myTopicConfig :: TopicConfig

devPath="repos"
webPath="Downloads/browser"

myTopicConfig = TopicConfig
  { topicDirs = M.fromList $
    [ ("music"    ,"Music")
    , ("eclipse"  ,devPath)
    , ("d1.dev"    ,devPath), ("d2.dev", devPath), ("d3.dev", devPath), ("d4.dev", devPath), ("d5.dev", devPath), ("d6.dev", devPath)
    , ("w1.web"    ,webPath), ("w2.web", webPath), ("w3.web", webPath), ("w4.web", webPath)
    ]
  , defaultTopicAction = const $ spawnShell
  , defaultTopic = "dashboard"
  , maxTopicHistory = 10
  , topicActions = M.fromList $
    [ ("dotfiles",
       do
         spawn "dotfiles-edit"
         spawnShell
         spawnShellIn ".xmonad"
         spawnShellIn ".emacs.d"
      )
    , ("music",
       do
         spawn "rhythmbox"
         webBrowserOpen "http://discogs.com"
      )
    , ("mail",
       webAppSpawn "https://mail.google.com/a/jossystem.se/")
    , ("chat",
       do
         spawn "pidgin"
         spawn "xchat"
      )
    , ("m1.misc", return())
    , ("m2.misc", return())
    , ("w1.web", webBrowserSpawn )
    , ("w2.web", webBrowserSpawn )
    , ("w3.web", webBrowserSpawn )
    , ("w4.web", webBrowserSpawn )
    , ("fileshare",
       do
         spawn "krusader"
         spawn "transmission-gtk"
         spawn "nicotine.py"
      )
    , ("dashboard",
       do
         inTerm "saidar"
         inTerm "htop"
         spawn "pavucontrol"
      )
    , ("calendar",
       do
         webAppSpawn "http://www.google.com/calendar/hosted/jossystem.se/render"
      )
    , ("sm.server:medeltiden",
       do
         inTerm "ssh -A medeltiden"
      )
    , ("ss.server:snowfish",
       do
         inTerm "ssh -A dev.snowfish.com"
      )
    , ("nodes",
       do
         webBrowserOpen "http://twitter.com"
         webBrowserOpen "http://facebook.com"
         webBrowserOpen "https://plus.google.com/u/1/"
         webBrowserOpen "http://last.fm"
         webBrowserOpen "http://github.com"
         -- webBrowserOpen "http://skunk.nu"
         -- webBrowserOpen "http://linkedin.com"
         -- webBrowserOpen "http://mixcloud.com"
         -- webBrowserOpen "http://soundcloud.com"
         -- webBrowserOpen "http://wfmu.org"
         -- webBrowserOpen "http://threadless.com"
      )
    , ("reading",
       do
         webBrowserOpen "http://reader.google.com"
         webBrowserOpen "http://dn.se"
         webBrowserOpen "http://slashdot.org"
         webBrowserOpen "http://physorg.com"
         webBrowserOpen "http://medicalxpress.com"
      )
    , ("eclipse", spawn "eclipse")
    , ("virtualbox", spawn "VirtualBox")
    ]
  }


------------------------------------------------------------------------
-- Commands:

inTerm cmd = spawn (myTerminal ++ " -e " ++ cmd)

webAppSpawn url = spawn ("www-app '" ++ url ++ "'")
webBrowserSpawn = spawn "www-window"
webBrowserOpen url = spawn ("www-window " ++ url)

spawnShell :: X ()
spawnShell = currentTopicDir myTopicConfig >>= spawnShellIn

spawnShellIn :: Dir -> X ()
spawnShellIn dir = spawn $ myTerminal ++ " -e "
                   ++ "bash -c 'cd ''" ++ dir ++ "'' && " ++ myShell ++ "'"

goto :: Topic -> X ()
goto = switchTopic myTopicConfig

promptedGoto :: X ()
promptedGoto = workspacePrompt myXPConfig goto

promptedShift :: X ()
promptedShift = workspacePrompt myXPConfig $ windows . W.shift

nextNonEmptyWorkspace= windows . W.greedyView =<< findWorkspace getSortByIndexNoSP Next HiddenNonEmptyWS 1
prevNonEmptyWorkspace= windows . W.greedyView =<< findWorkspace getSortByIndexNoSP Prev HiddenNonEmptyWS 1

nextEmptyWorkspace= windows . W.greedyView =<< findWorkspace getSortByIndexNoSP Next EmptyWS 1
prevEmptyWorkspace= windows . W.greedyView =<< findWorkspace getSortByIndexNoSP Prev EmptyWS 1

getSortByIndexNoSP = fmap (.scratchpadFilterOutWorkspace) getSortByIndex

terminalPad = namedScratchpadAction myScratchPads "terminal"
irssiPad = namedScratchpadAction myScratchPads "irssi"

restartXmonad = spawn "xmonad --recompile && xmonad --restart"

myXMessage :: [((KeyMask, KeySym), NamedAction)] -> NamedAction
myXMessage x = addName "Show Keybindings" $ io $ do
  h <- spawnPipe "zenity --text-info"
  System.IO.UTF8.hPutStr h (unlines $ showKm x)
  hClose h
  return ()

-----------------------------------------------------------------------
-- Support functionality

--getScreenDim :: Rectangle

-- | Return the dimensions (x, y, width, height) of screen n.
getScreenDim :: Num a => Int -> IO (a, a, a, a)
getScreenDim n = do
  d <- openDisplay ""
  screens  <- getScreenInfo d
  closeDisplay d
  let rn = screens!!(min (abs n) (length screens - 1))
  case screens of
    []        -> return $ (0, 0, 1024, 768) -- fallback
    [r]       -> return $ (fromIntegral $ rect_x r , fromIntegral $ rect_y r , fromIntegral $ rect_width r , fromIntegral $ rect_height r )
    otherwise -> return $ (fromIntegral $ rect_x rn, fromIntegral $ rect_y rn, fromIntegral $ rect_width rn, fromIntegral $ rect_height rn)

------------------------------------------------------------------------
-- Scratch pads:

myScratchPads = [ NS "terminal" (term "terminal") (res =? scratch "terminal") bottomFloat
                , NS "irssi" (inTerm' "irssi" "ssh medeltiden.org") (res =? scratch "irssi") nonFloating
                ]
  where
    scratch name = "scratchpad_" ++ name
    term name = myTerminal ++ " -name scratchpad_" ++ name
    inTerm' name cmd = myTerminal ++ " -name scratchpad_" ++ name ++ " -e " ++  cmd
    res=resource

    bottomFloat=customFloating $ W.RationalRect l t w h
      where
        h = 0.2
        w = 1
        t = 1 - h
        l = (1 - w)/2

    largeCenterFloat=customFloating $ W.RationalRect l t w h
      where
        h = 0.95
        w = 0.95
        t = (1 - h)/2
        l = (1 - w)/2

------------------------------------------------------------------------
-- Urgency hook:

data LibNotifyUrgencyHook = LibNotifyUrgencyHook deriving (Read, Show)

instance UrgencyHook LibNotifyUrgencyHook where
  urgencyHook LibNotifyUrgencyHook w = do
    name <- getName w
    ws <- gets windowset
    whenJust (W.findTag w ws) (flash name)
      where
        flash name index = spawn ("notify-send '" ++ show name  ++ " requests your attention on workspace " ++ index ++ "'")

------------------------------------------------------------------------
-- Default configuration

aDefaultConfig =
  addDescrKeys' ((mod4Mask, xK_F1), myXMessage) myKeys $ defaultConfig
  { terminal           = myTerminal
  , focusFollowsMouse  = myFocusFollowsMouse
  , borderWidth        = myBorderWidth
  , modMask            = myModMask
  , workspaces         = myTopics
  , normalBorderColor  = myNormalBorderColor
  , focusedBorderColor = myFocusedBorderColor
  , keys               = emptyKeys
  , mouseBindings      = myMouseBindings
  , layoutHook         = myLayoutHook
  , manageHook         = myManageHook
  , handleEventHook    = myEventHook
  , startupHook        = myStartupHook
  }


-----------------------------------------------------------------------------
--  Auto config!
--
--


autoConfig=do
  checkTopicConfig myTopics myTopicConfig
  host <- fmap nodeName getSystemID
  return =<< chooseConfigByHost host
    where
      chooseConfigByHost c
        | c == "transwhale" = configFull
        | c == "a00001"     = configFull
        | c == "flux"       = configFull
        | c == "dennisg"    = configSimple
        | c == "wonky"      = configMinimal
        | c == "kranky"     = configMinimal
        | otherwise         = configSimple

-----------------------------------------------------------------------------
--
--  ConfigSimple is a default configuration with a simple xmobar setup
--
--  Should run and be compatible with most situations and quick set ups
--
--

configSimple = do
  myStatusProc <- spawnPipe myStatusBar
  return $ ewmh aDefaultConfig
    { logHook     = myXmobarLogHook myStatusProc
    }
    where
      myStatusBar="xmobar ~/.xmonad/etc/xmobar-simple"


-----------------------------------------------------------------------------
--
--  ConfigMinimal is for low end computers.
--
--  A minimal system requirements are something like:
--
--    * Display: ~800x600 (min. 1024x768 recommended)
--    * CPU: ~Pentium III 600hz
--    * RAM: 256Mb (min. 512mb recommended)
--
configMinimal = do
  myStatusProc <- spawnPipe myStatusBar
  return  $ ewmh aDefaultConfig
    { logHook     = myXmobarLogHook myStatusProc
    }
    where
      myStatusBar="xmobar ~/.xmonad/etc/xmobar-minimal"

-----------------------------------------------------------------------------
--
--  ConfigFull is an more involved setup with more tray bars and such
--
--
myUrgencyConfig = urgencyConfig { suppressWhen = XMonad.Hooks.UrgencyHook.Never }
myUrgencyHook = LibNotifyUrgencyHook
configFull = do
  (sx, sy, sw, sh) <- getScreenDim 0
  let
    screenW = sw
    xmonadW = screenW * 0.4
    trayerW = 80
    trayerO = screenW - trayerW
    statusW = screenW * 0.6 - trayerW
    statusO = screenW - statusW - trayerW
    xmonadBarCmd="dzen2 -xs 1 -ta l -w " ++ show xmonadW
    trayerBarCmd="trayer --transparent true --tint 0x111111 --alpha 0 --edge top --align left --widthtype pixel --width " ++ show trayerW ++ " --margin " ++ show trayerO ++ " --heighttype pixel --height 18"
    statusBarCmd="conky -c ~/.xmonad/etc/conkyrc-mainbar-config-full | dzen2 -xs 1 -ta r -x " ++ show statusO ++ " -w " ++ show statusW
    configStartupHook=myStartupHook

  xmonadBar <- spawnPipe xmonadBarCmd
  spawn statusBarCmd
  spawn trayerBarCmd
  return $ withUrgencyHookC myUrgencyHook myUrgencyConfig  $ ewmh aDefaultConfig
    { logHook = myDzenLogHook xmonadBar
    , manageHook = manageHook gnomeConfig <+> myManageHook
    , startupHook = configStartupHook
    }


