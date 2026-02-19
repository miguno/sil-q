# Sil-Q Game Design

This document gives an overview of the game design and motivations behind key
design decisions, along with historical context.

## The nature of the game

Sil-Q is a game about choice.

It is possible to imagine a game in the same genre where progress is simply bump
combat, over and over, with numbers going up. The player would rarely or never
need to engage any sort of tactical sense; the rewards would largely be the
intermittent drip-feed of better and better loot, none of it changing the
gameplay loop significantly.

Sil-Q wants to sit as far away from this game as possible.

Sil has been compared to Angband with the analogy that if Angband is a trek up a
mountain, Sil is a bouldering problem. Sil-Q leans into this mindset to create a
short but intense game that demands much player concentration, while trying to
avoid instant deaths and situations that feel unfair.

Sil-Q broadly rejects the idea that there should be one way to succeed; it gives
you many possible tools, all designed to be useful in certain situations, and
leaves it up to you to figure out how they can be brought to work together.

## The flow of the game

The player starts, as is the case in most roguelikes, with very little in the
way of equipment. In Sil-Q this lack can quickly prove fatal. While the player
is unlikely to upgrade their weapon in the first couple of floors, armour is
critical to improving survivability.

Players can invest in Evasion and Melee early and quickly arrive at a
configuration that will survive the early floors. Pacifists sink their resources
into Stealth and Perception and embark on a very different game. Dedicated
smiths gauge how much experience they can afford to sink into Smithing.

The floor at 100' holds a forge shrouded in darkness with three orc warriors,
significantly stronger than anything else the player is likely to encounter in
those first couple of levels. This is the first proper tactical test for a new
player who has found some useful armour and invested in the combat skills. Being
surrounded in Sil-Q has significant combat maluses and it is generally advisable
to lure them out.

In this early phase of the game players focus on acquiring armour and filling
out their equipment slots. An early Smithing investment can give players a head
start on this with the trade off that later the experience spent on that tree
will not be available to boost combat skills.

Generally in this first phase little is spent on abilities and in particular a
melee combat character is well advised to sink almost all their experience into
improving their skills.

The stretch from 100' down to 400' is where most players are settling into their
build. Perhaps they find a bow and elect to invest in Archery, or decide that
they're going to specialise in polearms, or start investing in the abilities
that make their creation choices favouring Constitution or Grace pay off.

The player is contending a good deal with orcs over this period and later
trolls. Orc archers produce a ranged threat. Spiders and wights pose different
sorts of challenges. The first couple of uniques show up in Gorgol and Boldog.

In this stretch the player has to learn when they are strong enough to fight and
when they must simply avoid, what can be skirted steathily and what must be
fled. Getting a lantern or other addition to light radius is important so the
player doesn't stumble into trouble, but as fuel is limited the player may make
effort to conserve it until they are confident in their supply.

Fear and confusion and stun start to become minor threats. The player may want
either resistance against these or to start to increase their will.

400' is about the point where wargs and whispering shadows start to show up.
Wargs in particular challenge stealthy players, being fast with good perception,
and whispering shadows ask questions about the player's access to light. Players
who have not found sufficient light and who have not retained experience to
invest in abilities that will help out will have a hard time here. If stealthy
players have invested in Song of Lorien it is not yet strong enough to lock
levels down; those who are trying to balance stealth and combat may find there
are many things that they have to avoid.

As the player goes deeper from here, resistances to fire, cold and poison grow
more and more urgent. By 500' rauko are starting to appear along with
fire-drakes and a little later werewolves. Some enemies entrance on hit, or
drain stats, and these are no longer easy to avoid. Free action, sustains or
investments in Will are all useful. Perception starts to grow useful as
invisible enemies become much more dangerous than before.

The stretch down to about 800' can be tough going, but the player will be
finding increasingly more powerful items and improving their build, and at some
point should find themselves dealing comfortably with most of the common enemies
on these later levels. Usually players build up a stash of Staves of Treasures,
and spend a period of time gathering items for the final assault on Morgoth.

Morgoth's throne room is the climax of the game. The skilled player comes in
stocked up with potions to boost stats and speed and as much healing as they can
muster, equipped with every resistance, with a strong weapon capable of prising
free a Silmaril. Some of this changes a little for a pacifist who intends to put
Morgoth to sleep, steal a Silmaril and depart - everything is designed there to
maximise Song and the ability to continue singing.

Finally comes the escape, where Staves of Revelation and Song of Delvings expose
the map so the player can thread their way upward and out to the gates, where
they face Carcharoth.

## Combat

Sil-Q's combat, largely unchanged from Sil's, makes use of opposed 1d20 attack
and defence rolls followed by a damage roll against an armour roll.

The opposed attack and defence rolls function quite differently from a single
roll against a target. The distribution of outcomes is dependent on both dice,
and hence improving the bonus of one die compared to the other has much more
impact early on and less later. Rolling a single d20 against a fixed target with
95% percent success rate requires the target to be no higher than 1; with
opposed rolls, a difference of +13 is sufficient to achieve 94.75%, but adding
an extra 1 only ups the chances to 96.25%. This means combat between equal sides
is more quickly imbalanced by bonuses and maluses, and combat between unequal
sides less affected. This makes the impact of relatively small bonuses extremely
relevant in Sil-Q in a way that they are not in many other games.

Damage rolls vs armour rolls add a different dimension. An enemy with low
evasion but high armour will take hit after hit and only slowly be worn down; an
enemy with high evasion but no armour will be hard to hit but crumble quickly.

Critical hits allow for lighter weapons with lower damage dice to outperform
heavier weapons when the player is striking with a very significant advantage.
As heavier armour has maluses that reduce Melee and Evasion, this creates a
dynamic where lighter weapons and lighter armour work well together, and heavier
weapons work with heavier armour. The heavy weapon, not relying on critical
hits, need only make contact and so the player can afford to trade off some
damage output for enhanced protection. The light weapon cannot so easily afford
to give up on attack, and the player must rely on Evasion or Stealth for
protection instead.

## Monster AI (enemy behavior)

One thing the game does well is monster AI. For many players, the orcs running
away only to flank them from behind is typically a memorable experience early
on. Later they come to remember their fights with particular unique enemies.

However, the current level generation does little to assist until the player has
descended quite deep into the dungeons.

## Consumables

Herbs and potions are somewhat similar, and it would be hard to pick out a
consistent theme. Herbs inflict rage and terror, potions boost stats; beyond
that there's quite a bit of overlap. However on the whole both impact only the
player character, and usually are either curative or have an effect that lasts
for a period of time.

Staves are instantaneous in effect and generally modify the world external to
the player character.

## Resource book-keeping

Sil-Q is a game of resource management. Fuel is a ticking clock. Hunger is a
ticking clock. Mostly these serve to amplify the message of the depth clock:
time is passing, hurry up, explore areas you haven't seen yet.

This tension forces the player to make little choices: if I ditch this extra
fuel or this food to carry this potion, will it cost me later? Can I afford the
space to carry one weapon for orcs and another for wolves at the expense of an
antidote I don't need right now but may later? Now I have found a ring of resist
fire, can I afford not to take it with me? But what do I drop?

This feeling of tension, of balancing competing needs, is core to the game's
challenge.

Ammunition fits squarely into this dynamic. The best ammunition is treasured for
the most dangerous encounters, with the most dangerous of all being Morgoth.
This however comes at a cost as ammunition also demands inventory space. Melee
characters often carry a variety of weapons; archers rarely carry a variety of
bows but always a variety of ammunition. Ammunition, like fuel, is limited.

## Races

Races are broadly speaking difficulty levels. Noldor are excellent all-rounders.
Naugrim and Sindar are similar in difficulty; Naugrim are sturdy smiths and good
for melee, Sindar suit archery and stealth. Edain are very much weaker and a
test for the expert.

The motivation behind this is broadly to be true to Tolkien. Almost all good
characters in Tolkien in the first age belong to one of the four races.

These have been in Sil for a long time before they came to Sil-Q. One evolution
I made was to deprive Noldor of a sword affinity and add one for song. Swords
are much favoured weapons in any case, and Song needed a little extra love for
the tree to be relevant beyond stealth.

## Houses

While races are broadly reflective of Tolkien, houses are less so. They exist to
provide a way for the player to customise their character slightly toward one
build or another.

## Smithing

Smithing can be a relatively comprehensive playstyle in Sil-Q. Players will
arrive at the throne room clad mostly with items they made themselves. Other
skills will have suffered, but the bonuses gained from their smithed items
permit them to be just as effective if not more in combat against Morgoth.

Historically, in Sil, smiths spent a lot of time making items that made them
more effective at smithing, and so could arrive at the throne room with items
that were truly game-breaking. Sil-Q has removed the ability to make items that
boost Smithing directly, but rebalanced many costs to be cheaper, so the smith
has access to a diverse set of item abilities but cannot simply turn themselves
into a monster through creating items with ridiculous stat boosts.

Balancing smithing has been a long and difficult road. It has probably been the
hardest thing to balance, much more than archery, because it gives players a
permit to make items that bring together abilities that are broken in
combination. It's a very appealing part of the game for many players, but
historically it's had a U-shaped power curve: a little smithing made you very
strong early, it was bad in the middle game, and at the end you were vastly
overpowered and could breeze through Morgoth. The U-shape is much flatter now,
but it took some time to get there. Any future changes, such as introducing many
new abilities, would likely unsettle that progress.

## Notes

### Notes on dungeon design and level generation

**Making the dungeons feel more alive:** Ideally, the dungeons of Angband would
feel more lived in and "used" by its inhabitants.

Examples include:

- Barracks and dormitories, training rooms, armouries. But much of this would
  require furniture, which would require an overhaul in its own right to the
  ASCII. In many ways the tiles graphics make these things much easier.
- Cave systems with more organic forms, perhaps some areas lit by luminescent
  fungus, rivers, and pools. Once you have pools you can have thematic locations
  such as Moria's Watcher in the Water.
- Orc patrols that roam the levels.

> What other games do: Brogue does a good job of creating ASCII spaces that feel
> a little more full of character than Rogue's bare rooms.

**Early game experience:** What stands in the way of making early levels more
interesting is that there are relatively few building blocks in the ASCII (i.e.,
using ASCII characters to create the look and feel of space) to build rooms
with, and the size of early levels is quite limited so larger rooms barely fit.
These issues are fixable, but would require careful game design and technical
implementation.

### Notes on hunger and food

Originally in Sil, food was a little rarer, but not very much. However, there
was an ability on the Will skill tree that slowed your digestion. It was one of
the worst skills in the game, and Sil-Q subsequently removed it. But Sil-Q ended
up keeping the ability as an enchantment for one main reason: hunger is a curse.
If you have enough items that make you hungry, you can genuinely run yourself
into trouble with food.

One could consider removing hunger and digestion as well as food. But
historically, the dev team has found it very challenging in Sil-Q's finely
balanced ability ecosystem to introduce new bonuses and maluses which are
appropriately powered.
