-- Made by Miscellaniuz
-- Reads Mekanism Induction Cell and POSTs it to a HTTP Endpoint

-- Konfiguration
local config = {
  name = "reactor_base",  -- eindeutige Kennung
  side = "back",         -- Seite des angeschlossenen Induction Port
  org = "meine-org",
  bucket = "minecraft",
  host = "<dein-host>",   -- IP oder Hostname von InfluxDB
  token = "<influx-api-key>",
  unit_conversion = 2.5, -- EU to FE o.Ä.
  sleeptime = 5
}

-- Peripherie binden
local induction = peripheral.wrap(config.side)
if not induction then
  print("Kein Induction Port auf Seite: " .. config.side)
  return
end

while true do
-- Daten ermitteln
local stored = induction.getEnergy() / config.unit_conversion
local max = induction.getMaxEnergy() / config.unit_conversion
local percent = induction.getEnergyFilledPercentage()
local input = induction.getLastInput() / config.unit_conversion
local output = induction.getLastOutput() / config.unit_conversion
local io = induction.getTransferCap() / config.unit_conversion


-- local ts = os.epoch("utc") / 1000  -- Zeit in Sekunden

-- InfluxDB URL
local influxURL = string.format(
  "https://%s/api/v2/write?org=%s&bucket=%s&precision=s",
  config.host, config.org, config.bucket
)

-- Payload im Line Protocol mit Tag "system=<name>"
local payload = string.format(
  "energy,system=%s stored=%d,max=%d,percent=%.2f,input=%d,output=%d,io=%d",
  config.name, stored, max, percent, input, output, io -- , ts
)

-- Header
local headers = {
  ["Authorization"] = "Token " .. config.token,
  ["Content-Type"] = "text/plain"
}

-- Senden
local response, err = http.post(influxURL, payload, headers)
if response then
  print("Gesendet für " .. config.name .. " | Status: " .. response.getResponseCode())
  response.close()
else
  print("Fehler: " .. tostring(err))
end
os.sleep(config.sleeptime)
end
