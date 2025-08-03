-- === KONFIGURATION ===
local influxUrl = "https://<dein-influx-url>/api/v2/write?org=<org>&bucket=minecraft&precision=s"
local influxToken = "<DEIN_WRITE_TOKEN>"
local reactor = peripheral.wrap("back")  -- oder "left", "right", je nach Platzierung
local hostname = "fission_reactor_1"
local apiUrl = "https://nodered.kincheloe.de/api/reactor"

-- === FUNKTION: API abfragen ===
local function getReactorTargetState()
  local res = http.get(apiUrl)
  if res then
    local body = res.readAll()
    res.close()
    local data = textutils.unserializeJSON(body)
    return data and data.state or nil
  else
    print("Fehler beim Abruf von /api/reactor")
    return nil
  end
end

-- === FUNKTION: Werte an Influx senden ===
local function sendToInflux(fields)
  local timestamp = os.epoch("utc")
  local lines = {}

  for k, v in pairs(fields) do
    table.insert(lines, string.format("%s=%s", k, tostring(v)))
  end

  local payload = string.format(
    "reactor_status,host=%s %s %d",
    hostname,
    table.concat(lines, ","),
    math.floor(timestamp / 1000)
  )

  http.post(influxUrl, payload, {
    ["Authorization"] = "Token " .. influxToken,
    ["Content-Type"] = "text/plain"
  })
end

-- === HAUPTSCHLEIFE ===
while true do
  local targetState = getReactorTargetState()
  local currentActive = reactor.getStatus() == true

  -- Reaktorsteuerung
  if targetState == "on" and not currentActive then
    print("Reaktor wird aktiviert")
    reactor.activate()
  elseif targetState == "off" and currentActive then
    print("Reaktor wird deaktiviert")
    reactor.scram()
  end

  -- Daten sammeln
  local status = {
    active = currentActive and 1 or 0,
    temp = reactor.getTemperature(),
    fuel = reactor.getFuel(),
    maxFuel = reactor.getMaxFuel(),
    waste = reactor.getWaste(),
    maxWaste = reactor.getMaxWaste(),
    coolant = reactor.getCoolant(),
    maxCoolant = reactor.getMaxCoolant(),
    heatingRate = reactor.getHeatingRate(),
    damagePercent = reactor.getDamagePercent()
  }

  sendToInflux(status)

  sleep(5)
end
