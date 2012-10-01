-- Register the importer.
AhGoblin.RegisterImportModule('tradeskillmaster')

-- Load the TSM addons.
local TSM = LibStub('AceAddon-3.0'):GetAddon('TradeSkillMaster')
local TSMCrafting = LibStub('AceAddon-3.0'):GetAddon('TradeSkillMaster_Crafting')
local TSMAuctioning = LibStub('AceAddon-3.0'):GetAddon('TradeSkillMaster_Auctioning')
local TSMAuctioningConfig = TSMAuctioning:GetModule('Config')
local TSMMailing = LibStub('AceAddon-3.0'):GetAddon('TradeSkillMaster_Mailing')
local TSMMailingConfig = TSMMailing:GetModule('Config')

-- Disable all crafts for the specified profession name.
local function DisableAllCrafts(profession)

  -- Don't do anything if we don't have any crafts for this profession.
  if not TSMCrafting.Data[profession] and TSMCrafting.Data[profession].crafts then return end

  for itemId, _ in pairs(TSMCrafting.Data[profession].crafts) do
    TSMCrafting.Data[profession].crafts[itemId].enabled = false
  end

end

-- Remove all auctioning groups.
local function RemoveAllAuctioningGroups()

  -- Remove all categories.
  for category in pairs(TSMAuctioning.db.profile.categories) do

    -- Delete the category.
    TSMAuctioning.db.profile.categories[category] = nil

    -- Remove any references to this category.
    for key, data in pairs(TSMAuctioning.db.profile) do
      if type(data) == 'table' and data[category] ~= nil then
        data[category] = nil
      end
    end

  end

  -- Remove all groups.
  TSMAuctioning:UpdateGroupReverseLookup()
  for group in pairs(TSMAuctioning.db.profile.groups) do

    -- Delete the group.
    TSMAuctioning.db.profile.groups[group] = nil

    -- Remove any references to this group.
    for key, data in pairs(TSMAuctioning.db.profile) do
      if type(data) == 'table' and data[group] ~= nil then
        data[group] = nil
      end
    end

    -- Remove any reverse lookups for the group.
    if TSMAuctioning.groupReverseLookup[group] then
      TSMAuctioning.db.profile.categories[TSMAuctioning.groupReverseLookup[group]][group] = nil
    end

  end

  -- Reset the tree status.
  TSMAuctioning.db.global.treeGroupStatus.groups = { [2] = true }

  -- Update the config tree.
  TSMAuctioningConfig:UpdateTree()
  if TSMAuctioningConfig.treeGroup then
    TSMAuctioningConfig.treeGroup:SelectByPath(2)
  end

end

-- Add a category to the TSM Auctioning addon.
local function AddAuctioningCategory(name)
  TSMAuctioning.db.profile.categories[name] = {}
  TSMAuctioningConfig:UpdateTree()
end

-- Add an auctioning group to the TSM Auctioning addon below the specified
-- category.
local function AddAuctioningGroup(category, name, minimumPrice, fallbackPrice, postCap, perAuction, postTime)

  -- Just to make sure we're working on numbers and not strings.
  minimumPrice = minimumPrice + 0
  fallbackPrice = fallbackPrice + 0
  postCap = postCap + 0
  perAuction = perAuction + 0
  postTime = postTime + 0
  
  -- Add the category.
  TSMAuctioning.db.profile.groups[name] = {}
  TSMAuctioning.db.profile.categories[category][name] = true

  -- Set the minimum price threshold.
  TSMAuctioning.db.profile['thresholdPriceMethod'][name] = 'gold'
  TSMAuctioning.db.profile['threshold'][name] = minimumPrice

  -- Set the fallback price.
  TSMAuctioning.db.profile['fallbackPriceMethod'][name] = 'gold'
  TSMAuctioning.db.profile['fallback'][name] = fallbackPrice

  -- Set the post cap.
  TSMAuctioning.db.profile['postCap'][name] = postCap

  -- Set the per auction setting.
  TSMAuctioning.db.profile['perAuction'][name] = perAuction

  -- Set the post time setting.
  TSMAuctioning.db.profile['postTime'][name] = postTime

  -- Set the ignore stacks per-setting to match our perAuction setting.
  TSMAuctioning.db.profile['ignoreStacksOver'][name] = perAuction
  TSMAuctioning.db.profile['ignoreStacksUnder'][name] = perAuction

  -- Refresh the config tree.
  TSMAuctioningConfig:UpdateTree()

end

-- Add an item to the craft list for a profession.
local function AddItemCraft(profession, itemId, group, maxRestockQuantity, minRestockQuantity)

  -- Just to make sure we're working on numbers and not strings.
  itemId = itemId + 0 
  maxRestockQuantity = maxRestockQuantity + 0
  minRestockQuantity = minRestockQuantity + 0

  if TSMCrafting.Data[profession] ~= nil then
    if TSMCrafting.Data[profession].crafts[itemId] ~= nil then

      -- Enable the craft.
      TSMCrafting.Data[profession].crafts[itemId].enabled = true

      -- Set the max restock quantity.
      TSMCrafting.db.profile.maxRestockQuantity[itemId] = maxRestockQuantity
      
      -- Set the min restock quantity.
      TSMCrafting.db.profile.minRestockQuantity[itemId] = minRestockQuantity

      -- Associate the item with the group.
      TSMCrafting:SendMessage('TSMAUC_NEW_GROUP_ITEM', group, itemId)

    else

      -- We were unable to locate the craft for the profession. Just add the
      -- item as a normal item in TSM Auctioning instead.
      TSMCrafting:SendMessage('TSMAUC_NEW_GROUP_ITEM', group, itemId)
 
    end
  else
      print('AhGoblin/TradeSkillMasterImport: WARNING: Invalid profession ' .. profession .. ' referenced in import data')
  end
  
end

-- Look up the name of an item in the TSMCrafting data table.
local function ResolveItemName(profession, itemId)

  itemId = itemId + 0 -- Just make sure its a valid number.
  
  if TSMCrafting.Data[profession] ~= nil then
    if TSMCrafting.Data[profession].crafts[itemId] ~= nil then
      return TSMCrafting.Data[profession].crafts[itemId].name
    else
      itemName = GetItemInfo(itemId)
      return itemName
    end
  else
      print('AhGoblin/TradeSkillMasterImport: WARNING: Invalid profession ' .. profession .. ' referenced in import data')
  end

  return nil

end

-- Remove all mailing characters from TSM mailing.
local function RemoveAllMailingCharacters()
  TSMMailing.db.factionrealm.mailTargets = {}
  TSMMailing.db.factionrealm.mailItems = {}
  if TSMMailingConfig.treeGroup then
    TSMMailingConfig:UpdateTree()
  end
end

-- Register a mailing character in TSM mailing.
local function RegisterMailingCharacter(characterName)

  -- Check if the character is already registered.
  for _, name in pairs(TSMMailing.db.factionrealm.mailTargets) do
    if name:lower() == characterName:lower() then return end
  end

  -- Add the character.
  tinsert(TSMMailing.db.factionrealm.mailTargets, characterName:lower())
  if TSMMailingConfig.treeGroup then
    TSMMailingConfig:UpdateTree()
  end
  
end

-- Register a group to be mailed to the specified character in TSM mailing.
local function RegisterMailingGroup(groupName, characterName)

  -- Make sure the character is registered.
  RegisterMailingCharacter(characterName)

  -- Set up automailing of the specified group to the character.
  TSMMailing.db.factionrealm.mailItems[groupName] = characterName:lower()
  if TSMMailingConfig.treeGroup then
    TSMMailingConfig:UpdateTree()
  end

end

-- Register an item to be mailed to the specified character in TSM mailing.
local function RegisterMailingItem(itemId, characterName)

  -- Make sure we're working with numbers.
  itemId = itemId + 0

  -- Make sure the character is registered.
  RegisterMailingCharacter(characterName)

  -- Set up automailing of the specified item to the character.
  TSMMailing.db.factionrealm.mailItems[itemId] = characterName:lower()
  if TSMMailingConfig.treeGroup then
    TSMMailingConfig:UpdateTree()
  end

end

-- Define the import function.
AhGoblin.ImportModules.tradeskillmaster.import = function(data)

  -- Disable all crafts for all professions.
  for _, data in ipairs(TSMCrafting.tradeSkills) do
    DisableAllCrafts(data.name)
  end

  -- Remove all auctioning groups.
  RemoveAllAuctioningGroups()

  -- Remove all mailing characters.
  RemoveAllMailingCharacters()

  -- Parse the imported data.
  dataSet = AhGoblin.ParseImportData(data, '1.0.0')
  if getn(dataSet) > 0 then

    -- Add categories from the data set.
    for _, item in ipairs(dataSet) do
      if item[1] == 'category' then

        table.remove(item, 1)

        -- Iterate through the remaining data and add each catgory.
        for _, categoryName in ipairs(item) do
          AddAuctioningCategory(categoryName)
        end
      end
    end

    -- Add items from the data set.
    for _, item in ipairs(dataSet) do
      if item[1] == 'item' then

        local category = item[2]
        local profession = item[3]
        local mailingCharacter = item[4]
        local itemId = item[5]
        local minimumPrice = item[6]
        local fallbackPrice = item[7]
        local maxRestockQty = item[8]
        local minRestockQty = item[9]
        local postCap = item[10]
        local perAuction = item[11]
        local postTime = item[12]

        -- Mining isn't supported by TSM.
        if profession ~= 'Mining' then

          -- Find the item name from the TSM craft list.
          local itemName = ResolveItemName(profession, itemId)
          if itemName ~= nil then

            -- Determine the group name for this item.
            local group = itemName:lower()

            -- Add the auctioning group.
            AddAuctioningGroup(category, group, minimumPrice, fallbackPrice, postCap, perAuction, postTime)

            -- Add the item craft.
            AddItemCraft(profession, itemId, group, maxRestockQty, minRestockQty)

            -- If a mailing character is defined, set up mailing.
            if mailingCharacter ~= nil and mailingCharacter ~= '' and mailingCharacter ~= '-' then
              RegisterMailingGroup(group, mailingCharacter)
            end

          else
            print('AhGoblin/TradeSkillMasterImport: Skipping import of item ' .. itemId .. ' for profession ' .. profession .. ' - unable to find item information.')
          end

        end

      end
    end

    -- Add auto mail settings from the data set.
    for _, item in ipairs(dataSet) do
      if item[1] == 'automail' then

        -- Remove the prefix.
        table.remove(item, 1)

        -- Pull out and remove the character name.
        local characterName = item[1]
        table.remove(item, 1)

        -- Iterate through the remaining data and add each auto mail item.
        for _, itemId in ipairs(item) do
          RegisterMailingItem(itemId, characterName)
        end

      end
    end

  end

  print('AhGoblin/TradeSkillMasterImport: TSM data successfully imported.')

end
