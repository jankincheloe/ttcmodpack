-- Konfiguration
local tanks = {
  {
    readerSide = "left",
    label = "Tank 1",
    capacity = 256000
  },
  {
    readerSide = "right",
    label = "Tank 2",
    capacity = 256000
  }
}

local LOW_THRESHOLD = 30
local FULL_THRESHOLD = 100
local redstoneSide = "front"
local blocked = false

-- Monitor
local monitor = peripheral.find("monitor")
if not monitor then error("Monitor nicht gefunden.") end
monitor.setTextScale(0.75)
monitor.setBackgroundColor(colors.black)
monitor.clear()

local monWidth, monHeight = monitor.getSize()
local halfWidth = math.floor(monWidth / 2)

-- Reader binden
for _, tank in ipairs(tanks) do
  tank.reader = peripheral.wrap(tank.readerSide)
  if not tank.reader then
    error("Block Reader nicht gefunden an Seite: " .. tank.readerSide)
  end
end

-- Zeile gezielt löschen
function clearLine(mon, xOffset, y, width)
  mon.setCursorPos(xOffset + 1, y)
  mon.setBackgroundColor(colors.black)
  mon.setTextColor(colors.white)
  mon.write(string.rep(" ", width))
end

-- Balkenanzeige
function drawBar(mon, x, y, width, percent)
  local filled = math.floor((percent / 100) * width)
  mon.setCursorPos(x, y)
  mon.setBackgroundColor(colors.gray)
  mon.write(string.rep(" ", width))
  mon.setCursorPos(x, y)
  mon.setBackgroundColor(colors.green)
  mon.write(string.rep(" ", filled))
  mon.setBackgroundColor(colors.black)
end

-- Tankanzeige
function drawTank(mon, label, percent, amt, cap, xOffset, width)
  clearLine(mon, xOffset, 1, width)
  clearLine(mon, xOffset, 2, width)
  clearLine(mon, xOffset, 3, width)
  clearLine(mon, xOffset, 4, width)
  clearLine(mon, xOffset, 6, width)

  mon.setCursorPos(xOffset + 1, 1)
  mon.setTextColor(colors.white)
  mon.write(label)

  mon.setCursorPos(xOffset + 1, 2)
  mon.write(string.format("%d / %d mB", amt, cap))

  mon.setCursorPos(xOffset + 1, 3)
  mon.write(string.format("%d%%", percent))

  drawBar(mon, xOffset + 1, 4, width - 2, percent)
end

-- Statusanzeige (unten)
function drawStatus(mon, blocked)
  monitor.setCursorPos(1, 6)
  monitor.setBackgroundColor(colors.black)
  monitor.setTextColor(blocked and colors.red or colors.lime)
  clearLine(mon, 0, 6, monWidth)
  monitor.setCursorPos(1, 6)
  monitor.write(blocked and "Gasleitung: GESCHLOSSEN" or "Gasleitung: OFFEN     ")
end

-- Hauptloop
while true do
  local underThreshold = false
  local allFull = true

  for i, tank in ipairs(tanks) do
    local data = tank.reader.getBlockData()
    local gasTank = data and data.GasTanks and data.GasTanks[0]
    local gasData = gasTank and gasTank.stored
    if gasData and gasData.amount then
      local amt = gasData.amount
      local cap = tank.capacity
      local percent = math.floor((amt / cap) * 100)

      if percent < LOW_THRESHOLD then underThreshold = true end
      if percent < FULL_THRESHOLD then allFull = false end

      drawTank(monitor, tank.label, percent, amt, cap, (i - 1) * halfWidth, halfWidth)
    else
      clearLine(monitor, (i - 1) * halfWidth, 1, halfWidth)
      monitor.setCursorPos((i - 1) * halfWidth + 1, 1)
      monitor.setTextColor(colors.red)
      monitor.write(tank.label .. ": keine Daten")
      underThreshold = true
      allFull = false
    end
  end

  if blocked then
    if allFull then
      blocked = false
      redstone.setOutput(redstoneSide, false)
    end
  else
    if underThreshold then
      blocked = true
      redstone.setOutput(redstoneSide, true)
    else
      redstone.setOutput(redstoneSide, false)
    end
  end

  drawStatus(monitor, blocked)

  sleep(1)
end
