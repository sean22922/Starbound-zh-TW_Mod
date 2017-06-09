function init()
  storeData(config.getParameter("storedStorage"), config.getParameter("storedTemplates"))

  message.setHandler("requestSignDrop", function(_, _)
      requestSignDrop()
    end)
  message.setHandler("storeData", function(_, _, storageInput, templatesInput)
      storeData(storageInput, templatesInput)
    end)
  message.setHandler("putInChest", function(_, _, item, offset)
      putInChest(item, offset)
    end)
end

function update(dt)
  if matchingCabinet == nil or world.entityExists(matchingCabinet) == false then
    local matchingCabinetList = world.objectQuery({object.position()[1]+7,object.position()[2]},1)
    for i,j in ipairs(matchingCabinetList) do
      if world.entityName(j) == "signdispenser" then matchingCabinet = j end
    end
  end
end

function requestSignDrop()
  local item = world.containerItemAt(matchingCabinet,8)
  if item ~= nil and (item.name == "customsign" or item.name == "wiredcustomsign") then
    world.setProperty("SignStoreDrop", item.parameters)
  end
end

function storeData(storageInput, templatesInput)
  storage.heldStorage = tablecopy(storageInput)
  storage.heldTemplates = tablecopy(templatesInput)
end

function putInChest(item, offset)
  world.containerPutItemsAt(matchingCabinet, item, offset)
end

function tablecopy(input)
  if input == nil then return nil end
  if type(input) ~= "table" then
    local newinput = input
    return newinput
  end
  local newtab = {}
  for i,j in pairs(input) do
    newtab[i] = tablecopy(j)
  end
  return newtab
end
