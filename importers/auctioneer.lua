-- Register the importer.
AhGoblin.RegisterImportModule('auctioneer')

-- Set the name of the current snatch list.
local function SetSnatchListName(name)

  -- Change the value of the search ui save name-box.
  local editbox = SearchUiSaveName
  editbox:SetText(name)
  
end

-- Set the current snatch list in the Auctioneer UI.
local function SetCurrentSnatchList(name)

  -- Set the name of the snatch list to load.
  SetSnatchListName(name)

  -- Load the current search.
  AucSearchUI.LoadSearch()

end

-- Delete the currently selected snatch list in the Auctioneer UI.
local function DeleteCurrentSnatchList(name)

  -- Set the current snatch search.
  SetCurrentSnatchList(name)

  -- Delete the current search.
  AucSearchUI.DeleteSearch()

end

-- Save the currently selected snatch list in the Auctioneer UI.
local function SaveCurrentSnatchList(name)

  -- Set the name of the snatch list.
  SetSnatchListName(name)

  -- Disallow bids for this list.
  AucAdvancedData.UtilSearchUiData.Current['snatch.allow.bid'] = false

  -- Save the search.
  AucSearchUI.SaveSearch()

end

-- Add a new snatch list.
local function AddNewSnatchList()

  -- Reset the searcher settings.
  AucSearchUI.ResetSearch()
  
end

-- Add an item to the current snatch list.
local function AddSnatchListItem(itemId, price)

  local snatch = AucSearchUI.Searchers['Snatch']

  -- Find the item name and item link from the item id.
  local itemName, itemLink = GetItemInfo(itemId)
  if itemName == nil then

    -- The item was not in cache. Wait for the GET_ITEM_INFO_RECEIVED callback
    -- and then add the item when we receive that.
    f = CreateFrame('Frame')
    f:RegisterEvent('GET_ITEM_INFO_RECEIVED')
    f:SetScript('OnEvent', function(...)

      local itemName, itemLink = GetItemInfo(itemId)

      -- Add the item to the snatch list.
      snatch.AddSnatch(itemLink, price)
      
    end)

  else

    -- Add the item to the snatch list.
    snatch.AddSnatch(itemLink, price)

  end

end

-- Remove all snatch lists currently defined in Auctioneer.
local function RemoveCurrentSnatchLists()
  for name, _ in pairs(AucAdvancedData.UtilSearchUiData.SavedSearches) do
    if name:match('^Snatch: ') then

      DeleteCurrentSnatchList(name)

    end
  end
end

-- Define the import function.
AhGoblin.ImportModules.auctioneer.import = function(data)

  if AhGoblin.AuctionHouseOpen then

    -- Remove all saved searches currently defined in Auctioneer.
    print('AhGoblin/AuctioneerImport: Removing all predefined searches in Auctioneer.')
    RemoveCurrentSnatchLists()

    -- Parse the imported data.
    dataSet = AhGoblin.ParseImportData(data, '1.0.0')
    if getn(dataSet) > 0 then

      for _, snatchData in ipairs(dataSet) do

        local listName = table.remove(snatchData, 1)
        print('AhGoblin/AuctioneerImport: Importing snatch list ' .. listName .. ' with ' .. getn(snatchData) .. ' items')

        -- Add a new snatch list.
        AddNewSnatchList()

        for _, snatchItem in ipairs(snatchData) do

          local item = AhGoblin.SplitString(snatchItem, ';')
          local itemId = item[1]
          local price = item[2]
          AddSnatchListItem(itemId, price)

        end

        -- Save the snatch list.
        SaveCurrentSnatchList('Snatch: ' .. listName)

      end

    end

    print('AhGoblin/AuctioneerImport: Auctioneer data successfully imported.')

  else
    print('AhGoblin/AuctioneerImport: Auction house must be open for Auctioneer imports.')
  end

end
