# MAINTENANCE SYSTEM

## Overview

Machinery across the facility can randomly malfunction over time.
Maintenance personnel must repair these systems to prevent larger disasters.

Failure rates can scale with facility progression and funding level.

---

## Breakable Systems

The following objects can enter a Damaged State:

* Power boxes
* Water pipes
* Gas pipes
* Facility doors
  * May begin slamming repeatedly when damaged
* Tramline systems
* Elevators
* Computer consoles and terminals
* Light fixtures
* Fire alarm units

Each damaged object:

* Emits visual or audio warning cues
* Displays a repair interaction prompt
* Requires a repair tool
* Takes 10 to 45 seconds to fix depending on severity

---

## Escalation System

If a damaged object is ignored for too long, it can trigger an Automatic Event.

Escalation timer: 15 to 60 minutes depending on severity.

### Escalation Outcomes

* Power box
  * Local power outage
  * May spread to sector-wide outage

* Water pipe
  * Flooding
  * Reduced movement speed
  * Electrical hazard risk

* Gas pipe
  * Toxic gas leak
  * Requires evacuation or protective equipment

* Fire alarm
  * False alarm
  * Facility lockdown protocol

* Elevator
  * Becomes stuck
  * Requires external override

Severity increases as global funding increases.

Neglect increases cost.

---

## Repair Mechanics

Maintenance personnel require:

* Wrench
* Screwdriver
* Pliers
* Replacement parts
* Nearby battery for powered systems

Future upgrade option:

* Repair Efficiency research reduces repair time by 15 to 40 percent

---

## Funding Impact

Each successful repair:

* Adds 5 to 10 dollars to Global Funding
* Reduces chance of escalation

If escalation occurs:

* Automatic Event penalty applies
* Repair cost increases

---

# JANITOR SYSTEM

## Overview

Trash spawns randomly across facility sectors.

Spawn rate increases with:

* Player count
* Cafeteria activity
* Facility funding level

Trash types:

* Paper waste
* Food waste
* Chemical residue
* Broken glass

---

## Cleaning Mechanic

Janitors use a broom to clean trash.

Cleaning time: 3 to 6 seconds per object.

Uncleaned trash:

* Reduces facility reputation
* Slightly lowers morale
* Increases disease spread chance

---

## Cleaning Reward

Each cleaned object:

* Adds 5 to 10 dollars to Global Funding
* Slightly improves facility reputation

---

## Stain System

Stains are persistent surface marks that appear on floors and walls.

Sources:

* Blood decals from combat
* Chemical spills
* Food spills
* Water damage

Stains are separate from trash entities.

They use decal tracking and persistent storage.

---

## Cleaning Stains

Janitor must equip:

* Mop
* Bucket

Cleaning process:

1. Place bucket on ground.
2. Equip mop.
3. Primary attack while aiming at stain.
4. 4 to 8 second progress bar appears.

Movement speed reduced by 40 percent while mopping.

---

## Mop Dirtiness System

Mop has dirtiness value from 0 to 100.

Each cleaned stain:

* Adds 10 to 25 dirtiness depending on stain type.

At 100 dirtiness:

* Mop cannot clean further.
* Cleaning attempt fails.
* UI message: Mop too dirty.

To reset mop:

1. Aim at bucket.
2. Hold secondary attack.
3. 3 second rinse animation.
4. Mop dirtiness resets to 0.

Bucket must contain water.

Bucket water:

* Has contamination level.
* After multiple rinses becomes dirty.
* Dirty bucket increases mop dirtiness gain.

Bucket must be emptied at sink to reset contamination.

---

## Blood and Decal Cleanup

Stains must also remove decals.

Cleaning blood:

* Removes decal from surface.
* Slightly increases disease prevention rating.
* Adds more mop dirtiness than normal stains.

Uncleaned blood:

* Increases disease infection rolls.
* Lowers morale in sector.
* Increases Security tension rating.

---

## Escalation Effects

If stain count in a sector exceeds threshold:

* Reputation decreases.
* Disease multiplier increases.
* Random inspection events may trigger.

Stains persist across restarts until cleaned.
