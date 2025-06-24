local component = peripheral.wrap("bottom") -- Seite anpassen: z.B. "left", "right", "top"
local redstoneSide = "left" -- Seite für Redstone-Ausgang
local th = 98 -- Prozenzahl der Aktivierung Ausgabe

-- Funktion zum Berechnen der Prozentzahl
local function getEnergyPercentage(data)
  local energy = data.energy or 0
  local maxEnergy = data.maxEnergy or 1 -- Schutz gegen Division durch 0
  return (energy / maxEnergy) * 100
end

while true do
  local data = component.getBlockData()

  if data then
    local percentage = getEnergyPercentage(data)
    print(string.format("Energie: %.2f%%", percentage))

    if percentage > th then
      redstone.setOutput(redstoneSide, true)
    else
      redstone.setOutput(redstoneSide, false)
    end
  else
    print("Fehler: Keine Daten vom Block Reader.")
  end

  sleep(2) -- alle 2 Sekunden prüfen
end
