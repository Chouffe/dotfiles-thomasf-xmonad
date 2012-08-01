{-# LANGUAGE DeriveDataTypeable, FlexibleContexts,
  FlexibleInstances, MultiParamTypeClasses,
  NoMonomorphismRestriction, ScopedTypeVariables,
  TypeSynonymInstances, UndecidableInstances #-}
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
-----------------------------------------------------------------------------
module XMonad.Config.A00001
    ( -- * Usage
      -- $usage
      autoConfig
    ) where

import           Control.Monad
import qualified Data.Map                        as M
import           Graphics.X11.Xinerama
import           System.IO
import qualified System.IO.UTF8
import           System.Posix.Unistd             (getSystemID, nodeName)
import           XMonad                          hiding ( (|||) )
import           XMonad.Actions.CycleWS
import qualified XMonad.Actions.DynamicWorkspaces as DW
import           XMonad.Actions.PerWorkspaceKeys
import           XMonad.Actions.RotSlaves
import           XMonad.Actions.UpdatePointer
import           XMonad.Actions.WindowBringer    (gotoMenuArgs)
import qualified XMonad.Config.Desktop as Desktop
import           XMonad.Hooks.DynamicLog
import           XMonad.Hooks.EwmhDesktops       (ewmh)
import           XMonad.Hooks.ManageDocks as MD
import           XMonad.Hooks.ManageHelpers
import           XMonad.Hooks.ServerMode
import           XMonad.Hooks.UrgencyHook
import           XMonad.Layout.Decoration
import           XMonad.Layout.Fullscreen
import           XMonad.Layout.LayoutCombinators
import qualified XMonad.Layout.MultiToggle as MT
import qualified XMonad.Layout.MultiToggle.Instances as MTI
import           XMonad.Layout.Named
import           XMonad.Layout.NoBorders
import           XMonad.Layout.PerWorkspace      (onWorkspace)
import           XMonad.Layout.Reflect
import           XMonad.Layout.ShowWName
import           XMonad.Layout.Spiral
import           XMonad.Layout.Tabbed
import           XMonad.Layout.ThreeColumns
import           XMonad.Prompt
import           XMonad.Prompt.Workspace
import qualified XMonad.StackSet                 as W
import           XMonad.Util.EZConfig
import           XMonad.Util.NamedActions
import           XMonad.Util.NamedScratchpad
import           XMonad.Util.NamedWindows        (getName)
import           XMonad.Util.Run
import           XMonad.Util.WorkspaceCompare

------------------------------------------------------------------------
-- Basic random
--
myTerminal = "urxvt"
-- myShell = "bash"

myFocusFollowsMouse = False
myBorderWidth   = 4

------------------------------------------------------------------------
-- Border colors for unfocused and focused windows, respectively.
--
myNormalBorderColor  = "#859900"
myFocusedBorderColor = "#d33682"

------------------------------------------------------------------------
-- Workspaces

myWorkspaces = ["misc.1","misc.2","misc.3","misc.4"]

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

-- | Base decoration theme
baseTheme = defaultTheme { fontName            = "-*-fixed-medium-r-*--10-*-*-*-*-*-iso8859-1"
                         , decoHeight          = 12
                         }

-- | Copied from Tehemes
tabTheme = baseTheme { activeColor         = "#4c7899"
                     , inactiveColor       = "#333333"
                     , activeBorderColor   = "#285577"
                     , inactiveBorderColor = "#222222"
                     , activeTextColor     = "#ffffff"
                     , inactiveTextColor   = "#888888"
                     }

-- | Uses colors from solarized theme
-- titleTheme = baseTheme { inactiveColor       = "#eee8d5"
--                        , inactiveBorderColor = "#93a1a1"
--                        , inactiveTextColor   = "#657b83"
--                        }

-- | The layouthoook

myLayoutHook = showWorkspaceName $
               Desktop.desktopLayoutModifiers $ -- < only implies avoidStruts (ons jul 18 08:22 2012)
               onWorkspace "nodes" tabs $
               onWorkspace "reading" tabs $
               MT.mkToggle (MT.single MTI.NOBORDERS) $
               MT.mkToggle (MT.single MTI.NBFULL) $
               lessBorders OnlyFloat
               ((named "tall h"      $ Mirror tallH) |||
                (named "tall h flip" $ Mirror $ reflectHoriz tallH) |||
                (named "tall v"      $ tallV) |||
                (named "tall v flip" $ reflectHoriz tallV) |||
                (named "3col h"      $ threeCol) |||
                (named "3col v"      $ Mirror threeCol) |||
                (named "tabs"        $ tabs) |||
                (named "spiral"      $ spiral (6/7)))
  where
    tallH = Tall 1 (3/100) (4/5)
    tallV = Tall 1 (3/100) (3/4)
    threeCol = ThreeColMid 1 (3/100) (1/2)
    tabs = tabbed shrinkText tabTheme
    --titleDeco = deco titleTheme
    --deco t   = decoration shrinkText t Dwm
    showWorkspaceName = showWName'
                        defaultSWNConfig { swn_font = "-xos4-terminus-*-r-*-*-32-*-*-*-*-*-iso8859-*"
                                         , swn_bgcolor = "#073642"
                                         , swn_color = "#d33682"
                                         }

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

myManageHook = fullscreenManageHook <+>
               namedScratchpadManageHook myScratchPads <+>
               composeOne
  [ resource            =? "Do"                -?> doIgnore
  , resource            =? "desktop_window"    -?> doIgnore
  , resource            =? "kdesktop"          -?> doIgnore
  --, resource            =? "panel"             -?> doIgnore
  , className           =? "Unity-2d-panel"    -?> doIgnore
  , className           =? "Xfce4-notifyd"     -?> doIgnore
  , className           =? "Xfdesktop"         -?> doIgnore
  , resource            =? "speedbar"          -?> doFloat
  , resource            =? "emacs-floating"    -?> doFloat
  , className           =? "Unity-2d-launcher" -?> doFloat
  , className           =? "Gimp"              -?> doFloat
  , className           =? "Orage"             -?> doFloat
  , className    =? "Xfce4-settings-manager"   -?> doCenterFloat
  , className           =? "Xfce4-appfinder"   -?> doCenterFloat
  , className           =? "Pinentry"          -?> doCenterFloat
  , transience
  --, isFullscreen                               -?> doFullFloat
  , resource            =? "ssh_tmux"          -?> doF (W.shift "chat" )
  , resource            =? "empathy"           -?> doF (W.shift "chat")
  , resource            =? "xchat"             -?> doF (W.shift "chat")
  , className           =? "Pidgin"            -?> doF (W.shift "chat")
  , className           =? "Nicotine.py"       -?> doF (W.shift "fileshare")
  , className           =? "Transmission-gtk"  -?> doF (W.shift "fileshare")
  , resource            =? "xmessage"          -?> doCenterFloat
  , className           =? "feh"               -?> doFloat
  , className           =? "MPlayer"           -?> doFloat
  ] <+> manageHook Desktop.desktopConfig -- < implies only manageDocks (ons jul 18 08:51 2012)
  -- where
  --   role = stringProperty "WM_WINDOW_ROLE"

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
  , ppSort = fmap (.namedScratchpadFilterOutWorkspace) $ ppSort defaultPP
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
                   "Tall" -> "^fg(#777777)^i(/home/petar/.dzen/tall.xbm)"
                   _ -> x
               )
  , ppOutput            =   hPutStrLn h
  }
  where
    padWs ws = if ws == "NSP" then "" else pad ws

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

myStartupHook = return ()

------------------------------------------------------------------------
-- Keyboard configuration:

myModMask = mod4Mask
altMask = mod1Mask

-- align-regexp rules: "addName", "\$"

myKeys (XConfig {XMonad.modMask = modm}) =
  [ subtitle "Application launching"
  , ((modm.|. shiftMask, xK_Return),    addName "launch terminal"                                      $ spawnShell)

  , subtitle "Cyclic window actions (J/K) [+=focus] [+control=cycle+keep focus] [+shift=move]"
  , ((modm, xK_j),                      addName "Focus next window on workspace"                       $ windows W.focusDown >> movePointer)
  , ((modm, xK_k),                      addName "Focus previous window on workspace"                   $ windows W.focusUp >> movePointer)
  , ((modm.|. shiftMask, xK_j),         addName "Swap focused with next on workspace"                  $ windows W.swapDown >> movePointer)
  , ((modm.|. shiftMask, xK_k),         addName "Swap focused with previous on workspace"              $ windows W.swapUp >> movePointer)
  , ((modm.|. controlMask, xK_j),       addName "Rotate all windows forward while keeping focus"       $ rotAllUp >> movePointer)
  , ((modm.|. controlMask, xK_k),       addName "Rotate all windows backwards while keeping focus"     $ rotAllDown >> movePointer)

  , subtitle "Other window actions"
  , ((modm, xK_m),                      addName "Move focus to master window"                          $ windows W.focusMaster >> movePointer)
  , ((modm, xK_Return),                 addName "Swap the focused window and the master window"        $ windows W.swapMaster >> movePointer)
  , ((modm, xK_t),                      addName "Push the window into tiling mode"                     $ withFocused (windows . W.sink) >> movePointer)
  , ((modm.|. altMask, xK_f),           addName "Toggle fullscreen"                                    $ sendMessage (MT.Toggle MTI.NBFULL))
  , ((modm.|. controlMask, xK_c),       addName "kill"                                                 $ kill)

  , subtitle "Cyclic display actions (D/F) [+=select] [+control=swap] [+shift=move window to]"
  , ((modm, xK_d),                      addName "Next screen"                                          $ rmEmptyWs $ nextScreen >> movePointer)
  , ((modm, xK_f),                      addName "Previous screen"                                      $ rmEmptyWs $ prevScreen >> movePointer)
  , ((modm.|. controlMask, xK_d),       addName "Swap current display witn next"                       $ swapNextScreen >> nextScreen >> movePointer )
  , ((modm.|. controlMask, xK_f),       addName "Swap current display witn previous"                   $ swapNextScreen >> nextScreen >> movePointer )
  , ((modm.|. shiftMask, xK_d),         addName "Move window to next screen"                           $ shiftNextScreen >> nextScreen >> movePointer)
  , ((modm.|. shiftMask, xK_f),         addName "Move window to previous screen"                       $ shiftPrevScreen >> prevScreen >> movePointer)

  , subtitle "Workspace actions (E/R) [mod=select from prefix] [mod+control=select from all]"
  , ((modm, xK_e),                      addName "Next non enmpty workspace (prefix)"                   $ rmEmptyWs $ nextWsPrefix >> movePointer)
  , ((modm, xK_r),                      addName "Previous non empty workspace (prefix)"                $ rmEmptyWs $ prevWsPrefix >> movePointer)
  , ((modm.|. controlMask, xK_e),       addName "Next non empty workspace"                             $ rmEmptyWs $ nextWsNonEmpty >> movePointer)
  , ((modm.|. controlMask, xK_r),       addName "Previous non empty workspace"                         $ rmEmptyWs $ prevWsNonEmpty >> movePointer)

  , subtitle "Other workspace actions"
  , ((modm, xK_w),                      addName "Toggle previous workspace"                            $ ignoredToggleWS)

  , subtitle "Workspace prompts"
  , ((modm, xK_n),                      addName "Create or change workspace prompt"                    $ rmEmptyWs $ selectWorkspacePrompt >> maybeWorkspaceAction >> movePointer)
  , ((modm.|. shiftMask, xK_n),         addName "Move window to other workspace prompt"                $ DW.withWorkspace myXPConfig (windows . W.shift) >> movePointer)
  , ((modm.|. controlMask, xK_n),       addName "Rename current workspace"                             $ DW.renameWorkspace myXPConfig >> movePointer)
  , ((modm.|. shiftMask, xK_BackSpace), addName "Remove current workspace"                             $ DW.removeWorkspace >> movePointer)
  , ((modm, xK_o),                      addName "Goto workspace by window search prompt"               $ gotoMenuArgs ["-l 23"] >> movePointer)

  , subtitle "Modify current workspace layout... (H/L=size ,.=) [+alt=toggle]"
  , ((modm, xK_space),                  addName "Switch to the next window layout"                     $ sendMessage NextLayout >> movePointer)
  , ((modm, xK_h),                      addName "Shrink the master area"                               $ sendMessage Shrink >> movePointer)
  , ((modm, xK_l),                      addName "Expand the master area"                               $ sendMessage Expand >> movePointer)
  , ((modm, xK_comma),                  addName "Increment the number of windows in the master area"   $ sendMessage (IncMasterN 1) >> movePointer)
  , ((modm, xK_period),                 addName "Deincrement the number of windows in the master area" $ sendMessage (IncMasterN (-1)) >> movePointer)
  , ((modm.|. altMask, xK_b),           addName "Toggle borders"                                       $ sendMessage (MT.Toggle MTI.NOBORDERS))
  , ((modm.|. altMask, xK_s),           addName "Toggle struts"                                        $ sendMessage ToggleStruts)

  , subtitle "Toggle scratchpads and workspaces"
  , ((modm, xK_section),                addName "Toggle small terminal pad"                            $ smallTerminalPad >> movePointer)
  , ((modm.|.shiftMask, xK_section),    addName "Toggle large terminal pad"                            $ largeTerminalPad >> movePointer)
  , ((modm, xK_1),                      addName "Toggle chat workspace"                                $ myViewWS "chat")
  , ((modm, xK_2),                      addName "Toggle nodes workspace"                               $ myViewWS "nodes")
  , ((modm, xK_3),                      addName "Toggle nodes workspace"                               $ myViewWS "reading")
  , ((modm, xK_4),                      addName "Toggle mail workspace"                                $ myViewWS "mail")
  , ((modm, xK_5),                      addName "Switch to calendar workspace"                         $ myViewWS "cal")
  , ((modm, xK_6),                      addName "Toggle fileshare workspace"                           $ myViewWS "fileshare")
  , ((modm, xK_0),                      addName "Toggle dashboard workspace"                           $ myViewWS "dash")


  ] where
    ignoredToggleWS = toggleWS' ["NSP", "nodes", "dash", "mail", "cal"
                                , "temp", "chat", "fileshare"] >> movePointer

    myViewWS wsid = do
      DW.addHiddenWorkspace wsid
      windows (W.view wsid)
      maybeWorkspaceAction
      movePointer

    -- myToggleWS wsid = bindOn [ (wsid, ignoredToggleWS), ("", myViewWS wsid) ]

    selectWorkspacePrompt = workspacePrompt myXPConfig $ \w ->
                            do s <- gets windowset
                               if W.tagMember w s
                                 then windows $ W.view w
                                 else DW.addWorkspace w

emptyKeys c = mkKeymap c [ ]

------------------------------------------------------------------------
-- Mouse bindings: default actions bound to mouse events
--
myMouseBindings (XConfig {XMonad.modMask = modm}) = M.fromList
  -- mod-button1, Set the window to floating mode and move by dragging
  [ ((modm, button1), \w -> focus w >> mouseMoveWindow w
                                    >> windows W.shiftMaster)
  -- mod-button2, Raise the window to the top of the stack
  , ((modm, button2), \w -> focus w >> windows W.shiftMaster)
  -- mod-button3, Set the window to floating mode and resize by dragging
  , ((modm, button3), \w -> focus w >> mouseResizeWindow w
                                    >> windows W.shiftMaster)
  -- you may also bind events to the mouse scroll wheel (button4 and button5)
  ]

------------------------------------------------------------------------
-- XMonad Prompt configuration

myXPConfig = defaultXPConfig{ position = Top
  , bgColor = "#859900"
  , fgColor = "#fdf6e3"
  , bgHLight = "#b58900"
  , fgHLight = "#fdf6e3"
  , promptBorderWidth = 0
  }

-- myAutocompleteXPConfig = myXPConfig
--   { autoComplete = Just 500000  }

------------------------------------------------------------------------
-- Commands:

-- inTerm cmd = spawn (myTerminal ++ " -name " ++ cmd  ++ " -e " ++ cmd)
-- webAppSpawn url = spawn ("www-app '" ++ url ++ "'")
-- webBrowserSpawn = spawn "www-window"
-- webBrowserOpen url = spawn ("www-window " ++ url)

spawnShell :: X ()
spawnShell = spawn myTerminal

nextWsNonEmpty = windows . W.greedyView
         =<< findWorkspace getSortByTagNoSP Next HiddenNonEmptyWS 1
prevWsNonEmpty = windows . W.greedyView
         =<< findWorkspace getSortByTagNoSP Prev HiddenNonEmptyWS 1

nextWsPrefix = windows . W.greedyView
               =<< findWorkspace getSortByTagNoSP Next (HiddenWSTagGroup '.') 1

prevWsPrefix = windows . W.greedyView
               =<< findWorkspace getSortByTagNoSP Prev (HiddenWSTagGroup '.') 1

getSortByTagNoSP = fmap (.namedScratchpadFilterOutWorkspace) getSortByTag

smallTerminalPad = namedScratchpadAction myScratchPads "smallTerminal"
largeTerminalPad = namedScratchpadAction myScratchPads "largeTerminal"

------------------------------------------------------------------------
-- Utils

-- | Run script with same name as "w.workspacename" if the workspace is empty
maybeWorkspaceAction = do
  ws <- gets (W.currentTag . windowset)
  wins <- gets (W.integrate' . W.stack . W.workspace . W.current . windowset)
  when (null wins) $ spawn ("w." ++ takeWhile (/='.') ws)

-- | Remove current workpace if empty
rmEmptyWs = DW.removeEmptyWorkspaceAfter

-- | Move mouse pointer to bottom right of the current window
movePointer = updatePointer (Relative 0.99 0.99)

-- | Display keyboard mappings using zenity
showKeybindings :: [((KeyMask, KeySym), NamedAction)] -> NamedAction
showKeybindings x = addName "Show Keybindings" $ io $ do
  h <- spawnPipe "zenity --text-info"
  System.IO.UTF8.hPutStr h (unlines $ showKm x)
  hClose h
  return ()

-- | Return the dimensions (x, y, width, height) of screen n.
getScreenDim :: Num a => Int -> IO (a, a, a, a)
getScreenDim n = do
  d <- openDisplay ""
  screens  <- getScreenInfo d
  closeDisplay d
  let rn = screens !!(min (abs n) (length screens - 1))
  case screens of
    []        -> return (0, 0, 1024, 768) -- fallback
    [r]       -> return (fromIntegral $ rect_x r , fromIntegral $ rect_y r ,
                         fromIntegral $ rect_width r , fromIntegral $ rect_height r )
    otherwise -> return (fromIntegral $ rect_x rn, fromIntegral $ rect_y rn,
                         fromIntegral $ rect_width rn, fromIntegral $ rect_height rn)

-- | Determine the number of physical screens.
-- countScreens :: (MonadIO m, Integral i) => m i
-- countScreens = liftM genericLength . liftIO $ openDisplay "" >>= getScreenInfo

------------------------------------------------------------------------
-- Scratch pads:

myScratchPads = [ NS "smallTerminal" (term "smallTerminal") (res =? scratch "smallTerminal") bottomFloat
                , NS "largeTerminal" (term "largeTerminal") (res =? scratch "largeTerminal") largeCenterFloat
                ]
  where
    scratch sname = "scratchpad_" ++ sname
    term sname = myTerminal ++ " -name scratchpad_" ++ sname
    -- inTerm' sname scmd = myTerminal ++ " -name scratchpad_" ++ sname ++ " -e " ++  scmd
    res = resource

    bottomFloat = customFloating $ W.RationalRect l t w h
      where
        h = 0.2
        w = 1
        t = 1 - h
        l = (1 - w)/2

    largeCenterFloat = customFloating $ W.RationalRect l t w h
      where
        h = 0.8
        w = 0.8
        t = (1 - h)/2
        l = (1 - w)/2

------------------------------------------------------------------------
-- Urgency hook:

data LibNotifyUrgencyHook = LibNotifyUrgencyHook deriving (Read, Show)

instance UrgencyHook LibNotifyUrgencyHook where
  urgencyHook LibNotifyUrgencyHook w = do
    workspaceName <- getName w
    ws <- gets windowset
    whenJust (W.findTag w ws) (flash workspaceName)
      where
        flash workspaceName index = spawn ("notify-send '"
                                           ++ show workspaceName
                                           ++ " requests your attention on workspace "
                                           ++ index
                                           ++ "'")

myUrgencyConfig = urgencyConfig { suppressWhen = XMonad.Hooks.UrgencyHook.Never }
myUrgencyHook = LibNotifyUrgencyHook

------------------------------------------------------------------------
-- Default configuration

aDefaultConfig =
  addDescrKeys' ((mod4Mask, xK_F1), showKeybindings) myKeys $ defaultConfig
  { terminal           = myTerminal
  , focusFollowsMouse  = myFocusFollowsMouse
  , borderWidth        = myBorderWidth
  , modMask            = myModMask
  , workspaces         = myWorkspaces
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
-- | Auto config!
--
autoConfig=do
  host <- fmap nodeName getSystemID
  return =<< chooseConfigByHost host
    where
      chooseConfigByHost c
        | c == "transwhale" = configFull
        | c == "a00001"     = configFull
        | c == "flux"       = configFull
        | c == "kranky"     = configFull
        | c == "mat"        = configFull
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
    { logHook = myXmobarLogHook myStatusProc
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
configFull = do
  (sx, sy, sw, sh) <- getScreenDim 0
  let
    screenW = sw
    xmonadW = screenW * 0.4
    trayerW = 80
    trayerO = screenW - trayerW
    statusW = screenW * 0.6 - trayerW
    statusO = screenW - statusW - trayerW
    xmonadBarCmd = "dzen2 -xs 1 -ta l -w " ++ show xmonadW
    trayerBarCmd = "trayer --transparent true --tint 0x111111 --alpha 0 --edge top --align left"
                   ++ " --widthtype pixel --width " ++ show trayerW
                   ++ " --margin " ++ show trayerO
                   ++ " --heighttype pixel --height 18"
    statusBarCmd = "conky -c ~/.xmonad/etc/conkyrc-mainbar-config-full "
                   ++ "| dzen2 -xs 1 -ta r -x " ++ show statusO ++ " -w " ++ show statusW
    configStartupHook = myStartupHook

  xmonadBar <- spawnPipe xmonadBarCmd
  spawn statusBarCmd
  spawn trayerBarCmd
  return $ withUrgencyHookC myUrgencyHook myUrgencyConfig  $ ewmh aDefaultConfig
    { logHook = myDzenLogHook xmonadBar
    , manageHook = myManageHook
    , startupHook = configStartupHook
    }
