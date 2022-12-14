from "%scripts/dagui_library.nut" import *

//checked for explicitness
#no-root-fallback
#explicit-this

let time = require("%scripts/time.nut")
let { get_time_msec } = require("dagor.time")
let { PERSISTENT_DATA_PARAMS } = require("%sqStdLibs/scriptReloader/scriptReloader.nut")


::g_partner_unlocks <- {
  [PERSISTENT_DATA_PARAMS] = ["partnerExectutedUnlocks", "lastUpdateTime", "lastRequestTime"]

  REQUEST_TIMEOUT_MSEC = 45000
  UPDATE_TIMEOUT_MSEC = 60000

  lastRequestTime = -9999999999
  lastUpdateTime = -9999999999
  partnerExectutedUnlocks = {}
}

::g_partner_unlocks.requestPartnerUnlocks <- function requestPartnerUnlocks()
{
  if (!this.canRefreshData())
    return

  this.lastRequestTime = get_time_msec()
  let successCb = function(result)
  {
    ::g_partner_unlocks.lastUpdateTime = get_time_msec()
    if (!::g_partner_unlocks.applyNewPartnerUnlockData(result))
      return

    ::broadcastEvent("PartnerUnlocksUpdated")
  }

  let requestBlk = ::DataBlock()
  ::g_tasker.charRequestBlk("cln_get_partner_executed_unlocks",
                            requestBlk,
                            { showErrorMessageBox = false },
                            successCb)
}

::g_partner_unlocks.canRefreshData <- function canRefreshData()
{
  if (this.lastRequestTime > this.lastUpdateTime && this.lastRequestTime + this.REQUEST_TIMEOUT_MSEC > get_time_msec())
    return false
  if (this.lastUpdateTime + this.UPDATE_TIMEOUT_MSEC > get_time_msec())
    return false

  return true
}

::g_partner_unlocks.getPartnerUnlockTime <- function getPartnerUnlockTime(unlockId)
{
  if (::u.isEmpty(unlockId))
    return null

  if (!(unlockId in this.partnerExectutedUnlocks))
  {
    if (::is_unlocked_scripted(-1, unlockId))
      this.requestPartnerUnlocks()
    return null
  }

  return this.partnerExectutedUnlocks[unlockId]
}

::g_partner_unlocks.applyNewPartnerUnlockData <- function applyNewPartnerUnlockData(result)
{
  if (!::u.isDataBlock(result))
    return false

  let newPartnerUnlocks = ::buildTableFromBlk(result)
  if (::u.isEqual(this.partnerExectutedUnlocks, newPartnerUnlocks))
    return false

  this.partnerExectutedUnlocks = newPartnerUnlocks
  return true
}

::g_partner_unlocks.isPartnerUnlockAvailable <- function isPartnerUnlockAvailable(unlockId, durationMin = null)
{
  if (!unlockId)
    return true
  let startSec = this.getPartnerUnlockTime(unlockId)
  if (!startSec)
    return false
  if (!durationMin)
    return true
  if (!::is_numeric(durationMin))
    return false

  let durationSec = time.minutesToSeconds(durationMin)
  let endSec = startSec + durationSec
  return endSec > ::get_charserver_time_sec()
}

::g_partner_unlocks.onEventSignOut <- function onEventSignOut(_p)
{
  this.lastRequestTime = -9999999999
  this.lastUpdateTime = -9999999999
  this.partnerExectutedUnlocks = {}
}

::g_script_reloader.registerPersistentDataFromRoot("g_partner_unlocks")
::subscribe_handler(::g_partner_unlocks, ::g_listener_priority.CONFIG_VALIDATION)