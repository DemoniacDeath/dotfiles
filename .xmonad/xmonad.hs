import XMonad hiding ( (|||) )

import XMonad.StackSet as W

import XMonad.Config.Desktop

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ServerMode

import XMonad.Layout.MultiToggle
import XMonad.Layout.MultiToggle.Instances
import XMonad.Layout.WindowNavigation
import XMonad.Layout.Tabbed
import XMonad.Layout.Accordion
import XMonad.Layout.LayoutCombinators

import XMonad.Util.EZConfig
import XMonad.Util.NamedScratchpad
import XMonad.Util.Run(spawnPipe, hPutStrLn)

import XMonad.Actions.CycleWS
import XMonad.Actions.Commands

import System.Exit
import Graphics.X11.ExtraTypes.XF86
import Data.Map ((!))
import Data.List (intercalate)
import qualified Data.Map as M
import qualified DBus as D
import qualified DBus.Client as D
import qualified Codec.Binary.UTF8.String as UTF8

main = do
       xmproc <- spawnPipe "xmobar"
       dbus <- D.connectSession
       D.requestName dbus (D.busName_ "org.xmonad.Log")
         [D.nameAllowReplacement, D.nameReplaceExisting, D.nameDoNotQueue]
       xmonad $ docks desktopConfig
         { terminal          = "uxterm"
         , borderWidth       = 0
         , clickJustFocuses  = False
         , focusFollowsMouse = False
         , modMask           = mod4Mask
         , layoutHook        = myLayout
         , manageHook        = myManageHook
         , handleEventHook   = myEventHook
         , keys              = myKeys
         , logHook           = dynamicLogWithPP (
                                                  myLogHook (hPutStrLn xmproc) 
                                                  (\id -> xmobarAction ("xmonadctl view\\\"" ++ id ++ "\\\"") "1" id)
                                                  (\color -> xmobarColor color "")
                                                )

           } `additionalKeys`
         [ ((shiftMask, xK_Print), spawn "screenshot -s /home/demoniac/Pictures/Screenshots/")
         , ((0, xK_Print), spawn "screenshot /home/demoniac/Pictures/Screenshots/")
         , ((controlMask, xK_F12), namedScratchpadAction scratchpads "uxterm")

    -- music controls
         , ((mod1Mask .|. shiftMask .|. controlMask, xK_F10), spawn $ musicCommands ! "Previous")
         , ((mod1Mask .|. shiftMask .|. controlMask, xK_F11), spawn $ musicCommands ! "PlayPause")
         , ((mod1Mask .|. shiftMask .|. controlMask, xK_F12), spawn $ musicCommands ! "Next")
         , ((0, xF86XK_AudioPlay), spawn $ musicCommands ! "PlayPause")
         , ((0, xF86XK_AudioPrev), spawn $ musicCommands ! "Previous")
         , ((0, xF86XK_AudioNext), spawn $ musicCommands ! "Next")
         , ((0, xF86XK_AudioLowerVolume), spawn "amixer -D pulse sset Master 5%-")
         , ((0, xF86XK_AudioRaiseVolume), spawn "amixer -D pulse sset Master 5%+")
         , ((0, xF86XK_AudioMute), spawn "amixer -D pulse sset Master -- toggle")
           ]
           where 
             -- list of possible commands that can be sent to a music application via DBus
             musicCommandTypes = ["Previous", "PlayPause", "Next"]
             -- list of music applications that listen to DBus messages
             musicApplications = ["clementine", "spotify", "cmus"]
             -- template for DBus message sending command
             musicDbusMessage ap op = "dbus-send --print-reply --dest=org.mpris.MediaPlayer2." ++ ap ++ " /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player." ++ op
             -- command list combining function
             combineCommands = Data.List.intercalate ";"
             -- builds a combination of commands with the same type but for all possible applications
             musicCommandBuilder aps op = combineCommands $ ($ op) <$> musicDbusMessage <$> aps
             -- map of music commands
             musicCommands = M.fromList [ (t, musicCommandBuilder musicApplications t) | t <- musicCommandTypes]

-- Color of current workspace in bar.
barCurrentWorkspaceColor = "#CEFFAC"

-- Color of not-current workspace in bar.
barOtherWorkspaceColor = "#DDD"

scratchpads = [ NS "uxterm" "uxterm -name tildaterm -e 'tmux new -A -s main'" (resource =? "tildaterm") $ customFloating $ W.RationalRect 0 0 1 1
                ]

myManageHook = (isFullscreen --> doFullFloat) 
               <+> namedScratchpadManageHook scratchpads
               <+> manageHook desktopConfig

myTabConfig = def { fontName = "xft:Fira Code Retina:size=11:antialias=true"
                    }

myEventHook = serverModeEventHookCmd

myLayout = avoidStruts 
         $ windowNavigation 
         $ mkToggle (single FULL)
         $ layouts
         where
              layouts = wide ||| Mirror wide ||| Accordion ||| tab
              tab     = tabbed shrinkText myTabConfig
              wide    = Mirror $ Tall nmaster delta ratio
              nmaster = 3
              delta   = 3/100
              ratio   = 1/2
--myRunner = "j4-dmenu-desktop"
myRunner = "j4-dmenu-desktop --dmenu='rofi -dmenu -i' --no-generic --display-binary"

myKeys conf@(XConfig {XMonad.modMask = modm}) = M.fromList $
    -- launching and killing programs
    [ ((modm,               xK_Return   ), spawn $ XMonad.terminal conf)
    , ((modm,               xK_r        ), spawn myRunner)
    , ((modm .|. shiftMask, xK_q        ), kill)
    , ((modm,               xK_l        ), spawn "slock")

    -- layout
    , ((modm,               xK_f        ), (sendMessage $ Toggle FULL) <+> (sendMessage ToggleStruts))
    , ((modm .|. shiftMask, xK_f        ), toggleFloat)

    , ((modm,               xK_Up       ), windows W.focusUp)
    , ((modm,               xK_Down     ), windows W.focusDown)
    , ((modm,               xK_Page_Up  ), windows W.focusUp)
    , ((modm,               xK_Page_Down), windows W.focusDown)
    , ((modm,               xK_s        ), sendMessage $ JumpToLayout "Accordion")
    , ((modm,               xK_w        ), sendMessage $ JumpToLayout "Tabbed Simplest")
    , ((modm,               xK_e        ), sendMessage $ JumpToLayout "Mirror Tall")

    -- navigation
    , ((modm,               xK_Right    ), nextWS)
    , ((modm,               xK_Left     ), prevWS)
    , ((modm .|. shiftMask, xK_Right    ), shiftToNext)
    , ((modm .|. shiftMask, xK_Left     ), shiftToPrev)

    -- quit, or restart
    , ((modm .|. shiftMask, xK_e        ), io (exitWith ExitSuccess))
    , ((modm .|. shiftMask, xK_r        ), spawn "if type xmonad; then xmonad --recompile && pkill xmobar ; xmonad --restart; else xmessage xmonad not in \\$PATH: \"$PATH\"; fi") -- %! Restart xmonad

    -- debug
    , ((modm,               xK_x        ), spawn "xprop | xclip -selection clipboard -i")
    , ((modm .|. mod1Mask,  xK_r        ), defaultCommands >>= runCommand)
    ]
    ++
    -- mod-[1..9] %! Switch to workspace N
    -- mod-shift-[1..9] %! Move client to workspace N
    [((m .|. modm, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
    where 
      -- If the window is floating then (f), if tiled then (n)
      floatOrNot f n = withFocused $ \windowId -> do
          floats <- gets (W.floating . windowset)
          if windowId `M.member` floats -- if the current window is floating...
             then f
             else n
      
      -- Centre and float a window (retain size)
      centreFloat win = do
          (_, W.RationalRect x y w h) <- floatLocation win
          windows $ W.float win (W.RationalRect ((1 - w) / 2) ((1 - h) / 2) w h)
          return ()
      
      -- Float and centre a tiled window, sink a floating window
      toggleFloat = floatOrNot (withFocused $ windows . W.sink) (withFocused centreFloat)

myLogHook output clickable fgColor = def {
    ppOutput  = output
  , ppLayout  = \_ -> ""
  , ppTitle   = \_ -> ""
  , ppCurrent = (fgColor barCurrentWorkspaceColor) . (wrap "[" "]") . clickable
  , ppVisible = (fgColor barOtherWorkspaceColor) . (wrap "<" ">") . clickable . ignoreNSP
  , ppHidden  = (fgColor barOtherWorkspaceColor) . clickable . ignoreNSP
  , ppSep     = " | "
  }
  where
    ignoreNSP id
      | id == "NSP" = ""
      | otherwise   = id

dbusOutput :: D.Client -> String -> IO ()
dbusOutput dbus str = do
    let signal = (D.signal objectPath interfaceName memberName) {
        D.signalBody = [D.toVariant $ UTF8.decodeString str]
      }
    D.emit dbus signal
  where
    objectPath = D.objectPath_ "/org/xmonad/Log"
    interfaceName = D.interfaceName_ "org.xmonad.Log"
    memberName = D.memberName_ "Update"
