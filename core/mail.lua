-- Add event hook to the mailbox show-event.
local mailOpenFrame = CreateFrame('FRAME')
mailOpenFrame:RegisterEvent('MAIL_SHOW')
mailOpenFrame:SetScript('OnEvent', function()
  AhGoblin.MailboxOpen = true
end)

-- Add event hook to the mailbox closed-event.
local mailOpenFrame = CreateFrame('FRAME')
mailOpenFrame:RegisterEvent('MAIL_CLOSED')
mailOpenFrame:SetScript('OnEvent', function()
  AhGoblin.MailboxOpen = false
end)
