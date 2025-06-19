-- Delete old files.
term.setTextColor(colors.green)
print("Deleting files..")
term.setTextColor(colors.gray)
shell.run("delete", "/MonitorHandler/MonitorHandler")
shell.run("delete", "/MonitorHandler/updater")
shell.run("delete", "/MonitorHandler/makelist")

-- Runn installer to get all new files.
shell.run("/MonitorHandler/installer")
term.setTextColor(colors.green)
print("Done.")
