function downloadFile(web,lcal)
  print("Updating '" .. lcal .. "'")
  
  request = http.get(web)
  data = request.readAll()
  
  if fs.exists(lcal) then
    fs.delete(lcal)
    file = fs.open(lcal, "w")
    file.write(data)
    file.close()
  else
    file = fs.open(lcal, "w")
    file.write(data)
    file.close()
  end
  
  print("Update complete!")
end


term.clear()
term.setCursorPos(1,1)
local clientVersion = "0.1"
print("LunaOS " .. clientVersion .. " starting up...")

-- Check if there is an update
versionRequest = http.get("https://raw.githubusercontent.com/dadaemon/LunaOS/master/LunaOS.ver")
serverVersion = versionRequest.readAll()

if serverVersion ~= clientVersion then
  print("Version "..serverVersion.." is now available. Updating!")

  -- lib folder
  if fs.isDir("./LunaOS/lib") == false then
    fs.makeDir("./LunaOS/lib")
  end
  -- lib/funcs
  downloadFile("https://raw.githubusercontent.com/dadaemon/LunaOS/master/lib/funcs", "./LunaOS/libs/funcs")
  -- lib/button
  downloadFile("https://raw.githubusercontent.com/dadaemon/LunaOS/master/lib/button", "./LunaOS/libs/button")
  
  -- cnf folder
  if fs.isDir("./LunaOS/cnf") == false then
    fs.makeDir("./LunaOS/cnf")
  end
  
  -- LunaOS.lua
  downloadFile("https://raw.githubusercontent.com/dadaemon/LunaOS/master/LunaOS.lua", "./LunaOS/LunaOS.lua")
  
  print("Rebooting computer...")
  sleep(2)
  os.reboot()
end

-- Load files
--os.loadAPI("./LunaOS/libs/touchpoint")
os.loadAPI("./LunaOS/libs/funcs")
os.loadAPI("./LunaOS/libs/button")

-- Set variables


-- Start
while true do
  print("Now we sleep...")
  sleep(5)
end