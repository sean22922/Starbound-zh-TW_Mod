function init()
  animator.setGlobalTag("species", storage.species or "human")
end

function setSpecies(species)
  storage.species = species
  animator.setGlobalTag("species", species)
  return true
end
