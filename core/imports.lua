local AceGUI = LibStub('AceGUI-3.0')

-- Simple function to split a string on any given delimiter.
AhGoblin.SplitString = function(str, delimiter)

  local t = {}
  local i = 1
  for s in string.gmatch(str, '([^' .. delimiter .. ']+)') do
    t[i] = s
    i = i + 1
  end

  return t

end

-- Registers an import module for the addon.
AhGoblin.RegisterImportModule = function(name)
  AhGoblin.ImportModules[name] = {
    ['import'] = function(data) end
  }
end

-- Parse an import data set.
AhGoblin.ParseImportData = function(data, required_version)

  lines = {}
  dataSet = {}
  local function SplitLines(line) table.insert(lines, line) return '' end
  SplitLines((data:gsub('(.-)\r?\n', SplitLines)))

  if getn(lines) < 1 then
    print('Unable to parse import data: not enough data')
    return dataSet
  end

  -- Assert that the import data has the correct version.
  version = AhGoblin.SplitString(table.remove(lines, 1), '|')
  if getn(version) ~= 2 or version[1] ~= 'version' then
    print('Unable to parse import data: invalid version header')
    return dataSet
  end
  if version[2] ~= required_version then
    print('Unable to parse import data: unsupported version in header (' .. version[2] .. ')')
    return dataSet
  end

  -- Go through each line and split it up - then add it to the data set.
  for _, line in ipairs(lines) do
    table.insert(dataSet, AhGoblin.SplitString(line, '|'))
  end

  return dataSet

end

-- Initial point of entry for importing data. Present the user with a window to
-- paste the import data into, then delegate that data set to the actual import
-- module.
AhGoblin.ImportData = function(module_name)

  if module_name ~= nil and AhGoblin.ImportModules[module_name] ~= nil then

    -- Set up the import GUI.

    -- Create the main window.
    local f = AceGUI:Create('Frame')
    f:SetCallback('OnClose', function(self) AceGUI:Release(self) end)
    f:SetTitle('AhGoblin Import: ' .. module_name)
    f:SetLayout('flow')
    f:SetHeight(300)

    -- Create the large edit box where import data will be pasted.
    local eb = AceGUI:Create('MultiLineEditBox')
    eb:SetLabel('Data from AhGoblin')
    eb:SetFullWidth(true)
    eb:SetMaxLetters(0)
    f:AddChild(eb)

    -- Create the import button.
    local btn = AceGUI:Create('Button')
    btn:SetText('Import')
    btn:SetFullWidth(true)
    btn:SetCallback('OnClick', function()

      print('AhGoblin: Importing data into ' .. module_name)
      local data = eb:GetText()
      AhGoblin.ImportModules[module_name].import(data)

    end)
    f:AddChild(btn)

    -- Set some frame parameters.
    f.frame:SetFrameStrata('FULLSCREEN_DIALOG')
    f.frame:SetFrameLevel(100)

  else
    print('AhGoblin: Unknown import module - ' .. module_name)
  end

end
