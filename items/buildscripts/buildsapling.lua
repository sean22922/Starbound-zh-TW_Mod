require "/scripts/util.lua"

function build(directory, config, parameters, level, seed)
  config.inventoryIcon = jarray()

  table.insert(config.inventoryIcon, {
      image = string.format("%s?hueshift=%s", util.absolutePath(root.treeStemDirectory(parameters.stemName), "saplingicon.png"), parameters.stemHueShift or 0)
    })

  if parameters.foliageName then
    table.insert(config.inventoryIcon, {
        image = string.format("%s?hueshift=%s", util.absolutePath(root.treeFoliageDirectory(parameters.foliageName), "saplingicon.png"), parameters.foliageHueShift or 0)
      })
  end

  return config, parameters
end
