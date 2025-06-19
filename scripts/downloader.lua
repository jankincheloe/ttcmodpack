-- Konfiguration
local user = "jankincheloe"
local repo = "ttcmodpack"
local branch = "main"
local basePath = "scripts/" -- <-- Nur dieser Ordner wird gefiltert

-- JSON-Dekodierung
local json = textutils.unserializeJSON or require("json")

-- GitHub-Dateien auslesen
local function listFiles()
    local api = "https://api.github.com/repos/"..user.."/"..repo.."/git/trees/"..branch.."?recursive=1"
    local h = http.get(api)
    if not h then error("Fehler: API-Zugriff") end
    local data = json(h.readAll())
    h.close()
    local files = {}
    for _, f in ipairs(data.tree) do
        if f.type == "blob" and f.path:match("^"..basePath..".+%.lua$") then
            table.insert(files, f.path)
        end
    end
    table.sort(files)
    return files
end

-- Einzelnen File laden
local function download(path)
    local raw = "https://raw.githubusercontent.com/"..user.."/"..repo.."/"..branch.."/"..path
    local h = http.get(raw)
    if not h then
        print("Download fehlgeschlagen: "..path)
        return
    end
    local target = fs.getName(path)
    local f = fs.open(target, "w")
    f.write(h.readAll())
    f.close()
    h.close()
    print("-> '"..target.."' gespeichert.")
    return target
end

-- Menü anzeigen
local files = listFiles()
while true do
    term.clear()
    term.setCursorPos(1,1)
    print("=== TTC GitHub Downloader ===\n")
    for i, path in ipairs(files) do
        print(string.format("%2d. %s", i, path:sub(#basePath + 1)))
    end
    print("\nWähle Nummer (oder q für Ende):")
    local input = read()
    if input == "q" then break end
    local index = tonumber(input)
    if index and files[index] then
        local target = download(files[index])
        if target then
            print("Sofort starten? (j/n)")
            if read():lower() == "j" then
                shell.run(target)
            end
        end
    else
        print("Ungültige Eingabe.")
    end
    print("Beliebige Taste für zurück...")
    os.pullEvent("key")
end
