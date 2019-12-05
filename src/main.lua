math.randomseed(os.time())
math.random()
math.random()
math.random()

--[[
Next: Helper functions
]]

local function indefinite_article(word)
  local vocals = {
    a = true,
    e = true,
    i = true,
    o = true,
    u = true,
  }

  -- guess the indefinite article by looking at the first
  -- letter of the first word
  local first_letter = string.sub(word, 1, 1)
  if vocals[first_letter] then
    return "an"
  else
    return "a"
  end
end

-- chooses one from a number of nodes, based on the number of options in each
-- node
local function choose(...)
  local n_options = 0
  for n=1,select("#", ...) do
    n_options = n_options + select(n, ...).n_options
  end

  if n_options == 0 then return nil end

  local i = math.random(1, n_options)
  for n=1,select("#", ...) do
    local node = select(n, ...)
    i = i - node.n_options
    if i <= 0 then
      return node
    end
  end
  assert(false, "This should never be reached")
end

-- enumerates all options of a node, and returns them in a sequence
local function enumerate(node)
  local t = {}
  local i = 0
  return node.enumerate(t, i)
end

local function new_node(t)
  local default = {
    n_options = 0,
    collapse = function() return "undefined collapse function" end
  }
  for k, v in pairs(default) do
    t.k = t.k or v
  end

  return setmetatable(t, {
                        -- Add two leafs, forming their conjunction
                        __add = function(l1, l2)
                          local n_options = l1.n_options + l2.n_options
                          return new_node {
                            n_options = n_options,
                            collapse = function()
                              -- collapse one of the child nodes
                              return choose(l1, l2).collapse()
                            end,
                            enumerate = function(t, i)
                              l1.enumerate(t, i)
                              l2.enumerate(t, i + l1.n_options)
                            end,
                          }
                        end,
                        __mul = function(l1, l2)
                          local n_options = l1.n_options * l2.n_options
                          return new_node {
                            n_options = n_options,
                            collapse = function()
                              return {l1.collapse(), l2.collapse()}
                            end,
                            enumerate = function(t, i)
                              local t1 = enumerate(l1)
                              local t2 = enumerate(l2)
                              for i1 = 1, l1.n_options do
                                for i2 = 1, l2.n_options do
                                  t[i] = {t1[i1], t2[i2]}
                                  i = i + 1
                                end
                              end
                            end,
                          }
                        end,
  })
end

local function leaf(word)
  return new_node {
    collapse = function() return word end,
    n_options = 1,
    enumerate = function(t, i)
      t[i] = word
    end,
  }
end

--[[
Next: the content of the generator. Items, locations, people, etc.
]]

local personal_item =
  leaf "sword" +
  leaf "amulet" +
  leaf "helmet" +
  leaf "bracelet" +
  leaf "shield" +
  leaf "battle axe"

local you = leaf {
  word = leaf "you",
  pronoun = leaf "you",
  possessive_pronoun = leaf "your",
}

local group = you

-- Genders

local genders = {
  male = "male",
  female = "female",
  neutral = "neutral",
  other = "other",
}

-- Relations between persons

local father = leaf {
  word = leaf "father",
  pronoun = leaf "he",
  possessive_pronoun = leaf "his",
  subject_gender = genders.male,
}

local mother = leaf {
  word = leaf "mother",
  pronoun = leaf "she",
  possessive_pronoun = leaf "her",
  subject_gender = genders.female,
}

local son = leaf {
  word = leaf "son",
  pronoun = leaf "he",
  possessive_pronoun = leaf "his",
  subject_gender = genders.male,
}

local daughter = leaf {
  word = leaf "daughter",
  pronoun = leaf "she",
  possessive_pronoun = leaf "her",
  subject_gender = genders.female,
}

local child = leaf {
  word = leaf "child",
  pronoun = leaf "they",
  possessive_pronoun = leaf "their",
  subject_gender = genders.neutral,
}

local husband = leaf {
  word = leaf "husband",
  pronoun = leaf "he",
  possessive_pronoun = leaf "his",
  subject_gender = genders.male,
}

local wife = leaf {
  word = leaf "wife",
  pronoun = leaf "she",
  possessive_pronoun = leaf "her",
  subject_gender = genders.female,
}

local partner = leaf {
  word = leaf "partner",
  pronoun = leaf "they",
  possessive_pronoun = leaf "their",
  subject_gender = genders.neutral,
}

-- define the counterparts in those relations
wife.counterpart = husband
husband.counterpart = wife
partner.counterpart = partner

child.counterpart = mother + father
daughter.counterpart = mother + father
son.counterpart = mother + father

mother.counterpart = child + son + daughter
father.counterpart = child + son + daughter

local family_relations_across_generations =
  father + mother + son + daughter + child

local family_relations =
  family_relations_across_generations + husband + wife

local location =
  leaf "graveyard" +
  leaf "desert" +
  leaf "battlefield"

local dangerous_property =
  leaf "haunted" +
  leaf "cursed" +
  leaf "forbidden"

local dangerous_location =
  dangerous_property * location +
  leaf "abandoned" * (leaf "village" + leaf "farm")

--[[
Next: The functions that define the adventures.
]]

local function lost_item_quest()
  local group = group.collapse()
  local relative = family_relations.collapse()
  local item = personal_item.collapse()
  local dangerous_property, location = unpack(dangerous_location.collapse())

  return string.format("%s %s's %s was lost in %s %s %s. %s set out to explore the %s and retrieve %s %s",
                       group.possessive_pronoun.collapse(),
                       relative.word.collapse(),
                       item,
                       indefinite_article(dangerous_property),
                       dangerous_property, location,
                       group.word.collapse(), location,
                       relative.possessive_pronoun.collapse(),
                       item)
end

for i=1,10 do
  print(lost_item_quest())
end
