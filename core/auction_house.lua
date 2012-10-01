-- Add event hook to the auction house show-event.
local ahOpenFrame = CreateFrame('FRAME')
ahOpenFrame:RegisterEvent('AUCTION_HOUSE_SHOW')
ahOpenFrame:SetScript('OnEvent', function()
  AhGoblin.AuctionHouseOpen = true
end)

-- Add event hook to the auction house closed-event.
local ahOpenFrame = CreateFrame('FRAME')
ahOpenFrame:RegisterEvent('AUCTION_HOUSE_CLOSED')
ahOpenFrame:SetScript('OnEvent', function()
  AhGoblin.AuctionHouseOpen = false
end)
