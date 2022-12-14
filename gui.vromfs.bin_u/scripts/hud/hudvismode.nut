from "%scripts/dagui_library.nut" import *

//checked for explicitness
#no-root-fallback
#explicit-this

let enums = require("%sqStdLibs/helpers/enums.nut")
let { subscribe, send } = require("eventbus")
global enum HUD_VIS_PART //bit enum
{
  DMG_PANEL           = 0x0001
  MAP                 = 0x0002
  CAPTURE_ZONE_INFO   = 0x0004
  KILLLOG             = 0x0008
  CHAT                = 0x0010
  KILLCAMERA          = 0x0020
  STREAKS             = 0x0040
  REWARDS_MSG         = 0x0080
  ORDERS              = 0x0100
  RACE_INFO           = 0x0200

  //masks
  ALL                 = 0xFFFF
  NONE                = 0x0000
}

::g_hud_vis_mode <- {
  types = []

  cache = { byHudGm = {} }
}

::g_hud_vis_mode.template <- {
  hudGm = HUD_GAME_MODE_DEFAULT
  locId = ""
  parts = HUD_VIS_PART.NONE

  getName = function() { return loc(this.locId) }
  isAvailable = function(_diffCode) { return true }
  isPartVisible = function(part) { return (this.parts & part) != 0}
}

enums.addTypesByGlobalName("g_hud_vis_mode", {
  DEFAULT = {
    hudGm = HUD_GAME_MODE_DEFAULT
    locId = "options/hudDefault"
  }

  FULL = {
    hudGm = HUD_GAME_MODE_FULL
    locId = "options/hudFull"
    parts = HUD_VIS_PART.ALL
    isAvailable = function(diffCode) { return diffCode == DIFFICULTY_ARCADE || diffCode == DIFFICULTY_REALISTIC }
  }

  MINIMAL = {
    hudGm = HUD_GAME_MODE_MINIMAL
    locId = "options/hudNecessary"
    parts = HUD_VIS_PART.DMG_PANEL | HUD_VIS_PART.MAP | HUD_VIS_PART.CAPTURE_ZONE_INFO
            | HUD_VIS_PART.CHAT | HUD_VIS_PART.KILLCAMERA | HUD_VIS_PART.KILLLOG | HUD_VIS_PART.RACE_INFO
  }

  DISABLED = {
    hudGm = HUD_GAME_MODE_DISABLED
    locId = "options/hudMinimal"
    parts = HUD_VIS_PART.NONE
  }
})

::g_hud_vis_mode.types.sort(function(a,b)
{
  return a.hudGm > b.hudGm ? 1 : (a.hudGm < b.hudGm ? -1 : 0)
})

::g_hud_vis_mode.getModeByHudGm <- function getModeByHudGm(hudGm, defValue = ::g_hud_vis_mode.DEFAULT)
{
  return enums.getCachedType("hudGm", hudGm, ::g_hud_vis_mode.cache.byHudGm,
    ::g_hud_vis_mode, defValue)
}

::g_hud_vis_mode.getCurMode <- function getCurMode()
{
  return this.getModeByHudGm(::get_hud_game_mode(), ::g_hud_vis_mode.FULL)
}

subscribe("updateHudPartVisible", function(_) {
  if (!::is_in_flight()) {
    send("updateExtWatched", { isChatPlaceVisible = false, isOrderStatusVisible = false })
    return
  }

  let curMode = ::g_hud_vis_mode.getCurMode()
  send("updateExtWatched", {
    isChatPlaceVisible = curMode.isPartVisible(HUD_VIS_PART.CHAT)
    isOrderStatusVisible = curMode.isPartVisible(HUD_VIS_PART.ORDERS)
  })
})
