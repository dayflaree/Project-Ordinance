# MAINTENANCE SYSTEM – GAMEPLAY DETAILS

## Damage Generation

Each breakable entity has:

* durability value
* hidden wear timer
* severity level 1 to 3

Every 10 to 20 minutes, the system rolls:

* low chance to reduce durability
* higher chance if facility funding is high
* higher chance if power load is high

When durability reaches 0:

* entity enters Damaged State
* visual sparks, smoke, flicker, or sound begins
* UI hint appears when looked at

Severity determines:

* repair time
* required tools
* escalation speed

---

## Interacting With Damaged Machinery

Player looks at entity.

Press +use to open small repair menu.

Menu shows:

* Issue type
* Required tools
* Estimated repair time

Player must have required tool in inventory.

If tool missing, repair cannot begin.

To repair:

* Hold primary attack for repair duration
* Progress bar appears
* Movement speed reduced by 50 percent
* Cancelling resets progress

Failure chance:

* 5 to 15 percent base
* Increased if player has negative traits
* Decreased with Repair Efficiency research

Failure results:

* Minor health damage
* Tool durability reduced
* Escalation timer shortened

---

## Batteries and Power Dependency

Certain machines require:

* Battery item placed within defined radius

If no battery nearby:

* Machine cannot function
* Repair will only restore structure, not activation

Batteries:

* Have charge value
* Drain slowly when powering systems
* Can be replaced or recharged at charging station

---

## Escalation Gameplay

Each damaged object has escalation timer.

If timer reaches zero:

Event triggers.

Examples:

Power Box:

* Sector lights turn off
* Doors default to locked or manual
* Security cameras disabled

Gas Pipe:

* Gas cloud entity spawns
* Players take damage over time
* Biohazard suits negate damage

Water Pipe:

* Water volume appears
* Movement speed reduced
* Electric panels become hazardous

Fire Alarm:

* False alarm state
* Emergency lights enabled
* Certain doors lock

After escalation:

* Repair time increases
* Repair requires extra part item

---

# Janitor System – Gameplay Details

## Trash Spawning

Trash entities spawn:

* In hallways
* Near vending machines
* In cafeteria
* In labs

Spawn rate scales with:

* Player count
* Cafeteria usage
* Number of food items consumed

Trash has types:

* Paper
* Food waste
* Chemical residue
* Glass

Each trash entity stores:

* cleanliness penalty value
* disease risk value

---

## Interacting With Trash

Janitor equips broom.

Primary attack while aiming at trash:

* Begins cleaning
* 3 to 6 second progress bar

If interrupted:

* progress resets

When cleaned:

* Trash removed
* Small funding reward added
* Reputation slightly increased

---

## Trash Escalation

If trash remains for long period:

* Converts into Decay State

Decay State effects:

Food waste:

* Spawns flies
* Increases disease chance in area

Chemical residue:

* Small health damage over time
* Requires hazmat gloves to clean

Broken glass:

* Causes minor damage when stepped on
* Must be cleaned with broom

Trash accumulation threshold:

If 30 plus trash objects exist in sector:

* Morale penalty applied
* Disease spread multiplier increased

---

## Storage and Disposal

Optional extension:

Add Trash Bag item.

Cleaning trash adds it to Trash Bag inventory counter.

Janitor must:

* Bring full Trash Bag to disposal unit
* Use disposal terminal

Disposal rewards:

* Larger funding bonus
* Removes accumulated sector penalty

If bag not emptied:

* Cannot collect more trash

---

## Stain Spawning

Stains spawn dynamically from events:

* Player death creates blood stains.
* Gunshot wounds create impact blood splatter.
* Chemical leaks create colored spill decals.
* Flood events leave water marks.
* Failed medical treatment creates small blood decals.

Each stain entity stores:

* stain type
* severity
* disease modifier
* dirtiness value added to mop

---

## Stain Interaction

Requirements:

* Mop equipped
* Bucket placed nearby within defined radius

Cleaning steps:

* Aim at stain
* Hold primary attack
* Progress bar appears
* On completion:
  * Remove stain entity
  * Remove associated decals
  * Add funding bonus
  * Increase mop dirtiness

If mop dirtiness >= 100:

* Cleaning cannot begin
* Player must rinse mop

---

## Bucket Mechanics

Bucket is placeable item.

States:

* Clean water
* Dirty water
* Empty

Rinsing mop:

* Transfers dirt from mop to bucket.
* Increases bucket contamination.

When contamination reaches limit:

* Rinsing becomes ineffective.
* Mop rinses only partially.

Player must:

* Carry bucket to sink.
* Hold use for 3 seconds.
* Bucket resets to clean water.

---

## Gameplay Impact

Uncleaned stains:

* Increase disease spread chance.
* Increase negative trait triggers.
* Reduce facility cleanliness rating.
* Increase automatic inspection events.

Blood specifically:

* Raises infection risk.
* May attract Xen wildlife in certain sectors.

Janitor gameplay becomes:

* Resource management
* Area control
* Preventative disease mitigation
