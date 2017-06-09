require "/quests/scripts/portraits.lua"
require "/quests/scripts/questutil.lua"

function init()
  setPortraits()
  self.description = config.getParameter("description")

  if self.description then
    quest.setObjectiveList( { { self.description, false } } )
  end

  quest.setCanTurnIn(true)
end

function questComplete()
  setPortraits()
  questutil.questCompleteActions()
end
