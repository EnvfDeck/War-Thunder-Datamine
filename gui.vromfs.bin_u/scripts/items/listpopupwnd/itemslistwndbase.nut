from "%scripts/dagui_library.nut" import *

//checked for explicitness
#no-root-fallback
#explicit-this

let stdMath = require("%sqstd/math.nut")
let { handlerType } = require("%sqDagui/framework/handlerType.nut")

::gui_handlers.ItemsListWndBase <- class extends ::gui_handlers.BaseGuiHandlerWT {
  wndType = handlerType.MODAL
  sceneTplName = "%gui/items/universalSpareApplyWnd.tpl"

  itemsList = null
  alignObj = null
  align = ALIGN.BOTTOM

  curItem = null

  function getSceneTplView()
  {
    return {
      items = ::handyman.renderCached("%gui/items/item.tpl", { items = ::u.map(this.itemsList, @(i) i.getViewData()) })
      columns = stdMath.calc_golden_ratio_columns(this.itemsList.len())

      align = this.align
      position = "50%pw-50%w, 50%ph-50%h"
      hasPopupMenuArrow = checkObj(this.alignObj)
    }
  }

  function initScreen()
  {
    this.setCurItem(this.itemsList[0])
    this.updateWndAlign()
    this.guiScene.performDelayed(this, @() this.guiScene.performDelayed(this, function() {
      if (this.scene.isValid())
        ::move_mouse_on_child_by_value(this.scene.findObject("items_list"))
    }))
  }

  function updateWndAlign()
  {
    if (checkObj(this.alignObj))
      this.align = ::g_dagui_utils.setPopupMenuPosAndAlign(this.alignObj, this.align, this.scene.findObject("frame_obj"))
  }

  function setCurItem(item)
  {
    this.curItem = item
    this.scene.findObject("header_text").setValue(this.curItem.getName())
  }

  function onItemSelect(obj)
  {
    let value = obj.getValue()
    if (value in this.itemsList)
      this.setCurItem(this.itemsList[value])
  }

  function onActivate() {}
  function onButtonMax() {}

  function afterModalDestroy() {
    ::move_mouse_on_obj(this.alignObj)
  }
}
