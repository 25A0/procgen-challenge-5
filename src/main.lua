local inspect = require("src.inspect")

math.randomseed(os.time())
math.random()
math.random()
math.random()

--[[
Next: Helper functions
]]

-- this function takes a table (or a value), and flattens it,
local function flatten(t)
  local function flatten_recursively(tab, res, next_index)
    if type(tab) == "table" then
      for _, v in ipairs(tab) do
        next_index = flatten_recursively(v, res, next_index)
      end
    else
      res[next_index] = tab
      next_index = next_index + 1
    end
    return next_index
  end


  local res = {}
  flatten_recursively(t, res, 1)
  return res
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

local default_node = {
  n_options = 1,
  collapse = function() return "undefined collapse function" end
}

local function is_node(t)
  if type(t) ~= "table" then
    return false
  end
  for k in pairs(default_node) do
    if not t[k] then return false end
  end
  return true
end

local leaf, null_leaf, empty_leaf

local function new_node(t)
  for k, v in pairs(default_node) do
    t.k = t.k or v
  end

  return setmetatable(t, {
                        -- Add two leafs, forming their conjunction
                        __add = function(l1, l2)
                          if l1 == null_leaf then
                            return l2
                          elseif l2 == null_leaf then
                            return l1
                          end
                          local n_options = l1.n_options + l2.n_options
                          return new_node {
                            n_options = n_options,
                            collapse = function(...)
                              -- collapse one of the child nodes
                              return choose(l1, l2).collapse(...)
                            end,
                          }
                        end,
                        __mul = function(l1, l2)
                          if l1 == null_leaf or l2 == null_leaf then
                            return null_leaf
                          end
                          local n_options = l1.n_options * l2.n_options
                          return new_node {
                            n_options = n_options,
                            collapse = function(...)
                              return {l1.collapse(...), l2.collapse(...)}
                            end,
                          }
                        end,
                        __concat = function(l1, l2)
                          l1 = is_node(l1) and l1 or leaf(l1)
                          l2 = is_node(l2) and l2 or leaf(l2)
                          local n_options = l1.n_options * l2.n_options
                          return new_node {
                            n_options = n_options,
                            collapse = function(...)
                              return l1.collapse(...) .. l2.collapse(...)
                            end,
                          }
                        end,
  })
end

-- This leaf is a null node. It can be collapsed, but will yield no result.
-- It can be used as a neutral element when adding nodes.
null_leaf = new_node {
  n_options = 0,
  collapse = function() return nil end,
}

-- This leaf is an empty node. It can be collapsed, and will yield the empty
-- string. It can be used as a neutral element when multiplying nodes.
empty_leaf = new_node {
  n_options = 1,
  collapse = function() return "" end,
}

leaf = function(word)
  assert(type(word) == "string")

  return new_node {
    collapse = function()
      return word
    end,
    n_options = 1,
  }
end

-- This node formats the given fstring with the values of the given node.
-- Example usage:
--
-- format_node("I am %s", leaf "hungry" + leaf "thirsty").collapse()
-- yields "I am hungry" or "I am thirsty".
--
-- format_node("He wore a %s %s", (leaf "red" + leaf "brown"), (leaf "jacket" + leaf "scarf")).collapse()
-- yields one of:
-- "He wore a red jacket"
-- "He wore a brown jacket"
-- "He wore a red scarf"
-- "He wore a brown scarf"
--
-- Any patterns of the form ":key:" will be populated with the corresponding
-- value in the context's store. For example:
--
-- (
--   store(leaf "blue" + leaf "black", "color") ..
--   format_node("My favourite color is :color:")
-- ).collapse(new_context())
--
-- yields "My favourite color is blue" or "My favourite color is black"
local function format_node(fstring, ...)
  -- convert the fstring into a node if necessary
  local fstring_node = is_node(fstring) and fstring or leaf(fstring)
  local n_options = fstring_node.n_options
  local nodes = {...}
  for _, n in ipairs(nodes) do
    n_options = n_options * n.n_options
  end
  return new_node {
    n_options = n_options,
    collapse = function(context)
      local v = {}
      for i, n in ipairs(nodes) do
        v[i] = n.collapse(context)
      end
      -- first populate the formatstring with the passed variables
      local s = string.format(fstring_node.collapse(context), unpack(v))
      -- then replace any :key: instances with values from the store
      s = string.gsub(s, ":([_%a][_%a%d ]*):", function(key)
                    assert(context and context.store)
                    return context.store[key] or ""
      end)
      return s
    end,
  }
end

local function filter_node(fun, node, ...)
  local args = {...}
  return new_node {
    n_options = node.n_options,
    collapse = function(...)
      return fun(node.collapse(...), unpack(args))
    end,
  }
end

--[[ THE CONTEXT

When collapsing nodes, there's a context shared by all nodes that are
being collapsed.
The context is a sequence of literals.

When pushing elements to the context, they are appended to the context. When
popping elements from the context, they are removed from the end of the context, by
default.

There are also functions to peek elements without removing them, to clone
elements, and to drop elements without returning them.

]]

local function new_context()
  return {
    store = {}
  }
end

local function push_store()
  return new_node {
    n_options = 1,
    collapse = function(context)
      assert(context)
      context.store = {
        __parent_store = context.store,
      }
      return ""
    end,
  }
end

local function pop_store()
  return new_node {
    n_options = 1,
    collapse = function(context)
      assert(context)
      context.store = assert(context.store.__parent_store, "more pops than pushs")
      return ""
    end,
  }
end

-- the raw stack operations
local stack_ops = {
  push = function(context, i, v)
    return table.insert(context, i or (#context + 1), v)
  end,
  pop = function(context, i)
    return table.remove(context, i or #context)
  end,
  peek = function(context, i)
    return context[i or #context]
  end,
  drop = function(context, i)
    return table.remove(context, i or #context)
  end,
  clone = function(context, i)
    return table.insert(context, assert(context[i or #context]))
  end,
  swap = function(context, i, j)
    i, j = i or #context, j or #context - 1
    context[i], context[j] = context[j], context[i]
  end,
}

-- collapses the given node, and then pushes the resulting item
-- onto the context, and then returns the empty string
local push = function(node, i)
  return new_node {
    n_options = node.n_options,
    collapse = function(context)
      assert(context)
      stack_ops.push(context, i, node.collapse(context))
      return ""
    end,
  }
end

-- pops the ith, or the top item off the context
local pop = function(i)
  return new_node {
    n_options = 1,
    collapse = function(context)
      assert(context)
      return assert(stack_ops.pop(context, i))
    end,
  }
end

-- returns the ith, or the top item of the context, but doesn't remove it
local peek = function(i)
  return new_node {
    n_options = 1,
    collapse = function(context)
      assert(context)
      return assert(stack_ops.peek(context, i))
    end,
  }
end

-- removes the ith, or the top item off the context and returns the empty string
local drop = function(i)
  return new_node {
    n_options = 1,
    collapse = function(context)
      assert(context)
      assert(stack_ops.drop(context, i))
      return ""
    end,
  }
end

-- clones the ith, or the top item of the context and returns the empty string
local clone = function(i)
  return new_node {
    n_options = 1,
    collapse = function(context)
      assert(context)
      stack_ops.clone(context, i)
      return ""
    end,
  }
end

-- swaps the ith and jth, or the top two items of the context and returns the
-- empty string
local swap = function(i, j)
  return new_node {
    n_options = 1,
    collapse = function(context)
      assert(context)
      stack_ops.swap(context, i, j)
      return ""
    end,
  }
end

-- store(node, key): collapse the given node, and store the result in the store
-- under the given key.
--
-- store(key): pop the topmost item off the context, and store the result in the
-- store under the given key.
--
-- If key is a table of strings, then store will assume that the given node, or
-- the element at the top of the stack, will contain a table of strings, and will
-- map them one by one to the corresponding key.
local store = function(node, key)
  if not key then
    key = node
    node = nil
  end
  assert(key)
  return new_node {
    n_options = node and node.n_options or 1,
    collapse = function(context)
      assert(context and context.store)
      local to_store
      if node then
        -- collapse that node, and store the result on the context
        to_store = node.collapse(context)
      else
        -- pop the top-most value off the context
        to_store = stack_ops.pop(context)
      end
      if type(key) == "string" then
        context.store[key] = to_store
      elseif type(key) == "table" then
        for i, k in ipairs(key) do
          context.store[k] = to_store[i]
        end
      else
        error("Cannot handle key of type " .. type(key))
      end
      return ""
    end,
  }
end

local read = function(key)
  assert(key)
  assert(type(key) == "string")
  return new_node {
    n_options = 1,
    collapse = function(context)
      assert(context and context.store)
      return context.store[key]
    end,
  }
end

-- returns a node that is keyed with 1 or n elements of the context.
-- when collapsed, this node pops the first n elements off the
-- context, and returns something depending on those elements.
--
-- The given table tab will be indexed with the first element of the context.
-- if n is larger than one, then it is assumed that tab contains nested
-- tables, which are indexed with further elements of the context.
--
-- It is not obvious what the number of options should be for those
-- nodes. For the moment, they are set to 1, but that's not accurate.
local function keyed_node(tab, n)
  n = n or 1
  return new_node {
    n_options = 1,
    collapse = function(context)
      while n > 1 do
        tab = tab[stack_ops.pop(context)]
        n = n - 1
      end
      return tab[stack_ops.pop(context)].collapse(context)
    end,
  }
end

-- Tables can contain a special key "__default". Its value must be a string,
-- not a node. If a table doesn't have a key for a certain value, then that
-- table collapses to that default value, and to the empty string, otherwise.
local function map_to_node(node, ...)
  local tables = {...}
  if #tables == 0 then
    return new_node {
      n_options = node.n_options,
      collapse = function(...)
        return {node.collapse(...)}
      end,
    }
  end

  assert(is_node(node))

  -- Compute the number of options
  local default_key = "__default"
  local n_options = 0
  local options_per_key = {}
  for _, t in ipairs(tables) do
    for k, v in pairs(t) do
      if k == default_key then
        assert(type(v) == "string", "The default entry must be a string")
      else
        assert(is_node(v), "Values in the tables must be nodes. Use map_to_string otherwise.")
        options_per_key[k] = (options_per_key[k] or 1) * v.n_options
      end
    end
  end
  -- Finally, sum the options of all found keys.
  for _, v in pairs(options_per_key) do
    n_options = n_options + v
  end

  return new_node {
    n_options = n_options,
    collapse = function(...)
      local key = node.collapse(...)
      local result = {key}
      for _, t in ipairs(tables) do
        local n = t[key]
        local v
        if n then
          v = n.collapse(...)
        else
          v = t[default_key] or ""
        end
        table.insert(result, v)
      end
      return result
    end,
  }
end

local function map_to_string(node, t)
  -- The function can also be called as map_string(t),
  -- in which case we'll pop a value off the stack instead
  if not t then
    node, t = nil, node
  end

  local default_key = "__default"
  return new_node {
    n_options = node and node.n_options or 1,
    collapse = function(context, ...)
      -- collapse the node, or pop a value off the stack
      local key = node and node.collapse(context, ...) or stack_ops.pop(context)
      local v = t[key]
      if v then assert(type(v) == "string") end
      return v or t[__default_key] or ""
    end
  }
end

-- this function takes a node, and prefixes it
-- with a best guess for the correct indefinite article
local function prefix_a_an(node)
  local tab = setmetatable({}, {
      __index = function(_, key)
        assert(type(key) == "string")
        local vocals = {
          a = true,
          e = true,
          i = true,
          o = true,
          u = true,
        }

        -- guess the indefinite article by looking at the first
        -- letter of the first word
        local first_letter = string.sub(key, 1, 1)
        if vocals[first_letter] then
          return "an"
        else
          return "a"
        end
      end
  })

  return push(node) .. clone() .. map_to_string(tab) .. " " .. pop()
end

--[[
Next: the content of the generator. Items, locations, people, etc.
]]

local personal_item =
  leaf "sword" +
  leaf "amulet" +
  leaf "ring" +
  leaf "helmet" +
  leaf "bracelet" +
  leaf "shield" +
  leaf "battle axe" +
  leaf "dagger" +
  leaf "claymore" +
  null_leaf

local you = leaf "you"
local you_pronoun = leaf "you"
local you_possessive_pronoun = leaf "your"

local group = you

-- Genders

local gender = {
  male = leaf "male",
  female = leaf "female",
  neutral = leaf "neutral",
  other = leaf "other",
}

local genders = gender.male + gender.female + gender.neutral + gender.other

-- Relations between persons

local father = leaf "father"
local mother = leaf "mother"

local son = leaf "son"
local daughter = leaf "daughter"
local child = leaf "child"

local husband = leaf "husband"
local wife = leaf "wife"
local partner = leaf "partner"
local girlfriend = leaf "girlfriend"
local boyfriend = leaf "boyfriend"

local relations = father + mother + son + daughter + child + husband + wife + partner + girlfriend + boyfriend

--------

local pronoun_of_gender = {
  male = "he",
  female = "she",
  neutral = "they",
  other = "they",
}

local object_pronoun_of_gender = {
  male = "him",
  female = "her",
  neutral = "them",
  other = "them",
}

local possessive_pronoun_of_gender = {
  male = "his",
  female = "her",
  neutral = "their",
  other = "their",
}

local gender_of_relation = {
  father = "male",
  mother = "female",
  son = "male",
  daughter = "female",
  child = "neutral",
  brother = "male",
  sister = "female",
  sibling = "neutral",
  husband = "male",
  wife = "female",
  partner = "neutral",
  girlfriend = "female",
  boyfriend = "male",
}

local town_professions =
  leaf "blacksmith" +
  leaf "fisher" +
  leaf "logger" +
  leaf "hunter" +
  leaf "farmer" +
  leaf "stonemason" +
  leaf "carpenter" +
  leaf "priest" +
  leaf "innkeeper" +
  null_leaf

local professions =
  town_professions +
  leaf "armorer" +
  leaf "doctor" +
  leaf "tanner" +
  leaf "astronomer" +
  leaf "cartographer" +
  leaf "librarian" +
  leaf "monk" +
  null_leaf

-- Races
local dwarves = leaf "dwarves"
local elves = leaf "elves"
local dark_elves = leaf "dark elves"
local orks = leaf "orks"
local trolls = leaf "trolls"
local hobbits = leaf "hobbits"

-- This is used to describe that something belongs to that race:
-- An Elven sword. A Dwarven battle axe.
local adjective_for_race = {
  dwarves = leaf "dwarven",
  elves = leaf "elven",
  dark_elves = leaf "dark elf",
  orks = leaf "orkish",
  trolls = leaf "troll",
  hobbits = leaf "hobbit",
}

local individual_of_race = {
  dwarves = leaf "dwarf",
  elves = leaf "elf",
  dark_elves = leaf "dark elf",
  orks = leaf "ork",
  trolls = leaf "troll",
  hobbits = leaf "hobbit",
}

local friendly_races = dwarves + elves + hobbits
local unfriendly_races = dark_elves + orks + trolls
local races = friendly_races + unfriendly_races

local dragon = leaf "dragon"
local giant = leaf "giant"
local minotaur = leaf "minotaur"
local centaur = leaf "centaur"
local griffin = leaf "griffin"

local creatures =
  dragon +
  giant +
  minotaur +
  centaur +
  griffin +
  null_leaf

local body_part = {
  scales = leaf "scales",
  blood = leaf "blood",
  teeth = leaf "teeth",
  bones = leaf "bones",
  claws = leaf "claws",
  wings = leaf "wings",
  skin = leaf "skin",
  hair = leaf "hair",
  fur = leaf "fur",
  mane = leaf "mane",
  hooves = leaf "hooves",
  horns = leaf "horns",
  feathers = leaf "feathers",
  beak = leaf "beak",
}

local body_parts_of_creature = {
  dragon =
    body_part.scales +
    body_part.blood +
    body_part.teeth +
    body_part.bones +
    body_part.claws +
    body_part.wings +
    null_leaf,
  giant =
    body_part.blood +
    body_part.teeth +
    body_part.bones +
    body_part.hair +
    null_leaf,
  minotaur =
    body_part.blood +
    body_part.teeth +
    body_part.bones +
    body_part.fur +
    body_part.hooves +
    body_part.horns +
    null_leaf,
  centaur =
    body_part.blood +
    body_part.teeth +
    body_part.bones +
    body_part.fur +
    body_part.mane +
    body_part.hooves +
    null_leaf,
  griffin =
    body_part.blood +
    body_part.beak +
    body_part.bones +
    body_part.feathers +
    body_part.claws +
    null_leaf,
}

local location =
  leaf "graveyard" +
  leaf "desert" +
  leaf "battlefield" +
  leaf "tomb" +
  null_leaf

local dangerous_property =
  leaf "haunted" +
  leaf "cursed" +
  leaf "forbidden" +
  null_leaf

local dangerous_location =
  dangerous_property * location +
  leaf "abandoned" * (leaf "village" + leaf "farm")

--[[
Next: The functions that define the adventures.
]]

--[[
you stroll over the market, when
you are gambling in a tavern, when
you make your way through a busy street, when
you pass a group of strangers on a (forest/mountain) road, when
]]
local mead = leaf "mead"
local beer = leaf "beer"
local wine = leaf "wine"
local ale = leaf "ale"
local cider = leaf "cider"
local drinks = mead + beer + wine + ale + cider

local tavern_activities =
  leaf "gambling" +
  leaf "playing cards" +
  leaf "listening to a bard" +
  -- format_node("talking to some %s", friendly_races) +
  -- format_node("drinking %s", drinks) +
  null_leaf

-- these can be used to describe locations like roads, towns, villages
local landscape_description =
  leaf "forest" + leaf "mountain" + leaf "coastal" + leaf "rural" +
  leaf "lakeside" + leaf "riverside"

local quest_introduction_rural_social = format_node(
  leaf "you are %s, when" + leaf "while you are %s," + leaf "while %s,",
  format_node("passing a group of %s on a %s road",
              (friendly_races + leaf "strangers"), landscape_description) +
    null_leaf)

local quest_introduction_urban_social = format_node(
  leaf "you are %s, when" + leaf "while you are %s," + leaf "while %s,",
  null_leaf +
    leaf "strolling over the market" +
    leaf "making your way through a busy street" +
    format_node("%s in a tavern", tavern_activities) +
    null_leaf)

local lost_item_quest =
  -- a blacksmith approaches you. her father lost his sword in a haunted
  -- graveyard. she asks you to retrieve his sword.

  quest_introduction_urban_social .. " " ..

  -- "a blacksmith approaches you. "
  prefix_a_an(professions) .. " approaches you. " ..

  push_store() ..

  -- pick a random relation
  push(relations) .. clone() ..
  store("father") ..
  -- find the possessive pronoun for that relation
  push(map_to_string(gender_of_relation)) ..
  store(map_to_string(possessive_pronoun_of_gender), "his") ..

  -- pick a random gender
  push(gender.male + gender.female) .. clone() ..
  -- push the pronoun for this gender
  store(map_to_string(pronoun_of_gender), "she") ..
  -- push the possessive pronoun for this gender
  store(map_to_string(possessive_pronoun_of_gender), "her") ..

  -- pick a random personal item
  store(personal_item, "sword") ..

  store(dangerous_property, "haunted") ..
  store(location, "graveyard") ..

  format_node(":her: :father: lost :his: :sword: in a :haunted: :graveyard:. :she: asks you to travel to the :graveyard: and retrieve :his: :sword:.") ..
  pop_store()

local nesw = leaf "north" + leaf "east" + leaf "south" + leaf "west"

local vague_journey_destination =
  nesw + leaf "coast" + leaf "mountains" + leaf "capital"

local quantity_description =
  leaf "a lot of" + leaf "quite a few" + leaf "some" + leaf "a few" +
  leaf "a handful of" + leaf "plenty of"

local plundering_bandits_quest =
  -- While traveling to the coast, you spend the night in a little town. The
  -- townsfolk is hospitable, but something about this place feels odd. you
  -- notice a lot of broken windows, and one of the houses has burnt down.
  -- When you ask the local innkeeper about it, she tells you of plundering
  -- bandits that terrify the region. Will you hunt down the bandits, or carry
  -- on with your journey?

  format_node("while travelling to the %s, ", vague_journey_destination) ..
  "you spend the night in a little town. " ..
  "the people seem friendly, but something about this place feels odd. " ..
  "one of the " ..
  (leaf "houses" + leaf "stables" + leaf "windmills" + leaf "watermills") ..
  " has burnt down, and " ..
  format_node("you notice %s %s. ", quantity_description, (
                leaf "broken windows" + leaf "burnt cornfields"
  )) ..
  store(unfriendly_races + leaf "bandits", "bandits") ..
  "when you ask a local " .. town_professions .. " about it, " ..
  format_node("they tell you about plundering :bandits: that terrify the region. " ..
  "will you hunt down the :bandits:, or carry on with your journey?") ..
  empty_leaf

local hidden_treasure_quest =
  --[[

    After a day of traveling, you set up camp in a lush forest and start to collect firewood.
    Between the roots of a tree, you discover a small metal box, containing a letter.

    The text tells of a stash of gold, hidden in the mountains, and guarded by a mighty dragon.

  ]]

  (
    leaf "after a day of travelling, you set up camp in a lush forest. you just start to collect firewood, when you spot something odd. " +
    leaf "it is a cold, clear winter day, and you are hunting in a dense forest. you are preying on some deer, when you spot something odd. " +
      null_leaf
  ) ..

  store(leaf "between the roots of a tree" +
          leaf "hidden under some bushes" +
          leaf "hidden under a fallen tree" +
          leaf "hidden in a small cavity in a cliffside" +
          null_leaf,
        "between the roots of a tree") ..
  store(leaf "a small, metal box" +
          leaf "a small wooden box" +
          leaf "a small leather backpack" +
          leaf "a small metal tube" +
          null_leaf,
        "a small metal box") ..
  store(leaf "a letter" + leaf "a piece of parchment", "a letter") ..
  format_node(":between the roots of a tree:, you discover :a small metal box:, containing :a letter:. ") ..

  push(
    (leaf "a stash of" + leaf "a pile of") * (leaf "gold" + leaf "gemstones") +
    ("a " .. (leaf "valuable" + leaf "powerful") .. ", " .. (leaf "magical" + leaf "enchanted")) * personal_item
  ) ..
  store({"a stash of", "gold"}) ..
  store(leaf "in the mountains" +
          leaf "in a deep, abandoned mineshaft" +
          leaf "in the dungeons of an old castle ruin" +
          leaf "in the catacombs under the capital's large cathedral",
        "in the mountains") ..
  store(leaf "a mighty " + leaf "a gigantic " .. creatures, "a mighty dragon") ..
  format_node(leaf "the text tells of :a stash of: :gold:, hidden :in the mountains:, and guarded by :a mighty dragon:." +
                leaf "the text tells of :a stash of: :gold:, hidden :in the mountains:. :a mighty dragon: is said to guard the :gold:.")

local lifting_the_curse_quest =
  --[[
    the beloved king is cursed, and their health is fading by the day.
    the queen offers a generous reward for anyone able to lift the curse.

    you have been reading countless books, looking for ways to lift the curse.
    finally, on the third day, one of the books mentions a possible treatment.
    there is a nearly forgotten ritual that might be able to lift the curse,
    but it requires the scales of a dragon to be completed.
  ]]
  push(null_leaf +
         leaf "king" * leaf "queen" +
         leaf "queen" * leaf "king" +
         leaf "prince" * (leaf "king" + leaf "queen") +
         leaf "princess" * (leaf "king" + leaf "queen") +
         null_leaf) ..
  store({"king", "queen"}) ..
  push(leaf "is cursed" * leaf "lift the curse" +
         leaf "was poisoned" * leaf "stop the poison" +
         leaf "has fallen ill" * leaf "cure the illness") ..
  store({"is cursed", "lift the curse"}) ..
  format_node("the beloved :king: :is cursed:, and their health is fading by the day. the :queen: offers a generous reward for anyone able to :lift the curse:. ") ..
  push(
    leaf "reading countless books, looking" * leaf "books"+
      (
        (store(leaf "monks" + leaf "witches", "monks") ..
          format_node("discussing the symptoms with :monks: and herbalists, asking")) * read("monks")
  )) ..
  store({"reading countless books looking", "books"}) ..
  format_node("you have spent days :reading countless books looking: for ways to :lift the curse:. ") ..
  format_node("finally, on the third day, one of the :books: mentions a possible treatment. ") ..

    push(
      leaf "ritual" * (leaf "completing it" + leaf "performing it") +
        leaf "potion" * (leaf "brewing it" + leaf "preparing it")
    )..
    store({"ritual", "completing it"}) ..

    push(map_to_node(creatures, body_parts_of_creature)) ..
    store({"dragon", "scales"}) ..

  format_node("there is a nearly forgotten :ritual: that might be able to :lift the curse:, but :completing it: requires the :scales: of a :dragon:.")

local small_scale_quest = hidden_treasure_quest + lost_item_quest + plundering_bandits_quest + lifting_the_curse_quest
local medium_scale_quest = null_leaf
local large_scale_quest = null_leaf

local quest = small_scale_quest + medium_scale_quest + large_scale_quest

print("Number of quests:", quest.n_options)
for i=1,10 do
  print(quest.collapse(new_context()))
  print()
end
