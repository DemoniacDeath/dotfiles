import XMonad

import XMonad.StackSet as W

import XMonad.Config.Desktop

import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.ManageDocks

import XMonad.Util.EZConfig
import XMonad.Util.NamedScratchpad
import XMonad.Util.Run(spawnPipe, hPutStrLn)

import System.Exit
import qualified Data.Map as M

main = do
       xmproc <- spawnPipe ("xmobar")
       xmonad $ docks desktopConfig
         { terminal          = "uxterm"
         , borderWidth       = 0
         , clickJustFocuses  = False
         , focusFollowsMouse = False
         , modMask           = mod4Mask
         , layoutHook        = avoidStruts $ layoutHook desktopConfig
         , manageHook        = myManageHook
         , keys              = myKeys
         , logHook           = dynamicLogWithPP $ xmobarPP {
             ppOutput  = hPutStrLn xmproc
           , ppTitle   = xmobarColor xmobarTitleColor "" . shorten 100
           , ppCurrent = xmobarColor xmobarCurrentWorkspaceColor ""
           , ppSep     = "   "
         }
         } `additionalKeys`
         [ ((shiftMask, xK_Print), spawn "screenshot -s /home/demoniac/Pictures/Screenshots/")
         , ((0, xK_Print), spawn "screenshot /home/demoniac/Pictures/Screenshots/")
         , ((controlMask, xK_F12), namedScratchpadAction scratchpads "uxterm")
         ]

-- Color of current window title in xmobar.
xmobarTitleColor = "#FFB6B0"

-- Color of current workspace in xmobar.
xmobarCurrentWorkspaceColor = "#CEFFAC"

scratchpads = [ NS "uxterm" "uxterm" (className =? "xterm") $ customFloating $ W.RationalRect 0 0 0 0
              ]

myManageHook = (isFullscreen --> doFullFloat) 
               <+> namedScratchpadManageHook scratchpads
               <+> manageHook desktopConfig

myKeys conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $
    -- launching and killing programs
    [ ((modMask,               xK_Return), spawn $ XMonad.terminal conf)
    , ((modMask,               xK_r     ), spawn "j4-dmenu-desktop")
    , ((modMask .|. shiftMask, xK_q     ), kill)
    , ((modMask,               xK_Tab   ), spawn "rofi -combi-modi window -theme solarized -font \"hack 10\" -show combi")
    , ((modMask,               xK_l     ), spawn "i3lock")

    -- quit, or restart
    , ((modMask .|. shiftMask, xK_e     ), io (exitWith ExitSuccess))
    , ((modMask .|. shiftMask, xK_r     ), spawn "if type xmonad; then xmonad --recompile && xmonad --restart; else xmessage xmonad not in \\$PATH: \"$PATH\"; fi") -- %! Restart xmonad
    ]
    ++
    -- mod-[1..9] %! Switch to workspace N
    -- mod-shift-[1..9] %! Move client to workspace N
    [((m .|. modMask, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
