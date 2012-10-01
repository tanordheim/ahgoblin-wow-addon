local AceGUI = LibStub('AceGUI-3.0')
local TSMCrafting = LibStub('AceAddon-3.0'):GetAddon('TradeSkillMaster_Crafting')
local TSMEnchanting = TSMCrafting:GetModule("Enchanting")

local function TradeSkillFrameIsOpen()
  if _G["TradeSkillFrame"] ~= nil and _G["TradeSkillFrame"]:IsVisible() then return true else return false end
end

local function GetIdFromLink(link)
  if not link then return end
  local id = string.match(link, "item:([%-%d]+)") or string.match(link, "enchant:([%-%d]+)") or string.match(link, "spell:([%-%d]+)")
  return tonumber(id)
end

-- Initial point of entry for exporting profession data. It will scan the list
-- of tradeskills in the open tradeskill window, optionally filter it by a user
-- provided filter, and then present a window to the user containing the encoded
-- data that can be imported in the AhGoblin web application.
AhGoblin.ExportData = function(filter)
  if TradeSkillFrameIsOpen() then

    if filter == nil then filter = "" end
    print("AhGoblin: Exporting tradeskill recipes, filter=" .. filter)

    local exportData = {}

    for tradeSkillIndex = 1, GetNumTradeSkills() do
      local skillName, skillType = GetTradeSkillInfo(tradeSkillIndex)
      if skillType ~= "header" then
        if filter == "" or string.match(skillName:upper(), filter:upper()) then

          local tradeSkillLink = GetTradeSkillItemLink(tradeSkillIndex)
          local tradeSkillRecipeLink = GetTradeSkillRecipeLink(tradeSkillIndex)
          local tradeSkillItemId = GetIdFromLink(tradeSkillLink)
          local minYielded, maxYielded = GetTradeSkillNumMade(tradeSkillIndex)
          local reagentData = {}

          -- If the item ID found is in the TSM_Crafting Enchanting module item
          -- ID table, then the tradeskill is an enchant returning a spell ID.
          -- Map this to the item yielded when enchanting on a scroll instead,
          -- and add a vellum to the list.
          if TSMEnchanting.itemID[tradeSkillItemId] then
            tradeSkillItemId = TSMEnchanting.itemID[tradeSkillItemId]
            table.insert(reagentData, "1," .. TSMEnchanting.vellumID)
          end

          for reagentIndex = 1, GetTradeSkillNumReagents(tradeSkillIndex) do

            local reagentName, _, reagentCount = GetTradeSkillReagentInfo(tradeSkillIndex, reagentIndex)
            local reagentLink = GetTradeSkillReagentItemLink(tradeSkillIndex, reagentIndex)
            local reagentItemId = GetIdFromLink(reagentLink)

            if (reagentItemId == nil) then
              print("reagentItemId is nil from " .. reagentLink)
            end

            table.insert(reagentData, reagentCount .. "," .. reagentItemId)

          end

          -- Append a line to the export data for this trade skill.
          local exportLine = { tradeSkillItemId, minYielded, maxYielded, table.concat(reagentData, ":") }
          table.insert(exportData, table.concat(exportLine, "|"))

        end
      end
    end

    -- Create the main window.
    local f = AceGUI:Create("Frame")
    f:SetCallback('OnClose', function(self) AceGUI:Release(self) end)
    f:SetTitle("AhGoblin Export")
    f:SetLayout("flow")
    f:SetHeight(600)

    -- Create the large edit box where import data will be pasted.
    local eb = AceGUI:Create("MultiLineEditBox")
    eb:SetLabel("Paste data into the craft import in AhGoblin")
    eb:SetFullWidth(true)
    eb:SetFullHeight(true)
    eb:SetMaxLetters(0)
    eb:SetText(table.concat(exportData, "\n"))
    f:AddChild(eb)

    -- Set some frame parameters.
    f.frame:SetFrameStrata('FULLSCREEN_DIALOG')
    f.frame:SetFrameLevel(100)
    
  else
    print("AhGoblin: The tradeskill frame must be open before profession data is exported")
  end
end
