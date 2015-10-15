function downloadAPI()
  print("Updating...")
  
  request = http.get("https://raw.github.com/Morgrimm/CCButtonAPI/master/CCButtonAPI.txt")
  data = request.readAll()
  
  if fs.exists("button") then
    fs.delete("button")
    file = fs.open("button", "w")
    file.write(data)
    file.close()
  else
    file = fs.open("button", "w")
    file.write(data)
    file.close()
  end
  
  print("Update complete.")
end

if fs.exists("button") then
  os.unloadAPI("button")
  os.loadAPI("button")
  
  clientVersion = button.version()
  
  versionRequest = http.get("https://raw.github.com/Morgrimm/CCButtonAPI/master/CCButtonAPI.versions.txt")
  serverVersion = versionRequest.readAll()
  
  if serverVersion == clientVersion then
    print("You have the newest version of the API.")
  else
    print("Version "..serverVersion.." is now available. Would you like to update?")
    
    input = read()
    
    if string.lower(input) == "yes" then
      downloadAPI()
    else
      print("Update canceled.")
    end
  end
else
  downloadAPI()
end