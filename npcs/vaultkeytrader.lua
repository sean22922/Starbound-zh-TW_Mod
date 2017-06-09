function extraInit()
  message.setHandler("openVaults", function ()
      world.setUniverseFlag("vaultsopen")
    end)
end

function handleInteract(args)
  if world.universeFlagSet("vaultsopen") then
    return { "ScriptPane", "/interface/scripted/keytrader/keytradergui.config" }
  else
    sayToEntity({
      dialogType = "dialog.unavailable",
      dialog = nil,
      entity = args.sourceId,
      tags = {}
    })
  end
end


function QuestParticipant:updateOfferedQuests()
  if not world.universeFlagSet("vaultsopen") then
    local offeredQuests = config.getParameter("offeredQuests", jarray())
    npc.setOfferedQuests(offeredQuests)
  end
end
