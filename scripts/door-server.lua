local modemSide = "bottom"  -- oder "top", je nachdem wo das Modem sitzt
local redstoneSide = "top" -- Seite zur Tür
local openDuration = 5    -- Sekunden
local whitelist = {
    [10] = true
}


-- Modem aktivieren
rednet.open(modemSide)
print("Tür-Server bereit. Warte auf Befehle...")

while true do
  local id, message = rednet.receive()
  if not whitelist[id] then
      rednet.send(id, "unauthorized")
  elseif message == "openDoor" then
    print("Tür öffnen von ID "..id)
    redstone.setOutput(redstoneSide, true)
    sleep(openDuration)
    redstone.setOutput(redstoneSide, false)
    print("Tür geschlossen")
    rednet.send(id, "done")
  end
end
