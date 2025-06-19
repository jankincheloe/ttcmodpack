-- Intelligent Energy Management Program (IEMP)
--
-- Version: 0.4a
--
-- Author: Miscellaniuz
--
-- ////////////////////////

-- @ version //
version = "0.4a"

-- ToTheCore Utils import //
os.loadAPI("/Utils/Utils")

-- Variables //
tickcount = 0.5 --Update interval of monitor in sec
MinRF = 140000000 -- Minimum amount of RF storage before triggering energy backup system

-- Startup
Console.Init()
Console.ClearScreen()
Console.WriteLine(Console.Type.Info, "Welcome to IEMP.", m)
Console.WriteLine(Console.Type.Line, "---------------", m)
Console.WriteLine(Console.Type.Info, "We are running on version " .. version, m)
Console.WriteLine(Console.Type.Line, "---------------", m)
Console.WriteLine(Console.Type.Config, "Update interval is set to " .. tickcount, m)
Console.WriteLine(Console.Type.Config, "Minimum trigger is set to " .. MinRF, m)
Console.WriteLine(Console.Type.Line, "---------------", m)
Console.WriteLine(Console.Type.Init, "UtilsAPI loaded.", m)

-- init //
local cbmain = peripheral.wrap("capacitor_bank_2")
local cbbackup1 = peripheral.wrap("capacitor_bank_3")
local cbbackup2 = peripheral.wrap("capacitor_bank_4")
Console.WriteLine(Console.Type.Init, "Capacitor Bank 1 found.", m)
Console.WriteLine(Console.Type.Init, "Capacitor Bank 2 found.", m)
Console.WriteLine(Console.Type.Init, "Capacitor Bank 3 found.", m)


local monitor = peripheral.wrap("right")
Console.WriteLine(Console.Type.Init, "Monitor found on right.", m)

-- Main Monitor Init //
monitor.clear()
monitor.setTextScale(0.5)
monitor.setTextColor(colors.yellow)
-- monitor.setBackgroundColor(255) --deactivated for later
monitor.setCursorPos(1,1)
monitor.write("Intelligent Energy Management Program [IEMP] ver " .. version)
monitor.setCursorPos(1,2)
monitor.write("------------------------------------------------------")

monitor.setTextColor(colors.white)
monitor.setCursorPos(1,4)
monitor.write("Current Energy Level")
monitor.setCursorPos(1,5)
monitor.setTextColor(colors.blue) monitor.write("Main Capacitor Bank: ")
monitor.setCursorPos(1,6)
monitor.setTextColor(colors.blue) monitor.write("Backup Capacitor Bank: ")
monitor.setTextColor(colors.green)

-- end of init //
Console.WriteLine(Console.Type.Line, "---------------", m)
Console.WriteLine(Console.Type.Info, "Initialization done.", m)
Console.WriteLine(Console.Type.Hint, "Press CTRL+T to terminate the program.", m)


-- main program //
while true do

  energylevel = cbmain.getEnergyStored()
  backupenergy = cbbackup1.getEnergyStored() + cbbackup2.getEnergyStored()

  number = energylevel -- avoid attempt to call nil error(

  monitor.setCursorPos(24,5)
  monitor.write(StringUtils.numformat(number).." RF")


  number = backupenergy

  monitor.setCursorPos(24,6)
  monitor.write(StringUtils.numformat(number).." RF")

  -- RF trigger //
  if energylevel < MinRF then
     redstone.setOutput("left", true)
     monitor.setTextColor(colors.red) -- Text red
     monitor.setCursorPos(1,7)
     monitor.write("Energy Backup active")
    elseif energylevel > MinRF then
      redstone.setOutput ("right", false)
      monitor.setTextColor(colors.green) -- Text back to green
      monitor.setCursorPos(1,7)
      monitor.clearLine() -- deleting "Energy Backup active"
  end


  sleep(tickcount)

end
