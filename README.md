# ProcGen Challenge 5

In this post, I will briefly go over my entry for Procedural Challenge 5.
First of all, here are a couple of adventures generated with my entry:

> TODO

The rest of the post will explain how it works internally. You can find a link
to the code at the end of the post.

The approach I took for this challenge was to write some patterns for
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
the problems I ran into. Thanks for reading! :)

Link to the code:

[https://github.com/25A0/procgen-challenge-5](https://github.com/25A0/procgen-challenge-5)
