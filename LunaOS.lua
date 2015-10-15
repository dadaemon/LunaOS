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
local clientVersion = "0.4"
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
local barrelFile = "./LunaOS/cnf/barrels"
local recipeFile = "./LunaOS/cnf/recipes"

local exitLunaOS = false
local currentPage = "home"
local monitor = "monitor_6"
local mn = {}
local mnh = {}
local newRec = {}

local th = funcs.termH

-- - colors
local cG = colors.green
local cR = colors.red
local cW = colors.white

-- Load configs
local recipes = {}
local barrels = {}

-- Initialise buttons
--local tp = touchpoint.new()
button.setMon(monitor)

-- Status peripherals
--funcs.printPeripherals()

-- Functions/pages

function exitLOS()
  exitLunaOS = true
end

function loadConfigs()
  barrels = funcs.load(barrelFile)
  recipes = funcs.load(recipeFile)
end

function saveConfigs()
  funcs.save(barrels, barrelFile)
  funcs.save(recipes, recipeFile)
end

function mainMenu()
  --button.reset()
  os.unloadAPI("./LunaOS/libs/button")
  os.loadAPI("./LunaOS/libs/button")
  button.setMon(monitor)
  funcs.clearTerm()
  
  mn = {}
  mnh = {}
  table.insert(mn,{"Exit",exitLOS})
  table.insert(mn,{"Home",menuHome})
  table.insert(mn,{"Craft",menuCraft})
  
  --button.add("exit","Exit","flash",1,th-2,15,th,cG,cR,cW,exitLOS)
  --button.add("home","Home","flash",17,th-2,31,th,cG,cR,cW,menuHome)
end

function printStatus(text)
  funcs.printStatus(text)
end

function bDraw()
  for t=1,#mn do
    local nx = mn[t][1]
    local fx = mn[t][2]
    button.add(nx,nx,"flash",(t*15)-13,th-3,(t*15)-1,th-1,colors.lightGray,colors.gray,colors.black,fx)
  end
  
  if #mnh ~= 0 then
    local maxRows = (funcs.termH - 5) / 5
    local row = 0
    local col = 0
    
    for t=1,#mnh do
      local nx = mnh[t][1]
      local fx = mnh[t][2]
      
      row = row + 1
      if row > maxRows then
        row = 1
        col = col + 1
      end
      
      button.add(nx,nx,"flash",5+(col*35),(row*5)-1,38+(col*35),1+(row*5),cG,cR,cW,fx)
    end
  end
  
  button.draw()
  printStatus("Page: " .. currentPage)
end

function menuHome()
  currentPage = "home"
  mainMenu()

  --table.insert(mn,{"Tests",menuTests})
  --table.insert(mn,{"Extract",menuExtract})
  --table.insert(mn,{"Craft",menuCraft})
  table.insert(mn,{"Barrel Cnfg.",menuBarrels})

  bDraw()
end

-- Menu Barrels

function menuBarrels(page,filter)
  local page = page or 1
  local filter = filter or false
  
  currentPage = "barrels"
  mainMenu()
  
  table.insert(mn,{"Filter",function() menuBarrels(page,true) end})
  
  local clG = cG
  local clR = cR
  local crG = cG
  local crR = cR
  
  local left = page - 36
  if left < 1 then
    left = 1
    clG = cR
    clR = cG
  end
  local right = page + 36
  if right > #funcs.prph then 
    right = page
    crG = cR
    crR = cG
  end

  button.add("left","<","flash",1,4,1,th-6,clG,clR,cW,function() menuBarrels(left) end)
  button.add("righ",">","flash",funcs.termW - 1,4,funcs.termW,th-6,crG,crR,cW,function() menuBarrels(right) end)
  
  local cnt = 1
  for i=page,#funcs.prph do
    if cnt > 36 then break end
    local p = funcs.prph[i]
    if(peripheral.getType(p)=="mcp_mobius_betterbarrel") then
      local per = peripheral.wrap(p)
      local item = per.getStackInSlot(2)
      local ud = "?"
      
      for t=1,#barrels do
        if barrels[t].name == p then
          if barrels[t].chest == "DOWN" then
            ud = "V"
          elseif barrels[t].chest == "UP" then
            ud = "^"
          else
            ud = "-"
          end
          break
        end
      end
      
      if (filter == false) or (filter and ud == "?") then
        table.insert(mnh,{"[B" .. ud .. "] " .. item.qty .. " " .. item.display_name,function() editBarrel(p) end})
        cnt = cnt + 1
      end
    else
      if filter == false then
        table.insert(mnh,{peripheral.getType(p) .. " - " .. p,menuBarrels})
        cnt = cnt + 1
      end
    end
  end
  
  bDraw()
end

function editBarrel(bar)
  currentPage = "editBarrel"
  mainMenu()
  
  table.insert(mn,{"Back",menuBarrels})
  table.insert(mn,{"Save",saveBarrels})
  
  local p = peripheral.wrap(bar)
  local item = p.getStackInSlot(2)
  local ud = "???"
  local id = 0
  
  for t=1,#barrels do
    if barrels[t].name == bar then
      id = t
      ud = barrels[t].chest
      break
    end
  end
  
  button.add("up","Up","flash",5,15,15,17,cG,cR,cW,function() changeBarrel(id,"UP",bar,item.display_name) end)
  button.add("down","Down","flash",5,19,15,21,cG,cR,cW,function() changeBarrel(id,"DOWN",bar,item.display_name) end)

  bDraw()
   
  term.setCursorPos(1,5)
  print("  Selected side : " .. bar)
  print("  Type          : " .. peripheral.getType(bar))
  print("  Item inside   : " .. item.display_name)
  print("  Output side   : " .. ud)
end

function changeBarrel(id,side,nme,itm)
  if id > 0 then
    table.remove(barrels,id)
  end
  
  table.insert(barrels,{chest=side,name=nme,item=itm})
  editBarrel(nme)
end

function saveBarrels()
  saveConfigs()
  funcs.printStatus("Saved configs!")
end

-- Menu Craft

function menuCraft()
  currentPage = "craft"
  mainMenu()
  
  --button.add("new","New cnf","flash",10,10,20,12,cG,cR,cW,newRecipeCnf)
  --table.insert(mn,{"Drop water",dropWater})
  
  local maxRows = (funcs.termH - 10) / 5
  local row = 0
  local col = 0
  local t = 0
  
  for t = 1,#recipes do
    row = row + 1
    if row > maxRows then
      row = 1
      col = col + 1
    end
    
    --button.add(t,recipes[t].name,"flash",5+(col*35),5+(row*5),38+(col*35),7+(row*5),cR,cG,cW,function() craftRecipe(t) end)
    table.insert(mnh,{recipes[t].name,function() craftRecipe(t) end})
  end
  
  table.insert(mn,{"New Recipe",newRecipe})
  
  bDraw()
end

function newRecipe(keep,page)
  local page = page or 1
  local clG = cG
  local clR = cR
  local crG = cG
  local crR = cR
  
  local left = page - 27
  if left < 1 then
    left = 1
    clG = cR
    clR = cG
  end
  local right = page + 27
  if right > #barrels then 
    right = page
    crG = cR
    crR = cG
  end
  
  currentPage = "newRecipe"
  mainMenu()
  
  if keep == nil then newRec = {} end
  
  button.add("left","<","flash",1,4,2,th-6,clG,clR,cW,function() newRecipe(true,left) end)
  button.add("righ",">","flash",112,4,113,th-6,crG,crR,cW,function() newRecipe(true,right) end)
  
  for t=page,#barrels do
    if t-page > 27 then break end
    if peripheral.getType(barrels[t].name) == "mcp_mobius_betterbarrel" then
      table.insert(mnh,{barrels[t].item,function() addNewIngredient(barrels[t].item) end})
    end
  end
  
  table.insert(mn,{"Clear Recipe",newRecipe})
  table.insert(mn,{"Save Recipe",saveRecipe})
  
  bDraw()
  
  term.setCursorPos(120,5)
  print("New recipe ingredients ...")
  term.setCursorPos(120,7)
  if #newRec == 0 then
    print(" - Nothing selected")
  else
    for t=1,#newRec do
      term.setCursorPos(120,6+t)
      print(" - [" .. newRec[t].qty .. "]" .. newRec[t].name)
    end
  end
end

function saveRecipe()
  local r = {name="New recipe",recipe=newRec}
  table.insert(recipes,r)
  saveConfigs()
  menuCraft()
end

function addNewIngredient(ing)
  local found = false
  if #newRec > 0 then
    for t=1,#newRec do
      if newRec[t].name == ing then
        newRec[t].qty = newRec[t].qty + 1
        found = true
        break
      end
    end
  end
  
  if found ~= true then
    table.insert(newRec,{qty=1,name=ing})
  end
  newRecipe(true)
end

function craftRecipe(nr)
  term.clear()
  funcs.printStatus("Recipe nr. " .. nr .. " [" ..
    recipes[nr].name .. "]")
  
  local r = recipeList(recipes[nr].recipe)
  
  term.setCursorPos(1,3)
  print("  Collecting ingredients...")
  for t = 1,#r do
    print("   [" .. r[t].qty .. "] " .. r[t].name)
  end
  
  -- Craft Runes
  for t = 1,#r do
    if r[t].name:find("Rune") then
      for tt = 1,r[t].qty do
        craftRune(r[t].name)
      end
    end
  end

  -- Craft Mana Petals
  for t = 1,#r do
    if r[t].name:find("Mana") then
      for tt = 1,r[t].qty do
        local c = petalToColor(r[t].name)
        --print("Mystical: " .. convertToMystical(c))
        --print("Magic   : " .. convertToMystical(c, true)) 
        craftManaPetal(c)
      end
    end
  end
  
  for t = 1,#r do
    if r[t].name:find("Mystical") then
      for tt = 1,r[t].qty do
        askMysticalPetal(petalToColor(r[t].name), r[t].qty)
      end
    end
  end
  
  -- Craft flower
  print("Sleeping for 5 seconds to wait for items...")
  sleep(5)
  local p = peripheral.wrap("left")
  local seed = false
  local found = false
  local id = -1
  
  for t = 1,#r do
    found = false
    if r[t].name == "Seeds" then
      seed = true
    else
      for tt=1,p.getInventorySize() do
        local item = p.getStackInSlot(tt)
        if item ~= nil then
          if item.display_name == r[t].name then
            id = tt
            break
          end
        end
      end
      
      if id >= 0 then
        x = p.pushItem("DOWN",id,r[t].qty)        
        print("Ingredient found, " .. x .. " pushed down")
        sleep(1)
      else
        print("Ingredient not found")
      end   
    end
  end
  -- 4. Export seed
  
  if seed then
    print("Dropping seeds...")
    extractItem("Seeds")
    waitForItem("left","Seeds",1,"DOWN")
    
  end
  -- 5. Wait for pickup
  -- 6. Drop water
  sleep(2)
  dropWater()
  -- 7. Done
  print("Done!")
  sleep(1)
  menuCraft()  
end

function recipeList(recipe)
--  local r = {}
  return recipe
end

function getRecipe(name)
  for t = 1,#recipes do
    if recipes[t].name == name then
      return recipes[t]
    end
  end
  return nil
end

function craftRune(name)
  local rune = getRecipe(name)
  -- Craft Runes
  for t = 1, #rune.recipe do
    if rune.recipe[t]:find"Rune" then
      for tt = 1, rune.recipe[t].qty do
        craftRune(rune.recipe[t])
      end
    end
  end
  
  -- Craft Mana Petals
  for t = 1, #rune.recipe do
    if rune.recipe[t]:find"Magic" then
      for tt = 1, rune.recipe[t].qty do
        local c = petalToColor(rune.recipe[t].name)
        craftManaPetal(c)
      end
    end
  end
  
  -- Get all materials
  local p = peripheral.wrap("left")
  for t = 1, #rune.recipe do
    for tt = 1, p.getInventorySize() do
      local item = p.getStackInSlot(tt)
      if item ~= nil then
      
      end
    end
  end
end

function askMysticalPetal(colo, amount)
  local amount = amount or 1
  local myp = convertToMystical(colo)
  print("Extracting petal " .. colo)
  extractPetal(colo)
  waitForItem("left",myp,amount)
end

function craftManaPetal(colo)
  local myp = convertToMystical(colo)
  local map = convertToMystical(colo,true)
  funcs.printStatus("Crafting - " .. map)
  
  -- 1. Export petal
  print("Extracting " .. colo .. " petal")
  extractPetal(colo)
  -- 2. Export petal to top
  print("Waiting for " .. myp)
  waitForItem("left",myp,1,"UP")
  print("Waiting for " .. map)
  waitForItem("left",map,1)
  
  -- 3. Wait for item
  -- 4. Done
  
  
end

function waitForItem(side,item,amount,export)
  local export = export or nil
  local p = peripheral.wrap(side)
  local found = false
  local id = -1
  
  while found == false do
    for i = 1,p.getInventorySize() do
      local it = p.getStackInSlot(i)
      if it ~= nil then
        if it.display_name == item then
          found = true
          id = i
          break
        end
      end
    end
    sleep(.1)
  end
  
  if export ~= nil then
    p.pushItem(export,id,amount)
  end
end


function newRecipeCnf()
  local recipes = {
    {name="Endoflame",
    recipe={{
        qty=1,
        name="Mystical Licht Gray Petal"
      },{
        qty=1,
        name="Mystical Red Petal"
      }}
    }
  }
  
  funcs.save(recipes, recipeFile)
end

function dropWater()
  local p = peripheral.wrap("left")
  
  term.setCursorPos(1,2)
  for i = 1,p.getInventorySize() do
    local item = p.getStackInSlot(i)
    
    if item ~= nil then
      if item.display_name == "Water Bucket" then
        local x = p.pushItem("down",i,1)
        if x == 0 then
          funcs.printStatus("No bucket dropped!")
        else
          funcs.printStatus(x .. " bucket(s) dropped")
        end
        break
      end
    end
  end
end

-- Menu Extract

function menuExtract()
  currentPage = "extract"
  mainMenu()
  
  local maxRows = (funcs.termH - 10) / 5
  local row = 0
  local col = 0
  
  t = 1
  while t <= 32768 do
    row = row + 1
    if row > maxRows then
      row = 1
      col = col + 1
    end
    local colo = funcs.getColor(t)
    local item = colo .. "..." .. convertToMystical(colo)
    --button.add("color" .. t,item,"flash",5+(col*35),5+(row*5),38+(col*35),7+(row*5),cR,cG,cW,
    table.insert(mnh,{item,function() extractPetal(colo) end})
    t = t * 2
  end
  bDraw()
end

function extractPetal(colo)
  for t=1,#barrels do
    funcs.printStatus("[" .. colo .. "] Finding " .. convertToMystical(colo))
    if barrels[t].item == convertToMystical(colo) then
      extractItemFromBarrel(barrels[t].name,barrels[t].chest)
    end
  end
end

function extractItem(item)
  funcs.printStatus("Trying to find " .. item .. " in barrels.")
  for t=1,#barrels do
    if barrels[t].item == item then
      extractItemFromBarrel(barrels[t].name,barrels[t].chest)
    end
  end
end

function extractItemFromBarrel(b,s)
  funcs.printStatus("Extr.: " .. b .. " Side: " .. s)
  local barrel = peripheral.wrap(b)
  local x = barrel.pushItem(s,2,1)
  sleep(1)
  funcs.printStatus("Extracted " .. x)
end

function toUpper(txt)
  return txt:gsub("^%l", string.upper)
end

function split(str, sep)
  local sep, fields = sep or ":", {}
  local pattern = string.format("([^%s]+)", sep)
  str:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

function petalToColor(name)
  local colo = ""
  if name:find"Petal" then
    local sn = split(name, " ")
    if name:find("Mystical") then
      for t=2,#sn - 1 do
        if t > 2 then colo = colo .. " " end
        colo = colo .. sn[t]
      end
    elseif name:find("Mana") then
      for t=1,#sn-2 do
        if t > 1 then colo = colo .. " " end
        colo = colo .. sn[t]
      end
    end
  else
    colo = ""
  end
  return colo
end

function convertToMystical(colo,magic)
  local conv = "Mystical "
  if magic ~= nil then conv = "" end
  local pre = colo:match".*%u"
  local sub = colo:match"%u.*"
  
--  if sub ~= nil then
--    pre = string.sub(pre,1,string.len(pre) - 1)
--    conv = conv .. toUpper(pre) .. " " .. toUpper(sub)
--  else
--    conv = conv .. toUpper(colo)
--  end
  conv = conv .. colo
  
  if magic ~= nil then conv = conv .. " Mana" end
  conv = conv .. " Petal"
  
  --print("[" .. conv .. "]")
  
  return conv
end

-- Menu Tests

function menuTests()
  currentPage = "tests"
  mainMenu()

  table.insert(mn,{"Perps",perpsTest})

  bDraw()
end

function perpsTest()
  term.setCursorPos(1,3)
  funcs.printTableIdent(funcs.prph, " - ")
end

-- Start it up!
loadConfigs()

versionRequest = http.get("https://raw.githubusercontent.com/dadaemon/LunaOS/master/recipes.ver")
recipeVersion = versionRequest.readAll()

lrVersion = recipeFile.version or "0.0"

print("Loaded Recipe version " .. lrVersion)
print("Latest Recipe version " .. recipeVersion)

if lrVersion ~= recipeVersion then
	downloadFile("https://raw.githubusercontent.com/dadaemon/LunaOS/master/cnf/recipes", "./LunaOS/cnf/recipes")
	sleep(1)
	loadConfigs()
end

sleep(1)

menuHome()

while exitLunaOS == false do
  button.check()
  --funcs.fps()
end

-- End LunaOS
funcs.exitLunaOS()