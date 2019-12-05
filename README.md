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


## 
