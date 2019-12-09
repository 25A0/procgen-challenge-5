local inspect = require("src.inspect")

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
-- format_node("He wore a %s %s", (leaf "red" + leaf "brown") * (leaf "jacket" + leaf "scarf")).collapse()
-- yields one of:
-- "He wore a red jacket"
-- "He wore a brown jacket"
-- "He wore a red scarf"
-- "He wore a brown scarf"
--
-- Any patterns of the form ":key:" will be populated with the corresponding
-- value in the stack's store. For example:
--
-- (
--   store(leaf "blue" + leaf "black", "color") ..
--   format_node("My favourite color is :color:")
-- ).collapse(new_stack())
--
-- yields "My favourite color is blue" or "My favourite color is black"
local function format_node(fstring, node)
  -- convert the fstring into a node if necessary
  local fstring_node = is_node(fstring) and fstring or leaf(fstring)
  return new_node {
    n_options = (node and node.n_options or 1) * fstring_node.n_options,
    collapse = function(stack)
      local v = node and flatten({node.collapse(stack)}) or {}
      -- first populate the formatstring with the passed variables
      local s = string.format(fstring_node.collapse(stack), unpack(v))
      -- then replace any :key: instances with values from the store
      s = string.gsub(s, ":([_%a][_%a%d]*):", function(key)
                    assert(stack and stack.store)
                    return stack.store[key] or ""
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

--[[ THE STACK

When collapsing nodes, there's a stack shared by all nodes that are
being collapsed.
The stack is a sequence of literals.

When pushing elements to the stack, they are appended to the stack. When
popping elements from the stack, they are removed from the end of the stack, by
default.

There are also functions to peek elements without removing them, to clone
elements, and to drop elements without returning them.

]]

local function new_stack()
  return {
    store = {}
  }
end

local function push_store()
  return new_node {
    n_options = 1,
    collapse = function(stack)
      assert(stack)
      stack.store = {
        __parent_store = stack.store,
      }
      return ""
    end,
  }
end

local function pop_store()
  return new_node {
    n_options = 1,
    collapse = function(stack)
      assert(stack)
      stack.store = assert(stack.store.__parent_store, "more pops than pushs")
      return ""
    end,
  }
end

-- collapses the given node, and then pushes the resulting item
-- onto the stack, and then returns the empty string
local push = function(node, i)
  return new_node {
    n_options = node.n_options,
    collapse = function(stack)
      assert(stack)
      table.insert(stack, i or (#stack + 1), node.collapse(stack))
      return ""
    end,
  }
end

-- pops the ith, or the top item off the stack
local pop = function(i)
  return new_node {
    n_options = 1,
    collapse = function(stack)
      assert(stack)
      return assert(table.remove(stack, i or #stack))
    end,
  }
end

-- returns the ith, or the top item of the stack, but doesn't remove it
local peek = function(i)
  return new_node {
    n_options = 1,
    collapse = function(stack)
      assert(stack)
      return assert(stack[i or #stack])
    end,
  }
end

-- removes the ith, or the top item off the stack and returns the empty string
local drop = function(i)
  return new_node {
    n_options = 1,
    collapse = function(stack)
      assert(stack)
      assert(table.remove(stack, i or #stack))
      return ""
    end,
  }
end

-- clones the ith, or the top item of the stack and returns the empty string
local clone = function(i)
  return new_node {
    n_options = 1,
    collapse = function(stack)
      assert(stack)
      table.insert(stack, assert(stack[i or #stack]))
      return ""
    end,
  }
end

-- swaps the ith and jth, or the top two items of the stack and returns the
-- empty string
local swap = function(i, j)
  return new_node {
    n_options = 1,
    collapse = function(stack)
      assert(stack)
      i, j = i or #stack, j or #stack - 1
      stack[i], stack[j] = stack[j], stack[i]
      return ""
    end,
  }
end

-- store(node, key): collapse the given node, and store the result in the store
-- under the given key.
--
-- store(key): pop the topmost item off the stack, and store the result in the
-- store under the given key.
local store = function(node, key)
  if not key then
    key = node
    node = nil
  end
  assert(key)
  assert(type(key) == "string")
  return new_node {
    n_options = node and node.n_options or 1,
    collapse = function(stack)
      assert(stack and stack.store)
      local to_store
      if node then
        -- collapse that node, and store the result on the stack
        to_store = node.collapse(stack)
      else
        -- pop the top-most value off the stack
        to_store = table.remove(stack)
      end
      stack.store[key] = to_store
      return ""
    end,
  }
end

local read = function(key)
  assert(key)
  assert(type(key) == "string")
  return new_node {
    n_options = 1,
    collapse = function(stack)
      assert(stack and stack.store)
      return stack.store[key]
    end,
  }
end

-- returns a node that is keyed with 1 or n elements of the stack.
-- when collapsed, this node pops the first n elements off the
-- stack, and returns something depending on those elements.
--
-- The given table tab will be indexed with the first element of the stack.
-- if n is larger than one, then it is assumed that tab contains nested
-- tables, which are indexed with further elements of the stack.
--
-- It is not obvious what the number of options should be for those
-- nodes. For the moment, they are set to 1, but that's not accurate.
local function keyed_node(tab, n)
  n = n or 1
  return new_node {
    n_options = 1,
    collapse = function(stack)
      while n > 1 do
        tab = tab[table.remove(stack)]
        n = n - 1
      end
      return tab[table.remove(stack)].collapse(stack)
    end,
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
          return leaf "an"
        else
          return leaf "a"
        end
      end
  })

  return push(node) .. clone() .. keyed_node(tab) .. " " .. pop()
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
  leaf "battle axe" +
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

local relations = father + mother + son + daughter + child + husband + wife + partner

--------

local pronoun_of_gender = {
  male = leaf "he",
  female = leaf "she",
  neutral = leaf "they",
  other = leaf "they",
}

local possessive_pronoun_of_gender = {
  male = leaf "his",
  female = leaf "her",
  neutral = leaf "their",
  other = leaf "their",
}

local gender_of_relation = {
  father = gender.male,
  mother = gender.female,
  son = gender.male,
  daughter = gender.female,
  child = gender.neutral,
  brother = gender.male,
  sister = gender.female,
  sibling = gender.neutral,
  husband = gender.male,
  wife = gender.female,
  partner = gender.neutral,
}

local professions =
  leaf "blacksmith" +
  leaf "fisher" +
  leaf "logger" +
  leaf "armorer" +
  leaf "doctor" +
  leaf "hunter" +
  leaf "farmer" +
  leaf "tanner" +
  leaf "stonemason" +
  leaf "carpenter" +
  leaf "priest" +
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
you enjoy your evening mead in a tavern, when
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
  format_node("talking to some %s", friendly_races) +
  format_node(
    leaf "enjoying your evening %s" + leaf "drinking %s",
    drinks) +
  null_leaf

-- these can be used to describe locations like roads, towns, villages
local landscape_description =
  leaf "forest" + leaf "mountain" + leaf "coastal" + leaf "rural" +
  leaf "lakeside" + leaf "riverside"

local quest_introduction = format_node(
  leaf "you are %s, when" + leaf "while you are %s," + leaf "while %s,",
  null_leaf +
    leaf "strolling over the market" +
    leaf "making your way through a busy street" +
    format_node("%s in a tavern", tavern_activities) +
    format_node("passing a group of %s on a %s road",
                (friendly_races + leaf "strangers") * landscape_description) +
    null_leaf)

local lost_item_quest =
  -- a blacksmith approaches you. her father lost his sword in a haunted
  -- graveyard. she asks you to retrieve his sword.

  quest_introduction .. " " ..

  -- "a blacksmith approaches you. "
  prefix_a_an(professions) .. " approaches you. " ..

  push_store() ..

  -- pick a random relation
  push(relations) .. clone() ..
  store("father") ..
  -- find the possessive pronoun for that relation
  push(keyed_node(gender_of_relation)) ..
  store(keyed_node(possessive_pronoun_of_gender), "his") ..

  -- pick a random gender
  push(gender.male + gender.female) .. clone() ..
  -- push the pronoun for this gender
  store(keyed_node(pronoun_of_gender), "she") ..
  -- push the possessive pronoun for this gender
  store(keyed_node(possessive_pronoun_of_gender), "her") ..

  -- pick a random personal item
  store(personal_item, "sword") ..

  store(dangerous_property, "haunted") ..
  store(location, "graveyard") ..

  format_node(":her: :father: lost :his: :sword: in a :haunted: :graveyard:. :she: asks you to travel to the :graveyard: and retrieve :his: :sword:.") ..
  pop_store()

local small_scale_quest = null_leaf
local medium_scale_quest = null_leaf
local large_scale_quest = null_leaf

local quest = null_leaf

for i=1,10 do
  --print(quest_introduction.collapse(new_stack()))
  print(lost_item_quest.collapse(new_stack()))
end
