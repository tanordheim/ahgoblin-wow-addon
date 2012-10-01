-- Set up the AhGoblin addon.
AhGoblin = {
  ['ImportModules'] = {},
  ['AuctionHouseOpen'] = false,
  ['MailboxOpen'] = false
}

-- Set up the slash commands
SlashCmdList['AHGOBLIN_SLASHCMD'] = function(msg)
  local command, params = msg:match('^(%S*)%s*(.-)$');
  if command == 'import' then
    AhGoblin.ImportData(params)
  elseif command == 'export' then
    AhGoblin.ExportData(params)
  elseif command == 'dumpinv' then
    AhGoblin.DumpInventory(params)
  else
    print('AhGoblin: Unsupported command - ' .. command)
  end
end
SLASH_AHGOBLIN_SLASHCMD1 = '/ahgoblin'
