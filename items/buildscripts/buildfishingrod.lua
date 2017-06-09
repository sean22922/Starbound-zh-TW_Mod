function build(directory, config, parameters, level, seed)
  config.tooltipFields = config.tooltipFields or {}

  config.tooltipFields.reelNameLabel = parameters.reelName or config.reelName
  config.tooltipFields.reelIconImage = parameters.reelIcon or config.reelIcon

  config.tooltipFields.lureNameLabel = parameters.lureName or config.lureName
  config.tooltipFields.lureIconImage = parameters.lureIcon or config.lureIcon

  return config, parameters
end

function getRotTimeDescription(rotTime)
  local descList = root.assetJson("/items/rotting.config:rotTimeDescriptions")
  for i, desc in ipairs(descList) do
    if rotTime <= desc[1] then return desc[2] end
  end
  return descList[#descList]
end
