local TARGET_CHAR = nil
local QUEUED_ITEMS = {}
local TOOLTIP_FRAME
local TIMER_FRAME = CreateFrame("Frame")
local TIMER_COUNT = 0

local BLACKLIST_ITEMS = {
}

local function CreateTooltip()
  local tip, leftside = CreateFrame("GameTooltip"), {}
  for i = 1, 2 do
    local L, R = tip:CreateFontString(), tip:CreateFontString()
    L:SetFontObject(GameFontNormal)
    R:SetFontObject(GameFontNormal)
    tip:AddFontStrings(L, R)
    leftside[i] = L
  end
  tip.leftside = leftside
  TOOLTIP_FRAME = tip
  return tip
end

local function SendQueuedItems()

  if getn(QUEUED_ITEMS) == 0 then
    print("Done sending items")
    QUEUED_ITEMS = {}
    TARGET_CHAR = nil
    return
  end

  local maxItems = 12
  if getn(QUEUED_ITEMS) < 12 then
    maxItems = getn(QUEUED_ITEMS)
  end

  for i = 1, maxItems do

    local item = table.remove(QUEUED_ITEMS, 1)
    PickupContainerItem(item.bagId, item.slotId)
    ClickSendMailItemButton()

  end

  print("Sending batch to " .. TARGET_CHAR)
  SendMail(TARGET_CHAR, "Inventory dump", "")

  TIMER_COUNT = 0
  TIMER_FRAME:SetScript("OnUpdate", function(self, elapsed)
    TIMER_COUNT = TIMER_COUNT + elapsed
    if TIMER_COUNT > 1 then
      TIMER_FRAME:SetScript("OnUpdate", nil)
      TIMER_COUNT = 0
      SendQueuedItems()
    end
  end)

end

local function IsItemSoulbound(bagId, slotId)
  local tooltip = TOOLTIP_FRAME or CreateTooltip()
  tooltip:SetOwner(UIParent, "ANCHOR_NONE")
  tooltip:ClearLines()
  tooltip:SetBagItem(bagId, slotId)
  local t = tooltip.leftside[2]:GetText()
  tooltip:Hide()
  return (t == ITEM_SOULBOUND)
end

local function ItemMatchesFilter(link, filter)

  if filter == "" then return true end
  local name = GetItemInfo(link)
  if string.find(string.lower(name), string.lower(filter)) ~= nil then return true else return false end

end

local function DumpInventoryToCharacter(character, filter)

  QUEUED_ITEMS = {}
  TARGET_CHAR = character

  for bagId=0, 4 do
    for slotId = 1, GetContainerNumSlots(bagId) do

      local link = GetContainerItemLink(bagId, slotId)
      if link ~= nil then
        local _, _, quality = GetItemInfo(link)
        if quality >= 1 and not IsItemSoulbound(bagId, slotId) and ItemMatchesFilter(link, filter) then
          table.insert(QUEUED_ITEMS, { ["bagId"] = bagId, ["slotId"] = slotId })
        end
      end

    end
  end
  
  MailFrameTab2:Click()
  SendQueuedItems()
  
end

AhGoblin.DumpInventory = function(params)

  if not AhGoblin.MailboxOpen then
    print("Mailbox must be open to use this command")
    return
  end

  local char, filter = params:match('^(%S*)%s*(.-)$');
  DumpInventoryToCharacter(char, filter)

end
