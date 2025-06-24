local component = peripheral.wrap("bottom") -- Block Reader
local redstoneSide = "left"                -- Redstone-Ausgang
local threshold = 98                       -- Schwellwert in %

local maxEnergy = 16000000                 -- Fester Maximalwert

while true do
  local data = component.getBlockData()

  if data and data.stored then
    local energy = tonumber(data.stored)
    local percent = (energy / maxEnergy) * 100

    print(string.format("Energie: %.2f%%", percent))

    if percent >= threshold then
      redstone.setOutput(redstoneSide, true)
    else
      redstone.setOutput(redstoneSide, false)
    end
  else
    print("Keine gültigen Daten vom Block Reader.")
  end

  sleep(2)
end
