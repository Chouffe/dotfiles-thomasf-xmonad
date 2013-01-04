{-# LANGUAGE DeriveDataTypeable, FlexibleContexts,
  FlexibleInstances, MultiParamTypeClasses,
  NoMonomorphismRestriction, ScopedTypeVariables,
  TypeSynonymInstances, UndecidableInstances,
  PostfixOperators #-}
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

import Data.Maybe (isJust, catMaybes)
import Data.List
import           Control.Monad
import qualified Data.Map                        as M
import           Data.Ratio ((%))
import           Graphics.X11.Xinerama
import           System.IO
import qualified System.IO.UTF8
import           System.Posix.Unistd             (getSystemID, nodeName)
import           XMonad                          hiding ( (|||) )
import           XMonad.Actions.CycleWS hiding (toggleWS)
import qualified XMonad.Actions.DynamicWorkspaces as DW
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
import           XMonad.Layout.MouseResizableTile
import           XMonad.Layout.Decoration
import           XMonad.Layout.Fullscreen
import           XMonad.Layout.Grid
import           XMonad.Layout.IM
import           XMonad.Layout.LayoutCombinators
import qualified XMonad.Layout.MultiToggle as MT
import qualified XMonad.Layout.MultiToggle.Instances as MTI
import           XMonad.Layout.Renamed
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
import           XMonad.Util.Run
import           XMonad.Util.WorkspaceCompare
import qualified XMonad.Util.Dzen as DZ
import qualified Solarized as Sol
------------------------------------------------------------------------
-- Keyboard configuration:

-- simply for convenience and readability
super = mod4Mask
alt   = mod1Mask
ctrl  = controlMask
shft  = shiftMask
confModMask = super

-- align-regexp rules: "addName", "\$"
myKeys conf@(XConfig {XMonad.modMask = modm}) =
  [ subtitle "Application launching"
  , ((modm.|. shft, xK_Return),    addName "launch terminal"                                      $ spawnShell)

  , subtitle "Cyclic window actions (J/K) [+=focus] [+control=cycle+keep focus] [+shift=move]"
  , ((modm, xK_j),                 addName "Focus next window on workspace"                       $ windows W.focusDown >> movePointer)
  , ((modm, xK_k),                 addName "Focus previous window on workspace"                   $ windows W.focusUp >> movePointer)
  , ((modm.|. shft, xK_j),         addName "Swap focused with next on workspace"                  $ windows W.swapDown >> movePointer)
  , ((modm.|. shft, xK_k),         addName "Swap focused with previous on workspace"              $ windows W.swapUp >> movePointer)
  , ((modm.|. ctrl, xK_j),         addName "Rotate all windows forward while keeping focus"       $ rotAllUp >> movePointer)
  , ((modm.|. ctrl, xK_k),         addName "Rotate all windows backwards while keeping focus"     $ rotAllDown >> movePointer)

  , subtitle "Other window actions"
  , ((modm, xK_m),                 addName "Move focus to master window"                          $ windows W.focusMaster >> movePointer)
  , ((modm, xK_Return),            addName "Swap the focused window and the master window"        $ windows W.swapMaster >> movePointer)
  , ((modm, xK_t),                 addName "Push the window into tiling mode"                     $ withFocused (windows . W.sink) >> movePointer)
  , ((modm.|. ctrl, xK_c),         addName "kill"                                                 $ kill)
  , ((modm, xK_u),                 addName "Focus urgent winow"                                   $ focusUrgent >> movePointer >> showWorkspaceName)
  , ((modm.|. ctrl, xK_u),         addName "Clear all urgent window statuses"                     $ clearUrgents)

  , subtitle "Cyclic display actions (D/F) [+=select] [+control=swap] [+shift=move window to]"
  , ((modm, xK_d),                 addName "Next screen"                                          $ nextScreen >> movePointer >> showWorkspaceNameFast)
  , ((modm, xK_f),                 addName "Previous screen"                                      $ prevScreen >> movePointer >> showWorkspaceNameFast)
  , ((modm.|. ctrl, xK_d),         addName "Swap current display witn next"                       $ swapNextScreen >> showWorkspaceNameOld >> nextScreen >> movePointer >> showWorkspaceName)
  , ((modm.|. ctrl, xK_f),         addName "Swap current display witn previous"                   $ swapPrevScreen >> showWorkspaceNameOld >> nextScreen >> movePointer >> showWorkspaceName)
  , ((modm.|. shft, xK_d),         addName "Move window to next screen"                           $ shiftNextScreen >> nextScreen >> movePointer >> showWorkspaceNameFast)
  , ((modm.|. shft, xK_f),         addName "Move window to previous screen"                       $ shiftPrevScreen >> prevScreen >> movePointer >> showWorkspaceNameFast)

  , subtitle "Workspace actions (E/R) [mod=select from prefix] [mod+control=select from all]"
  , ((modm, xK_e),                 addName "Next workspace (prefix)"                              $ rmEmptyWs $ nextWsPrefix >> movePointer >> showWorkspaceName)
  , ((modm, xK_r),                 addName "Previous workspace (prefix)"                          $ rmEmptyWs $ prevWsPrefix >> movePointer >> showWorkspaceName)
  , ((modm.|. ctrl, xK_e),         addName "Next non empty workspace"                             $ rmEmptyWs $ nextWsNonEmpty >> movePointer >> showWorkspaceName)
  , ((modm.|. ctrl, xK_r),         addName "Previous non empty workspace"                         $ rmEmptyWs $ prevWsNonEmpty >> movePointer >> showWorkspaceName)
  , ((modm.|. alt, xK_e),          addName "New workspace in prefix.sequence"                     $ newPrefixWS >> movePointer >> showWorkspaceName)

  , subtitle "Other workspace actions"
  , ((modm, xK_w),                 addName "Toggle previous workspace"                            $ rmEmptyWs $ toggleWS >> showWorkspaceNameFast)
  , ((modm.|. ctrl, xK_w),         addName "Toggle previous workspace skipping some workspaces"   $ rmEmptyWs $ ignoredToggleWS >> showWorkspaceNameFast)
  , ((modm, xK_q),                 addName "Run default workspace launcer script"                 $ workspaceAction)

  , subtitle "Workspace prompts"
  , ((modm, xK_n),                 addName "Create or change workspace prompt"                    $ rmEmptyWs $ selectWorkspacePrompt >> maybeWorkspaceAction >> movePointer >> showWorkspaceName)
  , ((modm.|. shft, xK_n),         addName "Move window to other workspace prompt"                $ DW.withWorkspace myXPConfig (windows . W.shift) >> movePointer >> showWorkspaceName)
  , ((modm.|. ctrl, xK_n),         addName "Rename current workspace"                             $ DW.renameWorkspace myXPConfig >> movePointer >> showWorkspaceName)
  , ((modm.|. ctrl, xK_BackSpace), addName "Remove current workspace"                             $ DW.removeWorkspace >> movePointer >> showWorkspaceName)
  , ((modm, xK_o),                 addName "Goto workspace by window search prompt"               $ gotoMenuArgs ["-l 23"] >> movePointer >> showWorkspaceName)

  , subtitle "Modify current workspace layout... (H/L=size ,.=) [+alt=toggle]"
  , ((modm, xK_space),             addName "Switch to the next window layout"                     $ sendMessage NextLayout >> movePointer >> showLayoutName)
  , ((modm.|. ctrl, xK_space),     addName "Switch to default layout"                             $ sendMessage (JumpToLayout "tabs") >> movePointer >> showLayoutName)
  , ((modm.|. alt, xK_space),      addName "Toggle fullscreen"                                    $ sendMessage (MT.Toggle MTI.NBFULL) >> movePointer)
  , ((modm.|. alt, xK_s),          addName "Toggle struts (ignore panels)"                        $ sendMessage ToggleStruts >> movePointer)
  , ((modm.|. alt, xK_b),          addName "Toggle window borders"                                $ sendMessage (MT.Toggle MTI.NOBORDERS) >> movePointer)
  , ((modm, xK_h),                 addName "Shrink the master area"                               $ sendMessage Shrink >> movePointer)
  , ((modm, xK_l),                 addName "Expand the master area"                               $ sendMessage Expand >> movePointer)
  , ((modm, xK_comma),             addName "Increment the number of windows in the master area"   $ sendMessage (IncMasterN 1) >> movePointer)
  , ((modm, xK_period),            addName "Deincrement the number of windows in the master area" $ sendMessage (IncMasterN (-1)) >> movePointer)


  , subtitle "Toggle scratchpads and workspaces"
  , ((modm, xK_section),           addName "Toggle larger terminal pad"                           $ largeTerminalPad >> movePointer)
  , ((modm, xK_1),                 addName "Toggle home workspace"                                $ rmEmptyWs $ myViewWS "home" >> movePointer >> showWorkspaceNameFast)
  , ((modm, xK_2),                 addName "Toggle chat workspace"                                $ rmEmptyWs $ myViewWS "chat" >> movePointer >> showWorkspaceNameFast)
  , ((modm, xK_3),                 addName "Toggle nodes workspace"                               $ rmEmptyWs $ myViewWS "nodes" >> movePointer >> showWorkspaceNameFast)
  , ((modm, xK_4),                 addName "Toggle mail workspace"                                $ rmEmptyWs $ myViewWS "mail" >> movePointer >> showWorkspaceNameFast)
  , ((modm, xK_0),                 addName "Toggle dashboard workspace"                           $ rmEmptyWs $ myViewWS "dash" >> movePointer >> showWorkspaceNameFast)

  ] where

    -- | Move mouse pointer to bottom right of the current window
    movePointer = updatePointer (Relative 0.99 0.99)

    -- | Run script with same name as "w.workspacename"
    workspaceAction = do
      ws <- gets (W.currentTag . windowset)
      spawn ("w." ++ takeWhile (/='.') ws)

    -- | Run script with same name as "w.workspacename" if the workspace is empty
    maybeWorkspaceAction = do
      wins <- gets (W.integrate' . W.stack . W.workspace . W.current . windowset)
      when (null wins) $ workspaceAction

    -- | Remove current workpace if empty
    rmEmptyWs = DW.removeEmptyWorkspaceAfterExcept [ "NSP", "home", "nodes", "dash"]

    -- | Toggle recent workspaces ignoring some of them
    toggleWS = toggleWS' [ "NSP" ] >> movePointer

    -- | Toggle recent workspaces ignoring some of them
    ignoredToggleWS = toggleWS' [ "NSP"
                                , "home", "nodes", "dash", "mail"
                                , "chat", "im" ] >> movePointer

    -- | View a workspace by name
    myViewWS wsid = do
      DW.addHiddenWorkspace wsid
      windows (W.greedyView wsid)
      maybeWorkspaceAction

    -- | Select workspae prompt
    selectWorkspacePrompt = workspacePrompt myXPConfig $ \w ->
                            do s <- gets windowset
                               if W.tagMember w s
                                 then windows $ W.view w
                                 else DW.addWorkspace w

    -- | Open larger terminal pad
    largeTerminalPad = namedScratchpadAction myScratchPads "largeTerminal"

    -- | Select next non empty workspace
    nextWsNonEmpty = windows . W.greedyView
                     =<< findWorkspace getSortByTagNoSP Next HiddenNonEmptyWS 1

    -- | Select previous non empty workspace
    prevWsNonEmpty = windows . W.greedyView
                     =<< findWorkspace getSortByTagNoSP Prev HiddenNonEmptyWS 1

    -- |  Select next workspace with same prefix
    nextWsPrefix = windows . W.greedyView
                   =<< findWorkspace getSortByTagNoSP Next (HiddenWSTagGroup '.') 1

    -- | Select previous workspac with same prefix
    prevWsPrefix = windows . W.greedyView
                   =<< findWorkspace getSortByTagNoSP Prev (HiddenWSTagGroup '.') 1

    -- | Sort workspaces by tag name, exclude hidden scrachpad workspace.
    getSortByTagNoSP = fmap (.namedScratchpadFilterOutWorkspace) getSortByTag

    -- | TODO: rewrite
    newPrefixWS :: X ()
    newPrefixWS = withWindowSet $ \w -> do
      thisWS <- gets (W.currentTag . windowset)
      let wss = W.workspaces w
          currentTagPrefix = takeWhile (/='.') thisWS
          cws = map W.tag $ filter (\ws -> (currentTagPrefix ++ ".") `isPrefixOf` W.tag ws && isJust (W.stack ws)) wss
          num = head $ [0..] \\ catMaybes (map (readMaybe . drop ((length currentTagPrefix) +1 )) cws)
          new = currentTagPrefix ++ "." ++ (show num)
      when (not $ new `elem` (map W.tag wss)) $ myViewWS new
      windows $ W.view new
        where readMaybe s = case reads s of
                       [(r,_)] -> Just r
                       _       -> Nothing




------------------------------------------------------------------------
-- Basic random
--
myTerminal = "urxvt"
-- myShell = "bash"

------------------------------------------------------------------------
-- Border colors for unfocused and focused windows, respectively.
--
myNormalBorderColor  = Sol.green
myFocusedBorderColor = Sol.magenta

------------------------------------------------------------------------
-- Workspaces

myWorkspaces = [ "home", "temp.0", "chat", "nodes", "dash" ]

------------------------------------------------------------------------
-- Layouts:

-- You can specify and transform your layouts by modifying these values.
-- If you change layout bindings be sure to use 'mod-shift-space' after
-- restarting (with 'mod-q') to reset your layout state to the new
-- defaults, as xmonad preserves your old layout settings by default.

defaultFont = "-xos4-terminus-*-r-*-*-12-*-*-*-*-*-iso8859-*"
largeFont = "-xos4-terminus-*-r-*-*-32-*-*-*-*-*-iso8859-*"

-- | Base decoration theme
baseTheme = defaultTheme { fontName            = defaultFont
                         , decoHeight          = 12 }

-- | Decoration theme for tabbed layouts
tabTheme = baseTheme { activeColor         = Sol.blue
                     , inactiveColor       = Sol.base03
                     , activeBorderColor   = Sol.blue
                     , inactiveBorderColor = Sol.base03
                     , activeTextColor     = Sol.base03
                     , inactiveTextColor   = Sol.blue
                     , urgentColor         = Sol.magenta
                     , urgentTextColor     = Sol.base03
                     , urgentBorderColor   = Sol.magenta }

-- | The layouthoook
myLayoutHook = Desktop.desktopLayoutModifiers $ -- < only implies avoidStruts (ons jul 18 08:22 2012)
               MT.mkToggle (MT.single MTI.NOBORDERS) $
               MT.mkToggle (MT.single MTI.NBFULL) $
               onWorkspace "dash" (renamed [Replace "*"] $ tabsAlways) $
               onWorkspace "chat" ((renamed [Replace "*"]) $ grid) $
               onWorkspace "mail" ((renamed [Replace "*"]) $ grid) $
               onWorkspace "home" ((renamed [Replace "*"]) $ grid) $
               onWorkspace "nodes" ((renamed [Replace "*"]) $ grid) $
               onWorkspace "im" (renamed [Replace "*"] $ im) $
               onWorkspace "reading" (renamed [Replace "*"] $ tabs) $
               lessBorders OnlyFloat
               ((renamed [Replace "tabs"]        $ tabsAlways) |||
                (renamed [Replace "tall h"]      $ Mirror tallH) |||
                (renamed [Replace "tall v"]      $ tallV) |||
                (renamed [Replace "3col h"]      $ threeCol) |||
                (renamed [Replace "3col v"]      $ Mirror threeCol) |||
                (renamed [Replace "grid"]        $ grid ) |||
                (renamed [Replace "spiral"]      $ spiral (6/7)))
  where
    tallH = Tall 1 (3/100) (4/5)
    tallV = Tall 1 (3/100) (3/4)
    -- TODO: these might be usable with a bit of tweaking
    -- tallH = mouseResizableTileMirrored { nmaster  = 1
    --                                    , masterFrac = (4/5)
    --                                    , slaveFrac = (1/2)
    --                                    , fracIncrement = (3/100)
    --                                    , draggerType = BordersDragger }
    -- tallV = mouseResizableTile { nmaster  = 1
    --                            , masterFrac = (3/4)
    --                            , slaveFrac = (1/2)
    --                            , fracIncrement = (3/100)
    --                            , draggerType = BordersDragger }
    threeCol = ThreeColMid 1 (3/100) (1/2)
    tabsAlways = tabbedAlways shrinkText tabTheme
    tabs = tabbed shrinkText tabTheme
    grid = GridRatio (16/9)
    im = withIM (1%7) (Role "buddy_list") Grid
    --titleDeco = deco titleTheme
    --deco t   = decoration shrinkText t Dwm

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

myManageHook =
  fullscreenManageHook <+>  namedScratchpadManageHook myScratchPads <+> (composeOne . concat $
  [ [resource  =? r -?>                                        doIgnore      | r <- ignoreByResource]
  , [className =? c -?>                                        doIgnore      | c <- ignoreByClass]
  , [className =? c -?>                                        doSink        | c <- androidEmulatorByClass]
  , [resource  =? r -?>                                        doFloat       | r <- floatByResource]
  , [className =? c -?>                                        doFloat       | c <- floatByClass]
  , [role      =? "pop-up" <&&> appName =? "google-chrome" -?> doCenterFloat]
  , [className =? c -?>                                        doCenterFloat | c <- centerFloatByClass]
  , [resource  =? c -?>                                        doCenterFloat | c <- centerFloatByResource]
  , [transience]
  , [resource  =? "xmessage"          -?> doCenterFloat]
  , [title     =? "Onboard"           -?> doFloat]
  ]) <+> manageHook Desktop.desktopConfig -- < implies only manageDocks (ons jul 18 08:51 2012)
  where
    doSink = ask >>= doF . W.sink
    role = stringProperty "WM_WINDOW_ROLE"
    androidEmulatorByClass =
      ["emulator64-mips", "emulator-arm", "emulator-x86"
      ,"emulator64-arm", "emulator64-x86", "emulator-mips"]
    ignoreByResource =
      ["Do", "desktop_window", "kdesktop"]
    ignoreByClass =
      ["Unity-2d-panel", "Xfce4-notifyd", "Xfdesktop"]
    floatByResource =
      ["speedbar", "floating"]
    floatByClass =
      ["Unity-2d-launcher", "Orage", "feh"]
    centerFloatByResource =
      ["floating-center"]
    centerFloatByClass =
      ["Xfce4-settings-manager", "Xfce4-appfinder", "Pinentry"]

------------------------------------------------------------------------
-- Event handling

-- Defines a <custom handler function for X Events. The function should
-- return (All True) if the default handler is to be run afterwards. To
-- combine event hooks use mappend or mconcat from Data.Monoid.
--
myEventHook = serverModeEventHook <+> fullscreenEventHook

------------------------------------------------------------------------
-- Status bars and logging

-- Perform an arbitrary action on each internal state change or X event.
-- See the 'XMonad.Hooks.DynamicLog' extension for examples.
--
doublepad =  wrap "  " "  " . trim

myXmobarLogHook h = dynamicLogWithPP defaultPP
  { ppCurrent = xmobarColor Sol.base03 Sol.blue . doublepad
  , ppVisible = xmobarColor Sol.blue "" . doublepad
  , ppHidden  = const ""
  , ppUrgent  = xmobarColor Sol.base03 Sol.orange . doublepad
  , ppTitle   = xmobarColor Sol.yellow  "" . shorten 50 . trim
  , ppLayout  = xmobarColor Sol.base01 "" . trim
  , ppSep     = xmobarColor Sol.cyan "" "  *  "
  , ppOutput  = hPutStrLn h
  , ppSort    = getSortByXineramaRule
  }

myDzenLogHook h = dynamicLogWithPP $ myPP h

myPP h = defaultPP
  { ppCurrent = dzenColor Sol.base03 Sol.blue . doublepad
  , ppVisible = dzenColor Sol.blue "" . doublepad
  , ppHidden  = const ""
  , ppUrgent  = dzenColor Sol.base03 Sol.orange . doublepad
  , ppTitle   = dzenColor Sol.yellow "" . dzenEscape . trim
  , ppLayout  = dzenColor Sol.base01 "" . trim
  , ppSep     = dzenColor Sol.cyan "" "  *  "
  , ppOutput  = hPutStrLn h
  , ppSort    = getSortByXineramaRule
  }
  --where
  --  padWs ws = if ws == "NSP" then "" else pad ws

------------------------------------------------------------------------
-- Startup hook
--
-- Perform an arbitrary action each time xmonad starts or is restarted
-- with mod-q.  Used by, e.g., XMonad.Layout.PerWorkspace to initialize
-- per-workspace layout choices.
--

myStartupHook = return ()


------------------------------------------------------------------------
-- Urgency hook

myUrgencyHook =
  withUrgencyHookC BorderUrgencyHook
    { urgencyBorderColor = Sol.orange }
    urgencyConfig
      { suppressWhen = XMonad.Hooks.UrgencyHook.Focused }


------------------------------------------------------------------------
-- Mouse bindings: default actions bound to mouse events
--


------------------------------------------------------------------------
-- XMonad Prompt configuration

myXPConfig = defaultXPConfig
 { position = Top
 , bgColor = Sol.base03
 , fgColor = Sol.yellow
 , bgHLight = Sol.yellow
 , fgHLight = Sol.base03
 , promptBorderWidth = 0
 , font = "-xos4-terminus-*-r-*-*-16-*-*-*-*-*-iso8859-*" }

-- myAutocompleteXPConfig = myXPConfig
--   { autoComplete = Just 500000  }

------------------------------------------------------------------------
-- Commands:

spawnShell :: X ()
spawnShell = spawn myTerminal

------------------------------------------------------------------------
-- Scratch pads:

myScratchPads = [ NS "largeTerminal" (term "largeTerminal") (res =? scratch "largeTerminal") largeCenterFloat
                ]
  where
    scratch sname = "scratchpad_" ++ sname
    term sname = myTerminal ++ " -name scratchpad_" ++ sname
    -- inTerm' sname scmd = myTerminal ++ " -name scratchpad_" ++ sname ++ " -e " ++  scmd
    res = resource

    largeCenterFloat = customFloating $ W.RationalRect l t w h
      where
        h = 0.8
        w = 0.8
        t = (1 - h)/2
        l = (1 - w)/2

------------------------------------------------------------------------
-- Default configuration

aDefaultConfig =
  addDescrKeys' ((confModMask, xK_F1), showKeybindings) myKeys $ defaultConfig
  { terminal           = myTerminal
  , focusFollowsMouse  = False
  , borderWidth        = 4
  , modMask            = confModMask
  , workspaces         = myWorkspaces
  , normalBorderColor  = myNormalBorderColor
  , focusedBorderColor = myFocusedBorderColor
  , keys               = emptyKeys
  , layoutHook         = myLayoutHook
  , manageHook         = myManageHook
  , handleEventHook    = myEventHook
  , startupHook        = myStartupHook
  } where
    --  | An empty keymap
    emptyKeys c = mkKeymap c [ ]

    -- | Display keyboard mappings using zenity
    showKeybindings :: [((KeyMask, KeySym), NamedAction)] -> NamedAction
    showKeybindings x = addName "Show Keybindings" $ io $ do
      h <- spawnPipe "zenity --text-info"
      System.IO.UTF8.hPutStr h (unlines $ showKm x)
      hClose h
      return ()

-----------------------------------------------------------------------------
-- | Auto config!
--
autoConfig=do
  host <- fmap nodeName getSystemID
  return =<< chooseConfigByHost host
    where
      chooseConfigByHost c
        | c == "wonky"      = configSimple
        | otherwise        = configFull

-----------------------------------------------------------------------------
--
--  ConfigSimple is a default configuration with a simple xmobar setup
--
--  Should run and be compatible with most situations and quick set ups
--
--

configSimple = do
  myStatusProc <- spawnPipe myStatusBar
  return $ myUrgencyHook $ ewmh aDefaultConfig
    { logHook = myXmobarLogHook myStatusProc
    }
    where
      myStatusBar="xmobar ~/.xmonad/etc/xmobar-simple"

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
    trayerW = 100
    trayerO = screenW - trayerW
    statusW = screenW * 0.6 - trayerW
    statusO = screenW - statusW - trayerW
    xmonadBarCmd = "dzen2 -xs 1 -bg '"++ Sol.base03 ++"' -ta l -w " ++ show xmonadW
    trayerBarCmd = "trayer --transparent true --tint 0x002b36 --alpha 0 --edge top --align left"
                   ++ " --widthtype pixel --width " ++ show trayerW
                   ++ " --margin " ++ show trayerO
                   ++ " --heighttype pixel --height 18"
    statusBarCmd = "conky -c ~/.xmonad/etc/conkyrc-mainbar-config-full "
                   ++ "| dzen2 -xs 1 -ta r -bg '" ++ Sol.base03 ++ "' -x " ++ show statusO ++ " -w " ++ show statusW
    configStartupHook = myStartupHook

  xmonadBar <- spawnPipe xmonadBarCmd
  spawn statusBarCmd
  spawn trayerBarCmd
  return $ myUrgencyHook $ ewmh aDefaultConfig
    { logHook = myDzenLogHook xmonadBar
    , manageHook = myManageHook
    , startupHook = configStartupHook
    } where
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

showWorkspaceName1 timeout bg = do
  ws <- gets (W.currentTag . windowset)
  return ws
   >>= \d-> DZ.dzenConfig
             (DZ.timeout timeout
              >=> DZ.onCurr (DZ.center 400 48)
              >=> DZ.font largeFont
              >=> DZ.addArgs ["-fg", Sol.base03]
              >=> DZ.addArgs ["-bg", bg]
             ) d

showWorkspaceName = showWorkspaceName1 2.5 Sol.yellow
showWorkspaceNameOld = showWorkspaceName1 2.5 Sol.base1
showWorkspaceNameFast = showWorkspaceName1 0.5 Sol.magenta
showWorkspaceNameOldFast = showWorkspaceName1 0.5 Sol.base1

showLayoutName = do
  winset <- gets windowset
  let ld = description . W.layout . W.workspace . W.current $ winset
  return ld
   >>= \d-> DZ.dzenConfig
             (DZ.timeout 0.8
              >=> DZ.onCurr (DZ.center 400 48)
              >=> DZ.font largeFont
              >=> DZ.addArgs ["-fg", Sol.base03]
              >=> DZ.addArgs ["-bg", Sol.green]
             ) d

-- Local Variables:
-- fill-column: 180
-- End:
