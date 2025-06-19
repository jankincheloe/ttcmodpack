-- Opens Doors which need a redstone signal
-- need door-server to communicate with
-- add a wireless modem and place the computer

local modemSide = "back"  -- define the side where the modem is

-- start rednet
rednet.open(modemSide)

-- Empfange Antwort
print("Türöffnung wird angefordert...")
rednet.broadcast("openDoor")

-- Optional: auf Antwort warten
local id, msg = rednet.receive(6) -- Timeout 6 Sek.
if msg == "done" then
  print("Tür wurde geöffnet & wieder geschlossen.")
elseif msg == "unauthorized" then
  print("Nicht autorisiert.")
else
  print("Keine Antwort erhalten.")
end
