local component = peripheral.wrap("bottom") -- Block Reader
local redstoneSide = "left"                -- Redstone-Ausgabe
local threshold = 98                       -- Schwellwert in %
local maxEnergy = 16000000                 -- Bekannter Maximalwert

while true do
  local data = component.getBlockData()

  if data and data.EnergyContainers and data.EnergyContainers[0] then
    local storedStr = data.EnergyContainers[0].stored
    local stored = tonumber(storedStr)

    if stored then
      local percent = (stored / maxEnergy) * 100
      print(string.format("Energie: %.2f%%", percent))

      if percent >= threshold then
        redstone.setOutput(redstoneSide, true)
      else
        redstone.setOutput(redstoneSide, false)
      end
    else
      print("Fehler: 'stored' ist kein gültiger Zahlenwert.")
    end
  else
    print("Fehler: EnergyContainers-Daten fehlen.")
  end

  sleep(2)
end
