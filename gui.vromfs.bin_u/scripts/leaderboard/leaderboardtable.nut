from "%scripts/dagui_library.nut" import *

//checked for explicitness
#no-root-fallback
#explicit-this

let platformModule = require("%scripts/clientState/platform.nut")
let { handlerType } = require("%sqDagui/framework/handlerType.nut")

::gui_handlers.LeaderboardTable <- class extends ::gui_handlers.BaseGuiHandlerWT {
  wndType = handlerType.CUSTOM
  sceneBlkName = null
  sceneTplName = "%gui/leaderboard/leaderboardTable.tpl"

  isLastPage = false
  lbParams   = null
  lbModel    = null
  lbPresets  = null
  lbCategory = null
  isClanLb   = false
  rowsInPage = 0

  lastHoveredDataIdx = -1

  onCategoryCb = null
  onRowSelectCb = null
  onRowHoverCb = null
  onRowDblClickCb = null
  onRowRClickCb = null

  static function create(config)
  {
    return ::handlersManager.loadHandler(::gui_handlers.LeaderboardTable, config)
  }

  function getSceneTplView()
  {
    return {}
  }

  function updateParams(curModel, curPresets, curCategory, curParams, isCurClanLb = false)
  {
    this.lbModel = curModel
    this.lbPresets = curPresets
    this.lbCategory = curCategory
    this.lbParams = curParams
    this.isClanLb = isCurClanLb
  }

  function showLoadingAnimation()
  {
    this.showSceneBtn("wait_animation", true)
    this.showSceneBtn("no_leaderboads_text", false)
    this.showSceneBtn("lb_table", false)
  }

  function fillTable(lbRows, selfRow, selfPos, hasHeader, hasTable)
  {
    local data = ""
    if (hasHeader)
    {
      let headerRow = [
        { text = "#multiplayer/place", width = "0.1@sf" },
        { text = this.isClanLb ? "#clan/clan_name" : "#multiplayer/name",
          tdalign = "center", width = this.isClanLb ? 0 : "0.12@sf" }
      ]
      foreach(category in this.lbPresets)
      {
        if (!this.lbModel.checkLbRowVisibility(category, this.lbParams))
          continue

        let block = {
          id = category.id
          image = category.headerImage
          tooltip = category.headerTooltip
          needText = false
          active = this.lbCategory == category
          callback = "onCategory"
        }
        headerRow.append(block)
      }
      data += ::buildTableRow("row_header", headerRow, null, "isLeaderBoardHeader:t='yes'")
    }

    this.isLastPage = false
    if (hasTable)
    {
      local rowIdx = 0
      foreach(row in lbRows)
        data += this.getTableRowMarkup(row, rowIdx++, selfPos)

      if (rowIdx < this.rowsInPage)
      {
        for(local i = rowIdx; i < this.rowsInPage; i++)
          data += ::buildTableRow("row_" + i, [], i % 2 == 0, "inactive:t='yes';")
        this.isLastPage = true
      }

      data += this.generateSelfRow(selfRow)
    }

    let lbTable = this.scene.findObject("lb_table")
    this.guiScene.replaceContentFromText(lbTable, data, data.len(), this)

    if (hasTable)
      this.onRowSelect(lbTable)

    this.showSceneBtn("wait_animation", !hasHeader && !hasTable)
    this.showSceneBtn("no_leaderboads_text", hasHeader && !hasTable)
    this.showSceneBtn("lb_table", hasHeader && hasTable)
  }

  function getTableRowMarkup(row, rowIdx, selfPos)
  {
    let needAddClanTag = row?.needAddClanTag ?? false
    let clanTag = row?.clanTag ?? ""
    let playerName = platformModule.getPlayerName(row?.name ?? "")
    let rowData = [
      {
        text = row.pos >= 0 ? (row.pos + 1).tostring() : loc("leaderboards/notAvailable")
      }
      {
        id = "name"
        tdalign = "left"
        text = needAddClanTag
          ? ::g_contacts.getPlayerFullName(playerName, clanTag)
          : playerName
      }
    ]
    foreach(category in this.lbPresets)
    {
      if (!this.lbModel.checkLbRowVisibility(category, this.lbParams))
        continue

      rowData.append(this.getItemCell(category, row))
    }
    let clanId = needAddClanTag && clanTag == "" ? (row?.clanId ?? "") : ""
    let highlightRow = selfPos == row.pos && row.pos >= 0
    let rowParamsText = $"clanId:t='{clanId}';{highlightRow ? "mainPlayer:t='yes';" : ""}"
    let data = ::buildTableRow("row_" + rowIdx, rowData, rowIdx % 2 == 0, rowParamsText)

    return data
  }

  function getItemCell(curLbCategory, row)
  {
    let value = curLbCategory.field in row ? row[curLbCategory.field] : 0
    let res = curLbCategory.getItemCell(value, row)
    res.active <- this.lbCategory == curLbCategory

    return res
  }

  function generateSelfRow(selfRow)
  {
    if (!selfRow || selfRow.len() <= 0)
      return ""

    let emptyRow = ::buildTableRow("row_"+this.rowsInPage, ["..."], null,
      "inactive:t='yes'; commonTextColor:t='yes'; style:t='height:0.7@leaderboardTrHeight;'; ")

    return emptyRow + this.generateRowTableData(selfRow[0], this.rowsInPage + 1, selfRow)
  }

  function generateRowTableData(row, rowIdx, selfRow)
  {
    let rowName = "row_" + rowIdx
    let needAddClanTag = row?.needAddClanTag ?? false
    let clanTag = row?.clanTag ?? ""
    let playerName = platformModule.getPlayerName(row?.name ?? "")
    let rowData = [
      {
        text = row.pos >= 0 ? (row.pos + 1).tostring() : loc("leaderboards/notAvailable")
      },
      {
        id = "name"
        tdalign = "left"
        text = needAddClanTag
          ? ::g_contacts.getPlayerFullName(playerName, clanTag)
          : playerName
      }
    ]
    foreach(category in this.lbPresets)
    {
      if (!this.lbModel.checkLbRowVisibility(category, this.lbParams))
        continue

      rowData.append(this.getItemCell(category, row))
    }

    let clanId = needAddClanTag && clanTag == "" ? (row?.clanId ?? "") : ""
    let highlightRow = selfRow == row.pos && row.pos >= 0
    let data = ::buildTableRow(rowName, rowData, rowIdx % 2 == 0,
      $"clanId:t='{clanId}';{highlightRow ? "mainPlayer:t='yes';" : ""}")

    return data
  }

  function onRowSelect(obj)
  {
    if (::show_console_buttons)
      return
    if (!checkObj(obj))
      return

    let dataIdx = obj.getValue() - 1 // skiping header row
    this.onRowSelectCb?(dataIdx)
  }

  function onRowHover(obj)
  {
    if (!::show_console_buttons)
      return
    if (!checkObj(obj))
      return

    let isHover = obj.isHovered()
    let dataIdx = ::to_integer_safe(::g_string.cutPrefix(obj.id, "row_", ""), -1, false)
    if (isHover == (dataIdx == this.lastHoveredDataIdx))
     return

    this.lastHoveredDataIdx = isHover ? dataIdx : -1
    this.onRowHoverCb?(this.lastHoveredDataIdx)
  }

  function onRowDblClick()
  {
    if (this.onRowDblClickCb)
      this.onRowDblClickCb()
  }

  function onRowRClick()
  {
    if (this.onRowRClickCb)
      this.onRowRClickCb()
  }

  function onCategory(obj)
  {
    if (this.onCategoryCb)
      this.onCategoryCb(obj)
  }
}
