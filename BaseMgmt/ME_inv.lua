-- ▶ Konfiguration ----------------------------------

local config = {
  meBridgeSide = "right",      -- Seite des ME Bridge
  monitorSide = "left",        -- Seite des Monitors
  itemList = {
    { name = "minecraft:iron_ingot", label = "Iron Ingot" },
    { name = "minecraft:redstone", label = "Redstone" },
    { name = "appliedenergistics2:fluix_crystal", label = "Fluix Crystal" },
  },
  influx = {
    host = "<dein-host>",
    org = "meine-org",
    bucket = "minecraft",
    token = "<DEIN_TOKEN>"
  },
  estimatedTotal = 1000000,   -- geschätzte max. Item-Anzahl im ME
  updateInterval = 10         -- in Sekunden
}

-- ▶ Setup -----------------------------------------

local me = peripheral.wrap(config.meBridgeSide)
local monitor = peripheral.wrap(config.monitorSide)
if not me then error("❌ ME Bridge nicht gefunden!") end
if not monitor then error("❌ Monitor nicht gefunden!") end

-- ▶ Funktionen -------------------------------------

-- Daten an Influx senden
local function sendToInflux(measurement, tags, fields)
  local ts = math.floor(os.epoch("utc") / 1000)
  local tagStr = ""
  for k, v in pairs(tags) do
    tagStr = tagStr .. string.format(",%s=%s", k, v)
  end

  local fieldStr = ""
  for k, v in pairs(fields) do
    fieldStr = fieldStr .. string.format("%s=%s,", k, tostring(v))
  end
  fieldStr = fieldStr:sub(1, -2) -- letztes Komma entfernen

  local payload = string.format("%s%s %s %d", measurement, tagStr, fieldStr, ts)
  local url = string.format(
    "http://%s:8086/api/v2/write?org=%s&bucket=%s&precision=s",
    config.influx.host, config.influx.org, config.influx.bucket
  )
  local headers = {
    ["Authorization"] = "Token " .. config.influx.token,
    ["Content-Type"] = "text/plain"
  }

  local res, err = http.post(url, payload, headers)
  if res then res.close() end
end

-- Geschätzte Speicherbelegung berechnen
local function getSimulatedStorage()
  local totalUsed = 0
  local items = me.listItems()
  for _, item in pairs(items) do
    totalUsed = totalUsed + item.amount
  end
  return {
    used = totalUsed,
    total = config.estimatedTotal,
    percent = (totalUsed / config.estimatedTotal) * 100
  }
end

-- Anzeige auf Monitor
local function updateDisplay(itemData, storage, cpuBusy, channels)
  monitor.setTextScale(0.5)
  monitor.setBackgroundColor(colors.black)
  monitor.setTextColor(colors.white)
  monitor.clear()
  monitor.setCursorPos(1, 1)
  monitor.write("ME-System Monitor")
  monitor.setCursorPos(1, 2)
  monitor.write("------------------")

  local line = 3
  for _, entry in ipairs(itemData) do
    monitor.setCursorPos(1, line)
    monitor.write(string.format("%s: %s", entry.label, entry.amount))
    line = line + 1
  end

  monitor.setCursorPos(1, line + 1)
  monitor.write(string.format("Speicher: %.1f%%", storage.percent))

  monitor.setCursorPos(1, line + 2)
  monitor.write("Crafting: " .. (cpuBusy and "aktiv" or "frei"))

  monitor.setCursorPos(1, line + 3)
  monitor.write("Channels: " .. tostring(channels))
end

-- ▶ Hauptlogik ------------------------------------

while true do
  -- Items
  local items = {}
  for _, entry in ipairs(config.itemList) do
    local item = me.getItem({ name = entry.name })
    local amount = item and item.amount or 0
    table.insert(items, { label = entry.label, amount = amount })
    sendToInflux("me_items", { item = entry.name }, { amount = amount })
  end

  -- Speicher simulieren
  local storage = getSimulatedStorage()
  sendToInflux("me_status", {}, {
    used = storage.used,
    total = storage.total,
    percent = storage.percent
  })

  -- Crafting CPUs
  local cpus = me.getCraftingCPUs()
  local busy = false
  for _, cpu in pairs(cpus) do
    if cpu.busy then busy = true break end
  end
  sendToInflux("me_status", {}, { crafting = busy and 1 or 0 })

  -- Channels
  local channels = me.getUsedChannels()
  sendToInflux("me_status", {}, { channels = channels })

  -- Anzeige aktualisieren
  updateDisplay(items, storage, busy, channels)

  sleep(config.updateInterval)
end
