require("/scripts/util.lua")
require("/scripts/quest/text_generation.lua")

function noteTag(tagSuffix)
  return quest.questId().."-"..tagSuffix
end

function generateTaggedNoteItem(tagSuffix, templates, title)
  local textGenerator = currentQuestTextGenerator()
  local note = generateNoteItem(templates, title, textGenerator)
  note.parameters.questTag = noteTag(tagSuffix)
  return note
end

function generateParcelText(templates)
  local textGenerator = currentQuestTextGenerator()
  local template = templates[math.random(#templates)]
  return textGenerator:substituteTags(template)
end
