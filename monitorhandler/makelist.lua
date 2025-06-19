--- This script is used to create a new "monitorHandler.cfg".
os.loadAPI("/Utils/Utils") -- Load all Utils

Console.ClearScreen()
Console.WriteLine(Console.Type.Debug, "I'm working currently on this script.")
-- Write monitor name on every connected monitor
local peripherals = peripheral.getNames()
for i = 1, #peripherals do
  if(peripheral.getType(peripherals[i]) == "monitor") then
    local tempPeripheral = peripheral.wrap(peripherals[i])
    tempPeripheral.setTextScale(0.5)

    -- Clear screen & write text.
    Console.ClearScreen(tempPeripheral)
    for x = 1, 100 do
      Console.WriteLine(Console.Type.Hint, peripherals[i] .. " --------> " .. x, tempPeripheral)
    end
  end
end

Console.WriteLine(Console.Type.Debug, "Monitor name on")
Console.WriteLine(Console.Type.Debug, "each monitor..")

Console.WriteLine(Console.Type.Hint, "Gutenacht ;)")
