# ProcGen Challenge 5

Theme: Procedural adventure generator

> Think Quests, Missions, Plot Hooks or even Settings for a character (or party) in a book or game. A few simple examples:
>
>> An order of paladins is slaying anyone who doesn't convert to their faith,
>
> or .
>
>> The rebels have taken the station orbiting Phobos hostage and are demanding the release of their leader.
>
> If you want to take it a step further, you can increase their complexity or include the impact solving or ignoring this scenario would cause.
>
> A silly setting example that could be used to play a micro-rpg on the fly could be:
>
>> You are a band of miniature robots in a garage and you're low on battery.
>
> These are just examples, so if you come up with anything else you want to do that relates to an adventure, go for it!

## Adventure examples

> You and a group of dwarfs travel to the mountains to ambush the King's tax collector.

> You explore the cursed desert to find your father's lost sword.

> The Emperor's personal doctor is the only person who knows the cure for your brother's sickness. You travel to the Emperor's palace to learn the cure by seducing the doctor.

> Your sister's amulet has been buried in the haunted catacombs many years ago. With the help of your younger brother, you want to explore the catacombs and retrieve the amulet.

> The church's hidden treasure was found in a cave near the capital. You and a
> band of elves want to travel there to guard it from greedy bandits.

> You and a group of elves are traveling southwards when you hear that the
> church's hidden treasure was found in a cave near the capital. Will you
> guide it from greedy bandits, or try to take your own share?

> You chase a dragon for its curing scales.

Building blocks:
 - Dragon and scales: Could be any mystical creature that can have notable body parts

> You flee a dark forest, for you stole from the creatures that lurk there.

> You ride the mountains, to cross a bridge to another land.

> You find a chest under the roots of a tree

> You find the last plant in a long destroyed world.

> You are as small as forget-me-not's, on a quest to find the source of
> tree-destroyers.

> You killed the leader of a religious group and need to flee the country
> unnoticed.

> With the help of your friend, you want to rescue the queen, who was
> kidnapped. If you succeed, you can claim the king's reward.

> You discovered a letter that tells of a stash of gold, hidden in the mountains. The treasure is guarded by a mighty dragon.

> While traveling to the coast, you stay in a little town. The innkeeper tells
> you of a group of plundering bandits that terrifies the region. Will you
> hunt down the bandits or carry on with your journey?

A battlefield, wind blowing over it, but nobody goes there because of the giant
creature that lurks under the surface, ready to devour anyone who comes near.

A burning corpse with a smashed head in a burning house

Bracelet with a gemstone which can summon a demon

## Adventure elements

 - disaster
 - conflict (violent / non-violent)
 - motivation
 - relationships
   - love
   - hate
   - friendship
   - betrayal
   - affairs
   - lust
 - locations
 - ambush
 - travel
 - visions
 - prophecy
 - legends
 - lies
 - betrayal
 - deals
 - bribes
 - theft
 - sickness / death
 - childbirth
 - secrets
   - a cure
   - a recipe
   - a ritual
   - business secrets
   - an invention
 - treasure
   - medicine
   - money
   - artifact
   - weapon
 - technology
 - promises
 - hope
 - faith
 - leadership / power
 - exploration
 - rescue
 - flee

## Themed adventures

For the generated adventures to be coherent, they should fall into one specific
theme. The theme determines the motivation and goal of the adventure. Themes could be:

 - materialistic
 - political
 - interpersonal
 - religious

## Adventure structure

The generated adventures should contain the following elements:

 - A subject:
    - You...
    - You and your brothers...
    - You and your partner...
    - You and a group of dwarfs...
    - You and a couple of bandits...
    - With the help of your mentor, you...
 - An action:
    - travel somewhere
    - explore a location
 - A goal
    - find something
 - A motivation for the goal that justifies the action
    - Someone paid you to do it
    - It was someone's last wish
    - Time is running out because:
      - Someone is dying
      - There's a war at stake
      - There's a storm coming
      - The stars have to align a certain way
      - Someone is getting married

The bits of information can be chosen independently of how it will then be put into text.
The same bits of information can be put into text in different ways:

> 

## Patterns

 - [valuable item] was [lost / buried] in [dangerous location]. [group] want to explore the [location] and retrieve the [item].
 - [group] travel to [vague location] to ...?
 - [group] explore [dangerous location] to find [lost valuable item]
 - [valuable item] was [found / discovered] in [specific location]. [group]
   want to travel there to guard it from [evil group].
 - [group] [committed crime] and need to [escape or flee].
 - [group] want to [rescue / free] [significant person], who was kidnapped.

## Problems and solutions

 - When offering multiple options, how do we make sure they are well weighted?
   For example, we might populate a person slot with either:

     - "a childhood friend", or
     - a relative: "father", "mother", "brother", "sister"

   There are four options for a relative, but only one option for the childhood
   friend. When all options should have the same weight, then each of them
   should have a 20% chance of being chosen. But we only know how many options
   there are when we fully explore the tree of options.

   To solve that, we could keep track of the number of options when defining
   the trees, so that options can be weighted accurately. In the above example,
   we know that the `relative` node has four options, and the `friend` node has
   one option. The node that connects the two can keep that knowledge, not only
   to weight the options correctly, but also to inform any nodes higher up in
   the tree about the number of combined options (here, 5).

 - We sometimes need multiple ways to describe the same object. For example,
   the first time an item is mentioned, you might want to have it described
   with additional adjectives: "the legendary dagger", "the magical amulet".
   But when you mention it again in a different sentence, it sounds more natural
   to just refer to it as "the dagger" or "the amulet".

 - Approach: We first build a tree of options. Tree leaves are literal options,
   like "sword" for items, or "father" for a person. Nodes combine leaves.
   The same node can be child of multiple nodes, since there might be cases
   where a node can be used in different ways.

 - Using trees might give us the illusion of using something uniform, but it's
   natural language, and realistically, that's very ununiform. So it's fine to
   have very specific and non-uniform data structures if it helps to cast the
   knowledge into data.

 - Person:
    - we need a single word to refer to them: king
    - we need pronouns for persons: he
    - can own something: The King's knickers
      for this we also need possessive pronouns: his knickers
    - certain persons may need to be explained in context: the local blacksmith
    - there can be special cases concerning the relationship between two
      people. for example, the king's wife is commonly called the queen. the
      king's son is the prince, and so on. the prince's wife is the princess.
    - people can be related to each other:
      - wife, husband, partner
      - daughter, son, child
      - mother, father, parent
    - people can have professions:
       - blacksmith
       - fisher
       - logger
       - armorer
       - doctor
       - hunter
       - farmer
       - tanner
       - stonemason
       - carpenter

      But some professions will be limited to a higher class context:
       - alchemist
       - cartographer
       - guard commander

 - We need a way to link leaves. For example, we collapse a combination of
   creature and body part, yielding {dragon, scales}. Next we want to find
   a property for the body parts. We want to do something like
   `body_part_and_property.collapse(scales)`, thus providing a sort of filter.

   With this, we don't need to have a new node for the combination of creature,
   body part, and property.

 - Basic building blocks: We could try to write flexible building blocks that
   can be used to build a story and expand details as needed.
    - Something was stolen: "A local blacksmith seeks your help. His father's battle axe was stolen from his house. The blacksmith suspects a group of bandits who live in a nearby forest. He promises to reward you if you recover the battle axe."
       - What was stolen? Item
       - Who stole it? A party
       - Hint on the location of the party: Where are they or where did they go?
       - How did you hear of the stealing?

   With these building blocks we can flexibly define relations between data points.

    - A priest belongs to a religious group.
    - A person can have a family status.
    - An object can be stored in a specific type of building:
       - Book - Library
       - any personal item - House
       - weapon - armory
       - treasure - vault

   These relations let us choose a starting point for the quest, and expand it
   confidently.

 - We could categorize quests into scales:
    - small-scale quests are about local folk and problems. Travel distance is
      short, and the reward is small. Information about small-scale quests
      comes from first-hand conversations, or rumors.
    - medium-scale quests are about regional problems. Travel can take days,
      and there's a promising reward at stake. Information about medium-scale
      quests comes from bard's songs or local legends.
    - large-scale quests are about problems that concern a country or
      continent. Travel can take weeks, and the reward can be immense.
      Information about large-scale quests comes from books, legends, scrolls.
      large-scale quests might involve royals or legendary creatures.

 - How do you produce two, or `k` different options from the same node?
   We sometimes want to pick `k` distinct elements from a set, for example
   two different drinks, or two different adjectives to describe something.
   For example,

   ```lua
   (leaf "beer" + leaf "wine" + leaf "cider" + leaf "mead")^2
   ```

   should collapse to `{"beer", "cider"}`, or `{"mead", "beer"}`, but not
   `{"beer", "beer"}`.

   - We could just collapse the node multiple times, until we have `k`
     different results. **BUT** Collapsing is no longer stateless, so
     collapsing the same node multiple times may have side-effects that we
     might need to roll back if we get the same outcome twice. Also, this
     approach gets very slow when `k` is close to the number of options in that
     node.
   - We could teach nodes how to generate a result for a specific option.
     For example, the node

     ```lua
     drinks = leaf("beer") + leaf("wine") + leaf("cider") + leaf("mead")
     ```

     has four options. If we call `drinks.collapse(3)`, it should always return
     `cider`. This has the added bonus that we no longer need to make a dice
     roll in every single node. Once we determined which of the `n` options we
     want, it is fully deterministic which branch should be chosen in each node.

     If we get this to work, then we only need to generate `k` different
     integers in the range of options. This is stateless, so we can retry as
     much as we like. If we want to produce many different options (close to
     the total number of options), we could even do the reverse and choose
     the `(n_options - k)` values we don't generate.

     ~~Currently, it is not clear how to deal with keyed nodes for this scenario.~~

     Keyed nodes are tricky in this scenario because our computation for the
     number of options has to be accurate, and in our current implementation,
     it is not. We will replace keyed nodes by two functions:

      - `map_string([node,] table)` maps from a node to a table of strings.
        This is simple, but sufficient for things like pronouns, where there's
        only one option. If no node is given, it pops the key from the stack.
      - `map_node(node, table[, table]*)` maps from a node to one or more table
        of nodes. This function can't take a node value from the stack, since that
        would make it impossible to compute the number of options correctly.

        When collapsed, it first collapses the given node, which will form the
        key for the given tables. It then returns a sequence in which index 1
        holds the key itself, index 2 holds the value from the first table,
        and so on, for all given tables.

     _What if there are a lot of options? Will we run into precision problems?_
     Unlikely. Lua uses double-precision floats, with 53 bits mantissa, so
     there's 2^53 possible options that can be represented with a single
     number without losing precision.

## Unsorted thoughts

Healing a sickness

Lifting a curse:
 - By touching a magical object
 - A person can do it. A witch, a witcher, a wizard, a mage

Curing a poisoning

## Blog post

In this post, I will briefly go over my entry for Procedural Challenge 5.
First of all, here are a couple of adventures generated with my entry:

> TODO

The rest of the post will explain how it works internally. You can find a link
to the code at the end of the post.

The appraoch I took for this challenge was to write some patterns for
adventures by hand, and then write some code to diversify those patterns.

A simple adventure could look like this:

> you are drinking beer in a tavern, when a blacksmith approaches you. her
> father lost his sword in a haunted graveyard. she asks you to travel to the
> graveyard and retrieve his sword.

This singular example can be diversified in a lot of different ways:

 - You could also be drinking wine, or mead, or cider.
 - The blacksmith could be a fisher, or a logger, or a hunter instead.
 - The adventure could be about the blacksmith's brother, or daughter instead.
 - Maybe they lost a dagger, or a battle axe, or a ring, or an amulet...
 - They might have lost that item in a different location. Maybe a cursed
   battlefield?

My idea was to cast all these possible variations in code, and then pick one
option at random.

With this approach, I had two clear design goals for my code:

 - **It must be easy to add or expand content.**
   For example, once you defined a set of drinks, it should be trivial to
   add another drink to that list.

 - **It must be easy to re-use content.**
   For example, once you defined a set of drinks, it should be trivial to
   randomly pick one of those drinks in another situation.

I will now walk through some examples to illustrate my solution, and explain
some design decisions along the way.

This is how we can define a set of drinks:

```lua

local drinks = leaf("beer") + leaf("wine") + leaf("cider") + leaf("mead")

```

The individual drinks are introduced as _leaf nodes_ of a (sort of)
[binary tree](https://en.wikipedia.org/wiki/Binary_tree). Combining two nodes
(with the overloaded `+` operator) creates a new node that has the two combined
nodes as children. So, the `drinks` tree would look like this:

```
            ┌─ beer
          ┌─┤
          │ └─ wine
        ┌─┤
        │ └─ cider
drinks ─┤
        └─ mead
```

Each node has a function `collapse()` which returns one of the leaf values.
So, `drinks.collapse()` will return `"beer"`, `"wine"`, `"cider"`, or `"mead"`.

**That is fine, and all, but how do you actually use that to form sentences and stuff?** - You, probably

In Lua, the `..` operator concatenates two strings:

```
> print("Hello, " .. "world!")
Hello, world!
```

For nodes, the `..` operator is overloaded to concatenate two nodes, or a node
and a string, when they are collapsed. Here is an example:

```lua
local dwarf_doing_something_in_the_tavern = "a dwarf is drinking " .. drinks .. " in the tavern."
```

Note that the concatenation operator also returns a node, which itself can be collapsed:

```
> print(dwarf_doing_something_in_the_tavern.collapse())
a dwarf is drinking wine in the tavern.
> print(dwarf_doing_something_in_the_tavern.collapse())
a dwarf is drinking wine in the tavern.
> print(dwarf_doing_something_in_the_tavern.collapse())
a dwarf is drinking beer in the tavern.
> print(dwarf_doing_something_in_the_tavern.collapse())
a dwarf is drinking mead in the tavern.
```

This allows us to flexibly combine different kinds of content with ease. For
example, we can expand the set of drinks with various flavours of tea:

```lua
drinks = drinks + (leaf("mint") + leaf("green") + leaf("black") + leaf("sage") .. " tea")
```

Now the set of drinks also includes these four flavours of tea.

With these two operators, it's trivial to expand existing context: We literally
add strings to a variable to add options. It is also trivial to re-use the
content by concatenating nodes to strings or other nodes.

However, this simple model has some limitations, that we'll explore in the next
section.

## Remembering contextual information

The `+` and `..` operators only allow us to build rather simple content, but we
quickly run into problems once we try to generate more complex stuff. Let's
look at the following sentence:

> You are drinking beer in the tavern. The beer tastes rather disgusting.

The first sentence describes what you're drinking, and the second sentence
describes how that drink tastes. Let's say that we want to randomize the drink.
A first attempt could look like this:

```lua
local drinking = "You are drinking " .. drinks .. " in the tavern. " ..
                 "The " .. drinks .. " tastes rather disgusting."
```

But when we go ahead and test this, then we get results like these:

```
> print(drinking.collapse())
You are drinking wine in the tavern. The green tea tastes rather disgusting.
> print(drinking.collapse())
You are drinking mead in the tavern. The mead tastes rather disgusting.
> print(drinking.collapse())
You are drinking mint tea in the tavern. The ale tastes rather disgusting.
> print(drinking.collapse())
You are drinking beer in the tavern. The sage tea tastes rather disgusting.
> print(drinking.collapse())
You are drinking green tea in the tavern. The mint tea tastes rather disgusting.
```

For every instance of `drinks` in that construction, a new drink is picked at
random. That's not what we want. We want to describe the same drink in both
scenarios. The solution for these kind of problems is to temporarily store
contextual information.

Let me introduce three new functions:

 - `new_context()`: This returns a new context in which contextual information
   can be stored. The created context is then passed to the `collapse`
   function.
 - `store(node, key)`: This function returns a new node which does the following
   when collapsed: it collapses the given node, and stores the result in the
   context table under the given key. The function then returns the empty
   string.
 - `read(key)`: This function returns a new node which, when collapsed, will
   look up the given key in the context table, and return its value.

With these functions, we can build the sentence the way we want it:

```lua
local drinking =
  -- first, we pick one of the drinks, and store it in the context
  -- under the key "the_drink"
  store(drinks, "the_drink") ..
  -- then, we build our sentence, and rather than picking a new drink twice,
  -- we read the chosen drink from the context, so that we get the same
  -- drink both times.
  "You are drinking " .. read("the_drink") .. " in the tavern. " ..
  "The " .. read("the_drink") .. " tastes rather disgusting."
```

To generate text from this node, we now need to pass a `context` table
to the `collapse` function:

```
> print(drinking.collapse(new_context()))
You are drinking green tea in the tavern. The green tea tastes rather disgusting.
> print(drinking.collapse(new_context()))
You are drinking mead in the tavern. The mead tastes rather disgusting.
> print(drinking.collapse(new_context()))
You are drinking cider in the tavern. The cider tastes rather disgusting.
> print(drinking.collapse(new_context()))
You are drinking sage tea in the tavern. The sage tea tastes rather disgusting.
> print(drinking.collapse(new_context()))
You are drinking ale in the tavern. The ale tastes rather disgusting.
```

Next, we'll make it a bit easier to write sentences with this technique:

```lua
local drinking =
  store(drinks, "the_drink") ..
  format_node("You are drinking :the_drink: in the tavern. " ..
              "The :the_drink: tastes rather disgusting.")
```

The function `format_node` takes a formatstring as its first argument.
When collapsed, it will replace any patterns of the form `:key:`
with the corresponding value stored in the context. The code becomes
even more readable when you use one of the possible values as the key
for the context table:

```lua
local drinking =
  store(drinks, "beer") ..
  format_node("You are drinking :beer: in the tavern. " ..
              "The :beer: tastes rather disgusting.")
```

Note that all the new functions return nodes themselves, so they can be combined
with other nodes to form more complex content.

## Mapping nodes to other nodes

There is one final puzzle piece missing. Let's have a look at the following sentence:

> The old witch tells you that she needs the scales of a dragon to lift the curse.

Let's say that we want to randomize the creature, as well as the body parts in this sentence.
It is easy enough to make nodes for creatures and body parts:

```lua
local creatures = leaf "dragon" + leaf "giant" + leaf "minotaur" + leaf "centaur" + leaf "griffin"
local body_parts =
  leaf "scales" +
  leaf "blood" +
  leaf "teeth" +
  leaf "bones" +
  leaf "claws" +
  leaf "wings" +
  leaf "skin" +
  leaf "hair" +
  leaf "fur" +
  leaf "mane" +
  leaf "hooves" +
  leaf "horns" +
  leaf "feathers" +
  leaf "beak"
```

But if we were just to pick from these two nodes randomly, we would get weird
combinations like `dragon` and `mane`, or `centaur` and `beak`. We could limit
the body parts to those items that are present in all creatures, but that would
kill the diversity in the generated sentences. Instead, we can do something
better: We can create a mapping from creatures to body parts:

```lua
local body_parts_of_creature = {
  dragon =
    leaf "scales" +
    leaf "blood" +
    leaf "teeth" +
    leaf "bones" +
    leaf "claws" +
    leaf "wings",
  giant =
    leaf "blood" +
    leaf "teeth" +
    leaf "bones" +
    leaf "hair",
  minotaur =
    leaf "blood" +
    leaf "teeth" +
    leaf "bones" +
    leaf "fur" +
    leaf "hooves" +
    leaf "horns",
  centaur =
    leaf "blood" +
    leaf "teeth" +
    leaf "bones" +
    leaf "fur" +
    leaf "mane" +
    leaf "hooves",
  griffin =
    leaf "blood" +
    leaf "beak" +
    leaf "bones" +
    leaf "feathers" +
    leaf "claws",
}
```

Note that `body_parts_of_creature` is not a node, but a lua table, with the
literal creatures as keys, and nodes of their body parts as corresponding
values.

We can use this mapping like this:

```lua
local mapping_example =
  store(map_to_node(creatures, body_parts_of_creature), {"dragon", "scales"}) ..
  format_node("The old witch tells you that she needs the :scales: of a :dragon: to lift the curse.")
```

Let's go through this example one by one:
 - `map_to_node` is a new function that takes a node and a table as its arguments.
   The function itself returns a node, which, when collapsed, does the following:
    - it first collapses the node that was passed as its first argument. In our
      example, that would yield one of the possible creatures, say `"griffin"`.
    - it then uses the collapsed value as key into the table that was passed as
      the second argument, where it will find a node. In our example, it will
      find a node of possible body parts for the chosen creature.
    - it then collapses the node that it found on the table. In our example,
      that would yield a specific body part of the chosen creature, say
      `"beak"`.
    - finally, it returns both choices as a sequence. In our example, that
      would be `{"griffin", "beak"}`.
 - `store` is here called with a sequence of strings, rather than a single
   string. This is because, in contrast to all nodes we used so far,
   `map_to_node` doesn't yield a single string; it yields a sequence of
   strings. We pass a sequence of strings to `store`, so that it stores the two
   values (the creature, and the corresponding body part) under separate keys
   in the context.
 - finally, `format_node` is not different from the previous examples: We look
   up the stored creature under the key `"dragon"`, and the stored body part
   under the key `"scales"`.

Here are a few examples:

```
> print(mapping_example.collapse(new_context()))
The old witch tells you that she needs the wings of a dragon to lift the curse.
> print(mapping_example.collapse(new_context()))
The old witch tells you that she needs the bones of a griffin to lift the curse.
> print(mapping_example.collapse(new_context()))
The old witch tells you that she needs the claws of a dragon to lift the curse.
> print(mapping_example.collapse(new_context()))
The old witch tells you that she needs the mane of a centaur to lift the curse.
> print(mapping_example.collapse(new_context()))
The old witch tells you that she needs the bones of a centaur to lift the curse.
```

Crucially, `map_to_node` is itself again a node, so it can be combined with other
nodes to form more complex stories.

## Final words

That is all I want to cover in this post. Honestly, I don't think the generated
adventures are that interesting, but I enjoyed finding good solutions to tackle
the problems I ran into.

Link to code:

TODO
