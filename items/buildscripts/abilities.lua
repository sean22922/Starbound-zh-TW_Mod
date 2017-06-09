require "/scripts/util.lua"
require "/scripts/staticrandom.lua"

local abilityTablePath = "/items/buildscripts/weaponabilities.config"
local abilities = nil

function getAbilitySourceFromType(abilityType)
  if not abilityType then return nil end
  if not abilities then
    abilities = root.assetJson(abilityTablePath)
  end
  return abilities[abilityType]
end

-- abilitySlot is either "alt" or "primary"
function getAbilitySource(config, parameters, abilitySlot)
  local typeKey = abilitySlot .. "AbilityType"
  local abilityType = parameters[typeKey] or config[typeKey]

  return getAbilitySourceFromType(abilityType)
end

-- Adds the new ability to the config (modifying it)
-- abilitySlot is either "alt" or "primary"
function addAbility(config, parameters, abilitySlot, abilitySource)
  if abilitySource then
    local abilityConfig = root.assetJson(abilitySource)

    -- Rename "ability" key to primaryAbility or altAbility
    local abilityType = abilityConfig.ability.type
    abilityConfig[abilitySlot .. "Ability"] = abilityConfig.ability
    abilityConfig.ability = nil

    -- Allow parameters in the activeitem's config to override the abilityConfig
    local newConfig = util.mergeTable(abilityConfig, config)
    util.mergeTable(config, newConfig)

    parameters[abilitySlot .. "AbilityType"] = abilityType
  end
end

-- Determines ability from config/parameters and then adds it.
-- abilitySlot is either "alt" or "primary"
-- If builderConfig is given, it will randomly choose an ability from
-- builderConfig if the ability is not specified in the config/parameters.
function setupAbility(config, parameters, abilitySlot, builderConfig, seed)
  seed = seed or parameters.seed or config.seed or 0

  local abilitySource = getAbilitySource(config, parameters, abilitySlot)
  if not abilitySource and builderConfig then
    local abilitiesKey = abilitySlot .. "Abilities"
    if builderConfig[abilitiesKey] and #builderConfig[abilitiesKey] > 0 then
      local abilityType = randomFromList(builderConfig[abilitiesKey], seed, abilitySlot .. "AbilityType")
      abilitySource = getAbilitySourceFromType(abilityType)
    end
  end

  if abilitySource then
    addAbility(config, parameters, abilitySlot, abilitySource)
  end
end
