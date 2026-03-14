# Parallax Framework – Comprehensive Guide (Per-File Breakdown)
**Repository:** `parallax`  
**Scope:** Full framework (core systems, modules, interface, entities, items, localization, assets, docs, tooling)  
**Style:** Comprehensive per-file breakdown without full source listings (per request)  

---

## 1. High-Level Overview

Parallax is a modular roleplay framework for Garry’s Mod that **extends Sandbox** and provides the runtime systems for roleplay content (characters, items, factions, commands, networking, UI, and modular features).  
Schemas derive from Parallax and supply custom content (factions, items, hooks, UI) without modifying the framework.

### Key Concepts
- **Derivation chain:** `sandbox → parallax → your schema`
- **Global namespace:** `ax` table contains all framework systems
- **Realm prefixes:**  
  - `cl_` = client only  
  - `sv_` = server only  
  - `sh_` = shared  

---

## 2. Boot & Load Flow (Core Entry Points)

### `gamemode/init.lua` (Server Entry)
- Derives from Sandbox.
- Initializes `ax` namespace and reload state.
- Sends `cl_init.lua` and boot loaders to client.
- Includes utility boot and framework boot.
- Strips default sandbox widget hooks.
- Adds workshop content and resources (materials, fonts, sounds).

### `gamemode/cl_init.lua` (Client Entry)
- Derives from Sandbox.
- Initializes `ax` namespace and reload state.
- Includes utility boot and framework boot.
- Removes sandbox widget rendering hooks.

### `gamemode/framework/util/boot.lua`
- Utility boot loader.
- Adds utility Lua files to client (when server).
- Includes utility Lua files on both server and client.
- Validates `ax.util.Include` exists after load.

### `gamemode/framework/boot.lua`
- Defines GM metadata (name, author, website, email).
- Loads framework directories in order:
  1. `libraries`
  2. `meta`
  3. `core`
  4. `hooks`
  5. `networking`
  6. `interface`

---

## 3. Utilities (`gamemode/framework/util/`)

Utilities are foundational helpers used by the entire framework.

| File | Purpose |
|------|---------|
| `util_bots.lua` | Bot-specific helpers and detection (NPC/bot utilities). |
| `util_core.lua` | Core helpers (table/number/string helpers, object safety, realm detection). |
| `util_file.lua` | File operations, include logic, directory traversal. |
| `util_find.lua` | Search and lookup helpers (entities, players, items). |
| `util_print.lua` | Logging/printing with framework formatting (success, warn, error). |
| `util_sound.lua` | Sound playback helpers and sound table utilities. |
| `util_store.lua` | In-memory storage, cache or registry helpers. |
| `util_text.lua` | Text formatting, wrapping, localization helpers. |
| `util_version.lua` | Version comparisons and formatting. |

---

## 4. Framework Libraries (`gamemode/framework/libraries/`)

Libraries provide **primary framework APIs** and systems.

### Client Libraries
| File | Responsibility |
|------|----------------|
| `cl_bind.lua` | Input binding helpers; manages bind actions for UI/features. |
| `cl_font.lua` | Font registration, scaling, and font management. |
| `cl_motion.lua` | Motion/transition logic for UI elements. |
| `cl_skin.lua` | Derma skin definitions and overrides. |
| `cl_theme.lua` | Theme data (colors, fonts, UI styling). |

### Shared Libraries
| File | Responsibility |
|------|----------------|
| `sh_character.lua` | Character registry and API (creation, vars, retrieval). |
| `sh_chat.lua` | Chat system infrastructure, chat message routing. |
| `sh_class.lua` | Class registry and loader; Include/Get/CanBecome helpers. |
| `sh_command.lua` | Chat/console command registration, validation. |
| `sh_config.lua` | Config system (schema + framework config values). |
| `sh_data.lua` | Data helpers (serialization, default data access). |
| `sh_ease.lua` | Easing functions for animations/UI. |
| `sh_faction.lua` | Faction registration, validation, retrieval. |
| `sh_flags.lua` | Permission flags and access helpers. |
| `sh_hook.lua` | Hook registry and hook dispatch order. |
| `sh_inventory.lua` | Inventory system (creation, sync, weight). |
| `sh_item.lua` | Item system (definitions, instances, actions). |
| `sh_localization.lua` | Localization system (language tables). |
| `sh_module.lua` | Module system (bootstrapping, init, integration). |
| `sh_net.lua` | Networking wrapper helpers and message builders. |
| `sh_notification.lua` | Notification API (client/server notify). |
| `sh_option.lua` | Player options (settings) registry and access. |
| `sh_player.lua` | Shared player extensions (common APIs). |
| `sh_rank.lua` | Rank system for permissions/roles; registry with `instances`/`stored`, directory includes, faction links, `Get`/`GetAll`/`IsValid`/`HasAny`/`CanBecome`. |
| `sh_relay.lua` | Entity/global relay storage with sync and cleanup hooks. |
| `sh_schema.lua` | Schema initialization, ordered includes, and schema/module loading. |
| `sh_type.lua` | Type defs (constants), sanitization, detection, formatting, and helper `is*` functions. |

### Server Libraries
| File | Responsibility |
|------|----------------|
| `sv_character.lua` | Server-only character persistence and database hooks. |
| `sv_database.lua` | Database adapter, queries, schema DB setup. |
| `sv_item.lua` | Server-only item transfer, spawning, persistence. |

### Third-Party Libraries (`libraries/thirdparty/`)
These are embedded dependencies or shared utilities:
- `cl_gfonts.lua` – Google fonts retrieval.
- `cl_imgui.lua` – Immediate mode GUI helpers.
- `cl_mmask.lua` – Material masking.
- `cl_outline.lua` – Outline rendering.
- `cl_rndx.lua` – Render indexing or caching.
- `cl_scrcache.lua` – Screen caching for UI.
- `cl_viewstack.lua` – View stack utilities.
- `sh_cami.lua` – CAMI admin integration.
- `sh_gmn.lua` – Gamemode network helpers.
- `sh_impr.lua` – Improvement helpers (utility).
- `sh_sfs.lua` – Safe function serialization.
- `sh_soundduration_ogg.lua` – OGG duration fix.
- `sh_utf8.lua` – UTF-8 helper library.
- `sh_wiltostech.lua` – Wilto’s tech compatibility.
- `sv_mysql.lua` – MySQL wrapper.
- `sv_yaml.lua` – YAML parser.
- `dash/` – Dash utility set:
  - `sh_file.lua`, `sh_net.lua`, `sh_player.lua`, `sh_string.lua`, `sh_table.lua`, `sh_type.lua`.

### Library File Details (Line-Level Behavior)

- `sh_character.lua`
  - Provides `ax.character:Get(id)` with bot-ID handling.
  - `GetVar` resolves defaults and nested `ax.type.data` table keys.
  - `SetVar` updates values, triggers change callbacks, networks changes (`character.var`/`character.data`), and persists to database.
  - Supports `bNoNetworking`, `recipients`, and `bNoDBUpdate` options for controlled updates.
  - `SyncBotToClients` sends bot character states.
  - `CanPopulateVar` checks if a character variable should appear during creation.
  - `RegisterVar` registers variables, adds database schema fields, auto-generates getters/setters, and handles aliases.

- `sh_chat.lua`
  - Registers chat classes with `ax.chat:Add`, auto-wires client slash commands.
  - `Parse` detects which chat type prefix is used and strips it.
  - `Send` (server) validates `CanSay`, `CanHear`, hooks, and networks `chat.message`.
  - Text processing pipeline:
    - Shortcuts replacement (e.g., `idk` → `I don't know`).
    - Normalize spacing/punctuation and capitalization.
    - Fix pronoun “I”.
    - Ensure trailing punctuation even with markdown markers.
  - Markdown parser supports `*`, `**`, `***` styles and builds font tags.
  - Utilities for capitalization detection, font name building, and formatting.

- `sh_class.lua`
  - Class registry with `instances` and `stored`.
  - `Initialize` loads classes from framework, modules, schema, and schema modules.
  - `Include` loads class files, validates faction links, and populates `faction.Classes`.
  - `Get` resolves by id/index/name/partial match.
  - `CanBecome` runs hook + class `CanBecome`, notifies on denial.
  - `GetAll` supports filters (faction/name); `IsValid` and `HasAny` helpers.

- `sh_command.lua`
  - Command registry with aliases and CAMI privileges.
  - `Add` normalizes definitions, registers CAMI privileges (if no CanRun), and supports aliases.
  - `GetPublic` filters non-admin commands.
  - `Find`, `FindAll`, `FindClosest` for matching by name/alias.
  - `HasAccess` validates console permissions, admin/superadmin, CAMI access, and `CanPlayerRunCommand` hook.
  - Argument parsing/validation supports typed args, optional args, and text args consuming rest-of-line.
  - `Parse` resolves prefix (`/`/`!`), name, and alias mapping.
  - `Run` enforces access checks, extracts args, and executes handlers via `pcall`.
  - `Send` (client) validates and nets `command.run`.
  - `Help` formats usage strings from argument definitions.

- `sh_config.lua`
  - Defines `ax.config` store-based config system (server-authoritative).
  - `ax.config:Add/Get/Set/GetData/GetDefault/GetAllDefinitions/GetAllCategories/GetAllByCategory/Load/Save/Sync`.
  - Config store spec: project-scoped, human-readable JSON, legacy path `parallax/config.json`.
  - Uses `util_store` hot-reload detection and rebuilds store when library updated.
  - Sets up networking via `config.init` and `config.set`, loads config on server startup.

- `sh_data.lua`
  - Simple persistence helpers for data folder with scope (`global`, `project`, `map`).
  - `Set` writes JSON, supports human-readable formatting and cache control.
  - `Get` reads from cache or disk, parses JSON with primitive wrapper support.
  - `Delete` removes stored file and clears cache entry.

- `sh_ease.lua`
  - Provides `ax.ease.list` mapping to `math.ease.*` functions.
  - `ax.ease:Lerp(easeType, time, startValue, endValue)` with input validation.
  - Supports Linear or easing type interpolation for numbers, vectors, angles, and color tables.

- `sh_faction.lua`
  - Faction registry with `instances` (by index) and `stored` (by id).
  - `Initialize` loads factions from framework, modules, and schema directories.
  - `FACTION_DEFAULT_MODELS` fallback model list.
  - `Include` scans directories, loads faction files, builds `FACTION` table, calls `team.SetUp`.
  - `Get` resolves faction by id, index, or partial name.
  - `CanBecome` runs `CanPlayerBecomeFaction` hook and faction `CanBecome`.
  - `GetAll` returns all factions, `IsValid` verifies existence.

- `sh_flags.lua`
  - `ax.flag:Create(letter, data)` registers single-letter flags.
  - `GetAll` returns the entire flag registry.
  - `Get` returns a flag definition by letter with validation.

- `sh_hook.lua`
  - Registers/Unregisters hook tables via `ax.hook:Register`.
  - Overrides `hook.Call` to route through ax hooks, module methods, then gamemode.
  - Supports profiler recording when developer cvar or `debug.profiler.enabled` is set.
  - Records slow calls using `debug.profiler.thresholdMs`.

- `sh_inventory.lua`
  - Maintains `ax.inventory.instances` and `ax.inventory.meta` with instance 0 as world inventory.
  - Server `CreateTemporary` builds in-memory inventories with negative IDs, cleans old items.
  - Server `Create` inserts into `ax_inventories` and returns inventory via callback.
  - `Sync` sends inventory data to receivers; optional debounce/delta scheduling via config.
  - `Restore` loads character inventories, syncs world items in batches, rebuilds items from DB, and adds receivers for active inventory.
  - Uses `inventory.sync.delta`, `inventory.sync.debounce`, `inventory.sync.full_refresh_interval`.
  - Adds `ax_inventory_restore` console command for superadmins.

- `sh_item.lua`
  - Item registry (`stored`), instance list, actions, and meta table.
  - Loads items/bases from framework, schema, and module directories; supports inheritance.
  - Default actions: `take` (world pickup) and `drop` (to world inventory).
  - `GetActionsForClass` merges base + class actions.
  - `RefreshItemInstances` rebuilds metatables for existing instances.
  - `Include` loads base/items/inheritance; refreshes instances.
  - `CreateDefaultTakeAction` validates context entity/inventory weight; transfers to inventory and removes world entity.
  - `CreateDefaultDropAction` transfers to world inventory, notifies on failure.
  - `LoadBasesFromDirectory`, `LoadItemsFromDirectory`, `LoadItemsWithInheritance`, `LoadItemsWithBase` manage base/derived item loading with time filters.
  - `ExtractItemName` strips prefixes, `FindByIdentifier` resolves class by id/name/partial match.
  - `Instance` creates item instance table with metatable to definition.

- `sh_localization.lua`
  - Localization registry `langs` with `Register` and `AddPhrase`.
  - `GetCurrentLanguage` reads config/cvar and maps known codes.
  - `GetPhrase` returns localized string with format args, fallback to `en` or phrase key.
  - Reacts to `gmod_language` changes, rebuilds UI via `ax.gui`.
  - Client command `ax_localization_missing_keys` compares current locale to `en`.
  - `ax.localisation` alias to `ax.localization`.

- `sh_module.lua`
  - Module loader for single-file and folder-based modules.
  - `Include` loads file modules or boot.lua, then standard subdirs (libraries/meta/core/hooks/networking/interface).
  - Autoloads remaining files unless `MODULE.autoload` is false.
  - Loads module factions/classes/ranks/items/entities and fires `OnLoaded` + `OnModuleLoaded`.
  - `Get`, `GetAll`, `GetByScope`, `IsLoaded` module accessors.

- `sh_net.lua`
  - Streaming net layer using `sfs` encode/decode with queued net jobs.
  - `Enqueue`/`ProcessQueue` serialize net.Start calls.
  - `Hook` registers message handlers, optional no-delay flag.
  - `Start` routes to broadcast, player, table recipients, PAS/PVS (server), or server (client).
  - Receives `ax.net.msg`, decodes payload, applies cooldowns (`networking.cooldown`).

- `sh_notification.lua`
  - Server `Send` toasts to players via `notification.push`.
  - Client queue/active stacks with motion-driven animation.
  - Renders in `PostRender` with custom easing, layout, and reveal effects.
  - Supports positions, scale, sounds, and clear API.

- `sh_option.lua`
  - Per-client option store with optional server sync and persistence.
  - Uses `ax.util:CreateStore` spec with `option.sync`/`option.set`/`option.request`.
  - Global data store `parallax_options`, legacy path `parallax/options.json`.
  - Rebuilds store on library changes, loads options on client startup.

- `sh_player.lua`
  - Player variable registry with networking + DB updates.
  - `GetVar` supports data-type fields and fallbacks.
  - `SetVar` handles net routing, change callbacks, hooks, and DB writes.
  - `RegisterVar` adds schema fields, auto Get/Set methods, and aliases.

- `sh_rank.lua`
  - Rank registry with `instances` and `stored` tables.
  - `Initialize` loads ranks from framework/modules/schema + schema modules.
  - `Include` scans directories, loads rank files, validates faction links, and populates `faction.Ranks`.
  - `Get` resolves by id/index/name/partial match; `GetAll` supports faction/name filtering.
  - `CanBecome` runs `CanBecomeRank` hook and rank `CanBecome`, notifies on denial.
  - `IsValid`/`HasAny` helpers for validation.

- `sh_relay.lua`
  - Entity/global relay store with optional networking.
  - `Entity:SetRelay/GetRelay` store per-entity values (player uses SteamID64).
  - `SetRelay/GetRelay` global values in `ax.relay.data.global`.
  - `relay.sync` and `relay.update` net messages; cleanup on `EntityRemoved`.

- `sh_schema.lua`
  - Schema loader; includes schema boot and ordered directories.
  - Loads factions/classes/ranks/items and modules, then config (including map-specific).
  - Uses `SCHEMA.folder` or active gamemode fallback, registers `SCHEMA` hook table.
  - Fires `OnSchemaLoaded` after initialization.

- `sh_type.lua`
  - Type constants (string/number/bool/vector/angle/color/player/character/steamid/steamid64/array/table/data).
  - `Sanitise` coerces and validates values per type; supports data-table parsing.
  - `Detect` maps Lua types or validators to type IDs.
  - `Format` returns readable type names; defines global `is*` helpers.

---

## 5. Meta Tables (`gamemode/framework/meta/`)

Meta tables extend GMod classes with framework-specific methods.

| File | Responsibility |
|------|----------------|
| `sh_character.lua` | Adds character helper methods (getters/setters). |
| `sh_color.lua` | Color extensions (utility methods). |
| `sh_entity.lua` | Entity extensions (entity helpers). |
| `sh_inventory.lua` | Inventory object methods. |
| `sh_item.lua` | Item instance methods. |
| `sh_player.lua` | Player methods (character, inventory, flags). |
| `sh_tool.lua` | Toolgun / tool-mode helpers. |

---

## 6. Core Systems (`gamemode/framework/core/`)

Core files connect libraries to runtime behavior.

| File | Responsibility |
|------|----------------|
| `sh_character.lua` | Registers default character variables and core behavior. |
| `sh_chat.lua` | Core chat handling, message formatting, chat types. |
| `sh_commands.lua` | Core commands registration and default commands. |
| `sh_config.lua` | Framework configuration defaults and loader. |
| `sh_ents.lua` | Entity management helpers and hooks. |
| `sh_flags.lua` | Flag registration and default flags. |
| `sh_options.lua` | Player options registry and defaults. |
| `sh_player.lua` | Shared player runtime behavior hooks. |
| `sv_yaml.lua` | YAML parsing/usage on server. |

### Core File Details (Line-Level Behavior)

- `sh_character.lua`
  - Registers character variables: `steamID64`, `schema`, `inventory` (hidden/internals), `faction`, `class`, `rank`, `name`, `description`, `model`, `skin`, `creationTime`, `lastPlayed`, `data`.
  - `faction` var: validates chosen faction, builds faction selection UI with a horizontal scroller, uses banner images, draws a glass panel, and sets team/trigger hooks when changed.
  - `class`/`rank`: validates transitions, runs `OnLeave` and `OnSet` hooks, triggers `PlayerLoadout`, and emits `OnCharacterClassChanged` / `OnCharacterRankChanged`.
  - `name` var: strict validation (length, trimming, ASCII-only, no URLs, no punctuation edges, no numbers/underscores, requires 2 words, proper capitalization, no excessive repeats). Supports faction-supplied default names and UI hints.
  - `description` var: single-line text only, no URLs/HTML/control chars, requires words, capitalization, and avoids spam patterns. Adds multiline UI with hints.
  - `model` var: validates model and faction-allowed models, builds a SpawnIcon selection grid, sets payload defaults, and applies model/skin changes with forced skin rules.
  - `skin` var: slider UI (0–16), validates forced-skin rules if faction disallows customization.

- `sh_chat.lua`
  - Defines chat verbs for `ic`, `yell`, and `whisper`.
  - `GetLookTarget` uses eye trace to detect addressed players.
  - `GetVerb` optionally randomizes verbs using `chat.randomized.verbs` option.
  - Implements OOC/LOOC rate limiting via `AX_OOC_TRACK` with delay and rolling-window counts.
  - Registers chat classes: `ic`, `roll`, `yell`, `whisper`, `looc`, `ooc`, `me`, `it`, `event`.
    - Each provides color selection, formatting, and distance-based hearing.
    - `ic`/`yell`/`whisper` add “to you” messaging if looking at a target.
    - `ooc`/`looc` enforce enable/limits; `ooc` is global.
    - `event` is admin-only and global.

- `sh_commands.lua`
  - Admin/system commands: `SetGravity`, `CharSetModel`, `CharSetSkin`, `CharSetName`, `CharGiveItem`, `CharGiveFlags`, `CharTakeFlags`, `CharSetFlags`, `CharSetFaction`, `CharSetClass`, `CharSetRank`, `PlyWhitelist`, `PlyWhitelistAll`, `PlyUnWhitelist`, `PlyUnWhitelistAll`, `PlyRespawn`, `MapRestart`.
  - Player commands: `PM`, `Reply`, `Roll`, `BecomeClass`.
  - `PM` and `Reply` store relays (`pm.last`, `pm.last_since`), play sounds, and validate targets.
  - `CharGiveItem` implements looped adds with success/failure notifications.

- `sh_config.lua`
  - Defines framework config values: language, chat distances/colors, OOC controls, bunnyhop reduction, UI font options, character limits, autosave interval, inventory limits/sync settings, movement speeds, jump power, hands interaction limits, vignette, build menu permissions.

- `sh_ents.lua`
  - Adds `ents.FindInCube(center, radius)` with validation and box-based lookup.

- `sh_flags.lua`
  - Registers default flags:
    - `p` (physgun): strips or gives `weapon_physgun`.
    - `t` (toolgun): strips or gives `gmod_tool`.

- `sh_options.lua`
  - Client options: performance animations, inventory layout and sorting, UI theme and glass styling, UI scale, HUD bar toggles, chat preferences, notification settings, font scaling.
  - Changing theme rebuilds the main menu and shows a dialog.
  - Font scale options reload fonts with a rejoin notice.

- `sh_player.lua`
  - Player variables: `nameVar`, `lastJoin`, `lastLeave`, `playTime`, `data` (hidden).

- `sv_yaml.lua`
  - Reads `database.yml` via `ax.yaml.Read`, falls back to sqlite on missing data, stores result in `ax.database.server`.

---

## 7. Hooks (`gamemode/framework/hooks/`)

Framework hooks that integrate with GMod hook events.

| File | Responsibility |
|------|----------------|
| `cl_hooks.lua` | Client hook handlers (HUD, UI, render). |
| `sh_hooks.lua` | Shared hooks (common runtime events). |
| `sv_hooks.lua` | Server hooks (spawn, character loading, persistence). |

---

## 8. Networking (`gamemode/framework/networking/`)

Handles net messages and version synchronization.

| File | Responsibility |
|------|----------------|
| `cl_networking.lua` | Client net receivers and dispatchers. |
| `cl_version.lua` | Client version checks; ensures compatibility. |
| `sv_networking.lua` | Server net handlers, data sync. |
| `sv_version.lua` | Server version broadcast and validation. |

---

## 9. Interface (`gamemode/framework/interface/`)

Client-side UI (Derma-based).

| File | Responsibility |
|------|----------------|
| `cl_actionbar.lua` | Action bar UI for item actions. |
| `cl_button.lua` | Custom button component. |
| `cl_combobox.lua` | Custom combo box component. |
| `cl_config.lua` | Config UI for admin/player options. |
| `cl_contentsearch.lua` | Content search panel (items, entries). |
| `cl_contentsidebar.lua` | Sidebar for content browser. |
| `cl_derma.lua` | Derma base helpers or overrides. |
| `cl_frame.lua` | Custom frame window. |
| `cl_help_commands.lua` | Help page for commands. |
| `cl_help_factions.lua` | Help page for factions. |
| `cl_help_modules.lua` | Help page for modules. |
| `cl_help_overview.lua` | Overview help page. |
| `cl_help.lua` | Main help UI wrapper. |
| `cl_inventory.lua` | Inventory panel UI. |
| `cl_main_create.lua` | Character creation UI. |
| `cl_main_load.lua` | Character load/select UI. |
| `cl_main_options.lua` | Options tab UI. |
| `cl_main_splash.lua` | Main splash/intro panel. |
| `cl_main.lua` | Main menu root. |
| `cl_scoreboard.lua` | Custom scoreboard UI. |
| `cl_scroller.lua` | Custom scrolling panel. |
| `cl_settings.lua` | Settings UI panel. |
| `cl_spawnmenu_items.lua` | GMod spawnmenu items integration. |
| `cl_store.lua` | Store/shop UI (items, vendors). |
| `cl_tab.lua` | Tab container component. |
| `cl_text.lua` | Text rendering helper widgets. |
| `cl_transition.lua` | UI transition/animation helpers. |

---

## 10. Entities (`entities/`)

### `entities/entities/ax_item.lua`
- World item entity for dropped items.
- Responsible for visual model, interaction, and link to item instance.

### Weapons
#### `entities/weapons/ax_base/`
| File | Responsibility |
|------|----------------|
| `cl_init.lua` | Client-side weapon visuals/logic. |
| `init.lua` | Server-side weapon logic. |
| `shared.lua` | Shared weapon base metadata. |
| `core/sh_anims.lua` | Weapon animation definitions and state. |

#### `entities/weapons/ax_hands/`
| File | Responsibility |
|------|----------------|
| `cl_init.lua` | Client viewmodel hands. |
| `init.lua` | Server logic for hands weapon. |
| `shared.lua` | Shared metadata for hands. |

---

## 11. Items (`gamemode/items/`)

### Base Items
| File | Responsibility |
|------|----------------|
| `base/sh_ammo.lua` | Base item definition for ammunition. |
| `base/sh_outfits.lua` | Base item definition for outfits/clothing. |
| `base/sh_weapons.lua` | Base item definition for weapon items. |

---

## 12. Localization (`gamemode/localization/`)

Language packs for core framework text.

| File | Language |
|------|----------|
| `sh_english.lua` | English |
| `sh_bulgarian.lua` | Bulgarian |
| `sh_german.lua` | German |
| `sh_russian.lua` | Russian |
| `sh_spanish.lua` | Spanish |
| `sh_turkish.lua` | Turkish |

---

## 13. Modules (`gamemode/modules/`)

### Single-File Modules
| File | Responsibility |
|------|----------------|
| `cl_ammo_counter.lua` | Client ammo HUD. |
| `cl_crash_analysis.lua` | Client crash-report helper. |
| `cl_curvy.lua` | Client visual shader/curve effect. |
| `cl_intro.lua` | Client intro/boot splash. |
| `sh_movement.lua` | Shared movement tweaks. |
| `sh_pac3.lua` | PAC3 compatibility module. |
| `sh_proximity.lua` | Proximity chat/voice. |
| `sh_spawn_save.lua` | Player spawn saving. |
| `sh_thirdperson.lua` | Third-person camera. |
| `sh_voices.lua` | Voice system helpers. |

### Folder Modules

Each module folder has its own `boot.lua`, plus optional `core/`, `hooks/`, `interface/`, `libraries/`, `meta/`, `networking/`, `entities/`, and `localization/`.

#### `modules/admin/`
- Admin framework: permissions, admin UI, activity logs.
- Files:
  - `boot.lua`
  - `core/` (commands, options, usergroups, player admin data, activity)
  - `hooks/` (admin hook handlers)
  - `interface/` (admin panels)
  - `localization/` (admin module translations)
  - `networking/` (admin net messages)

#### `modules/animations/`
- Player animation system and overrides.
- Files:
  - `boot.lua`
  - `hooks/` (client/shared/server animation hooks)
  - `libraries/` (animation definitions)
  - `meta/` (player animation methods)
  - `networking/` (animation sync)

#### `modules/chatbox/`
- Custom chatbox UI.
- Files:
  - `boot.lua`
  - `core/` (options, config)
  - `hooks/` (client/server chat hooks)
  - `interface/` (chatbox UI panels)
  - `libraries/` (chatbox utilities)

#### `modules/currencies/`
- Multi-currency system.
- Files:
  - `boot.lua`
  - `core/` (currency commands)
  - `entities/` (`ax_currency` entity)
  - `libraries/` (currency registry)
  - `meta/` (character/player currency methods)

#### `modules/mapscene/`
- Map scene / environment animation system.
- Files:
  - `boot.lua`
  - `core/` (commands, config)
  - `hooks/` (client/shared/server hooks)
  - `libraries/` (mapscene management)
  - `networking/` (sync)

#### `modules/safety/`
- Anti-exploit or safety rules.
- Files:
  - `boot.lua`
  - `core/` (safety commands)
  - `hooks/` (client/shared/server safety hooks)
  - `meta/` (player safety data)

#### `modules/spawns/`
- Advanced spawn system.
- Files:
  - `boot.lua`
  - `core/` (spawn commands)
  - `hooks/` (server hooks)
  - `libraries/` (spawn management)

#### `modules/vendors/`
- Vendor/NPC shop system.
- Files:
  - `boot.lua`
  - `libraries/` (vendor registry)

#### `modules/zones/`
- Zone system: triggers, detection, editing tools.
- Files:
  - `boot.lua`
  - `COMMANDS.md` (module commands reference)
  - `core/` (commands, config, options, zones core)
  - `interface/` (zone editor UI)
  - `libraries/` (editor, evaluation, tracking, persistence)
  - `localization/` (zone translations)
  - `meta/` (player zone data)
  - `networking/` (editor net, tracking net)

### Module File Inventory (Detailed)

#### `modules/admin/`
- `boot.lua` – Admin module registration and bootstrap.
- `core/sh_cami.lua` – CAMI integration and admin privilege wiring.
- `core/sh_commands.lua` – Admin command definitions.
- `core/sh_options.lua` – Admin module configuration/options.
- `core/sh_player.lua` – Admin data on player objects.
- `core/sh_usergroups.lua` – Usergroup and permission definitions.
- `core/sv_activity.lua` – Server activity tracking/storage.
- `hooks/cl_hooks.lua` – Client admin hooks.
- `hooks/sh_hooks.lua` – Shared admin hooks.
- `hooks/sv_activity.lua` – Server activity hooks.
- `hooks/sv_hooks.lua` – Server admin hooks.
- `interface/cl_admin_activity.lua` – Activity UI panel.
- `interface/cl_admin.lua` – Main admin UI.
- `localization/sh_bulgarian.lua` – Admin localization (Bulgarian).
- `localization/sh_english.lua` – Admin localization (English).
- `localization/sh_german.lua` – Admin localization (German).
- `localization/sh_russian.lua` – Admin localization (Russian).
- `localization/sh_spanish.lua` – Admin localization (Spanish).
- `localization/sh_turkish.lua` – Admin localization (Turkish).
- `networking/sv_activity.lua` – Net payloads for activity log.

#### `modules/animations/`
- `boot.lua` – Animation module bootstrap.
- `hooks/cl_hooks.lua` – Client animation hooks.
- `hooks/sh_hooks.lua` – Shared animation hooks.
- `hooks/sv_hooks.lua` – Server animation hooks.
- `libraries/sh_animations.lua` – Animation registry/data.
- `meta/sh_player.lua` – Player animation methods.
- `networking/cl_networking.lua` – Client animation net handlers.

#### `modules/chatbox/`
- `boot.lua` – Chatbox module bootstrap.
- `core/cl_options.lua` – Client chatbox options.
- `core/sh_config.lua` – Shared chatbox config.
- `hooks/cl_hooks.lua` – Client chatbox hooks.
- `hooks/sv_hooks.lua` – Server chatbox hooks.
- `interface/cl_chatbox.lua` – Main chatbox UI.
- `interface/cl_chatbox_bottom.lua` – Bottom input panel.
- `interface/cl_chatbox_history.lua` – History panel.
- `interface/cl_chatbox_recommendations.lua` – Autocomplete/recommendations UI.
- `libraries/cl_chatbox.lua` – Chatbox UI logic.
- `libraries/cl_chatbox_util.lua` – Chatbox utilities.

#### `modules/currencies/`
- `boot.lua` – Currency module bootstrap.
- `core/sh_commands.lua` – Currency commands.
- `entities/entities/ax_currency.lua` – Currency world entity.
- `libraries/sh_currencies.lua` – Currency registry.
- `meta/sh_character.lua` – Character currency methods.
- `meta/sh_player.lua` – Player currency helpers.

#### `modules/mapscene/`
- `boot.lua` – Mapscene module bootstrap.
- `core/sh_commands.lua` – Mapscene commands.
- `core/sh_config.lua` – Mapscene configuration.
- `hooks/cl_hooks.lua` – Client mapscene hooks.
- `hooks/sh_hooks.lua` – Shared mapscene hooks.
- `hooks/sv_hooks.lua` – Server mapscene hooks.
- `libraries/cl_mapscene.lua` – Client mapscene rendering.
- `libraries/sh_mapscene.lua` – Shared mapscene state.
- `libraries/sv_mapscene.lua` – Server mapscene control.
- `networking/cl_networking.lua` – Client mapscene net handlers.
- `networking/sv_networking.lua` – Server mapscene net handlers.

#### `modules/safety/`
- `boot.lua` – Safety module bootstrap.
- `core/sh_commands.lua` – Safety/anti-exploit commands.
- `hooks/cl_hooks.lua` – Client safety hooks.
- `hooks/sh_hooks.lua` – Shared safety hooks.
- `hooks/sv_hooks.lua` – Server safety hooks.
- `meta/sh_player.lua` – Shared player safety data.
- `meta/sv_player.lua` – Server-only safety data.

#### `modules/spawns/`
- `boot.lua` – Spawn module bootstrap.
- `core/sh_commands.lua` – Spawn commands.
- `hooks/sv_hooks.lua` – Server spawn hooks.
- `libraries/sv_spawns.lua` – Spawn management.

#### `modules/vendors/`
- `boot.lua` – Vendor module bootstrap.
- `libraries/sh_vendors.lua` – Vendor registry/logic.

#### `modules/zones/`
- `boot.lua` – Zone module bootstrap.
- `COMMANDS.md` – Zone module commands reference.
- `core/sh_commands.lua` – Zone commands.
- `core/sh_config.lua` – Zone configuration.
- `core/sh_options.lua` – Zone options.
- `core/sh_zones.lua` – Zone core logic.
- `interface/cl_zone_editor.lua` – Zone editor UI.
- `libraries/cl_debug.lua` – Zone debug helpers.
- `libraries/cl_editor.lua` – Client zone editor logic.
- `libraries/cl_tracking.lua` – Client zone tracking.
- `libraries/sh_editor.lua` – Shared editor utilities.
- `libraries/sh_evaluation.lua` – Shared zone evaluation.
- `libraries/sh_zones.lua` – Shared zone data.
- `libraries/sv_networking.lua` – Zone networking (server).
- `libraries/sv_persistence.lua` – Zone persistence (server).
- `libraries/sv_tracking.lua` – Zone tracking (server).
- `localization/sh_bulgarian.lua` – Zone localization (Bulgarian).
- `localization/sh_english.lua` – Zone localization (English).
- `localization/sh_german.lua` – Zone localization (German).
- `localization/sh_russian.lua` – Zone localization (Russian).
- `localization/sh_spanish.lua` – Zone localization (Spanish).
- `localization/sh_turkish.lua` – Zone localization (Turkish).
- `meta/sh_player.lua` – Player zone data.
- `networking/cl_networking.lua` – Zone editor networking (client).
- `networking/sv_editor.lua` – Zone editor networking (server).

---

## 14. Content Assets (`content/`)

### Materials
- `content/materials/parallax/`

#### `content/materials/parallax/banners/`
- `unknown.png`

#### `content/materials/parallax/overlays/`
- `radial_gradient.png`
- `vignette.png`
- `vignette_cinematic.png`

#### `content/materials/parallax/icons/`
- `add-to-queue.png`
- `adjust-alt.png`
- `adjust.png`
- `alarm-add.png`
- `alarm-exclamation.png`
- `alarm-off.png`
- `alarm-snooze.png`
- `alarm.png`
- `album.png`
- `ambulance.png`
- `analyse.png`
- `angry.png`
- `arch.png`
- `archive-in.png`
- `archive-out.png`
- `archive.png`
- `area.png`
- `arrow-from-bottom.png`
- `arrow-from-left.png`
- `arrow-from-right.png`
- `arrow-from-top.png`
- `arrow-to-bottom.png`
- `arrow-to-left.png`
- `arrow-to-right.png`
- `arrow-to-top.png`
- `award.png`
- `baby-carriage.png`
- `backpack.png`
- `badge-check.png`
- `badge-dollar.png`
- `badge.png`
- `baguette.png`
- `ball.png`
- `balloon.png`
- `band-aid.png`
- `bank.png`
- `bar-chart-alt-2.png`
- `bar-chart-square.png`
- `barcode.png`
- `baseball.png`
- `basket.png`
- `basketball.png`
- `bath.png`
- `battery-charging.png`
- `battery-full.png`
- `battery-low.png`
- `battery.png`
- `bed.png`
- `been-here.png`
- `beer.png`
- `bell-minus.png`
- `bell-off.png`
- `bell-plus.png`
- `bell-ring.png`
- `bell.png`
- `bible.png`
- `binoculars.png`
- `blanket.png`
- `bolt-circle.png`
- `bolt.png`
- `bomb.png`
- `bone.png`
- `bong.png`
- `book-add.png`
- `book-alt.png`
- `book-bookmark.png`
- `book-content.png`
- `book-heart.png`
- `book-open.png`
- `book-reader.png`
- `book.png`
- `bookmark-alt-minus.png`
- `bookmark-alt-plus.png`
- `bookmark-alt.png`
- `bookmark-heart.png`
- `bookmark-minus.png`
- `bookmark-plus.png`
- `bookmark-star.png`
- `bookmark.png`
- `bookmarks.png`
- `bot.png`
- `bowl-hot.png`
- `bowl-rice.png`
- `bowling-ball.png`
- `box.png`
- `brain.png`
- `briefcase-alt-2.png`
- `briefcase-alt.png`
- `briefcase.png`
- `brightness-half.png`
- `brightness.png`
- `brush-alt.png`
- `brush.png`
- `bug-alt.png`
- `bug.png`
- `building-house.png`
- `building.png`
- `buildings.png`
- `bulb.png`
- `bullseye.png`
- `buoy.png`
- `bus-school.png`
- `bus.png`
- `business.png`
- `cabinet.png`
- `cable-car.png`
- `cake.png`
- `calculator.png`
- `calendar-alt.png`
- `calendar-check.png`
- `calendar-edit.png`
- `calendar-event.png`
- `calendar-exclamation.png`
- `calendar-heart.png`
- `calendar-minus.png`
- `calendar-plus.png`
- `calendar-star.png`
- `calendar-week.png`
- `calendar-x.png`
- `calendar.png`
- `camera-home.png`
- `camera-movie.png`
- `camera-off.png`
- `camera-plus.png`
- `camera.png`
- `capsule.png`
- `captions.png`
- `car-battery.png`
- `car-crash.png`
- `car-garage.png`
- `car-mechanic.png`
- `car-wash.png`
- `car.png`
- `card.png`
- `caret-down-circle.png`
- `caret-down-square.png`
- `caret-left-circle.png`
- `caret-left-square.png`
- `caret-right-circle.png`
- `caret-right-square.png`
- `caret-up-circle.png`
- `caret-up-square.png`
- `carousel.png`
- `cart-add.png`
- `cart-alt.png`
- `cart-download.png`
- `cart.png`
- `castle.png`
- `cat.png`
- `category-alt.png`
- `category.png`
- `cctv.png`
- `certification.png`
- `chalkboard.png`
- `chart.png`
- `chat.png`
- `check-circle.png`
- `check-shield.png`
- `check-square.png`
- `checkbox-checked.png`
- `checkbox-minus.png`
- `checkbox.png`
- `cheese.png`
- `chess.png`
- `chevron-down-circle.png`
- `chevron-down-square.png`
- `chevron-down.png`
- `chevron-left-circle.png`
- `chevron-left-square.png`
- `chevron-left.png`
- `chevron-right-circle.png`
- `chevron-right-square.png`
- `chevron-right.png`
- `chevron-up-circle.png`
- `chevron-up-square.png`
- `chevron-up.png`
- `chevrons-down.png`
- `chevrons-left.png`
- `chevrons-right.png`
- `chevrons-up.png`
- `chip.png`
- `church.png`
- `circle-half.png`
- `circle-quarter.png`
- `circle-three-quarter.png`
- `circle.png`
- `city.png`
- `clinic.png`
- `cloud-download.png`
- `cloud-lightning.png`
- `cloud-rain.png`
- `cloud-upload.png`
- `cloud.png`
- `coffee-alt.png`
- `coffee-bean.png`
- `coffee-togo.png`
- `coffee.png`
- `cog.png`
- `coin-stack.png`
- `coin.png`
- `collection.png`
- `color-fill.png`
- `color.png`
- `comment-add.png`
- `comment-check.png`
- `comment-detail.png`
- `comment-dots.png`
- `comment-edit.png`
- `comment-error.png`
- `comment-minus.png`
- `comment-x.png`
- `comment.png`
- `compass.png`
- `component.png`
- `confused.png`
- `contact.png`
- `conversation.png`
- `cookie.png`
- `cool.png`
- `copy-alt.png`
- `copy.png`
- `copyright.png`
- `coupon.png`
- `credit-card-alt.png`
- `credit-card-front.png`
- `credit-card.png`
- `cricket-ball.png`
- `crop.png`
- `crown.png`
- `cube-alt.png`
- `cube.png`
- `cuboid.png`
- `customize.png`
- `cylinder.png`
- `dashboard.png`
- `data.png`
- `detail.png`
- `devices.png`
- `diamond.png`
- `dice-1.png`
- `dice-2.png`
- `dice-3.png`
- `dice-4.png`
- `dice-5.png`
- `dice-6.png`
- `direction-left.png`
- `direction-right.png`
- `directions.png`
- `disc.png`
- `discord-alt.png`
- `discord.png`
- `discount.png`
- `dish.png`
- `dislike.png`
- `dizzy.png`
- `dock-bottom.png`
- `dock-left.png`
- `dock-right.png`
- `dock-top.png`
- `dog.png`
- `dollar-circle.png`
- `donate-blood.png`
- `donate-heart.png`
- `door-open.png`
- `doughnut-chart.png`
- `down-arrow-alt.png`
- `down-arrow-circle.png`
- `down-arrow-square.png`
- `down-arrow.png`
- `download.png`
- `downvote.png`
- `drink.png`
- `droplet-half.png`
- `droplet.png`
- `dryer.png`
- `duplicate.png`
- `edit-alt.png`
- `edit-location.png`
- `edit.png`
- `eject.png`
- `envelope-open.png`
- `envelope.png`
- `eraser.png`
- `error-alt.png`
- `error-circle.png`
- `error.png`
- `ev-station.png`
- `exit.png`
- `extension.png`
- `eyedropper.png`
- `face-mask.png`
- `face.png`
- `factory.png`
- `fast-forward-circle.png`
- `file-archive.png`
- `file-blank.png`
- `file-css.png`
- `file-doc.png`
- `file-export.png`
- `file-find.png`
- `file-gif.png`
- `file-html.png`
- `file-image.png`
- `file-import.png`
- `file-jpg.png`
- `file-js.png`
- `file-json.png`
- `file-md.png`
- `file-pdf.png`
- `file-plus.png`
- `file-png.png`
- `file-txt.png`
- `file.png`
- `film.png`
- `filter-alt.png`
- `first-aid.png`
- `flag-alt.png`
- `flag-checkered.png`
- `flag.png`
- `flame.png`
- `flask.png`
- `flip-circle.png`
- `florist.png`
- `folder-minus.png`
- `folder-open.png`
- `folder-plus.png`
- `folder.png`
- `food-menu.png`
- `fridge.png`
- `game.png`
- `gas-pump.png`
- `ghost.png`
- `gift.png`
- `graduation.png`
- `grid-alt.png`
- `grid.png`
- `group.png`
- `guitar-amp.png`
- `hand-down.png`
- `hand-left.png`
- `hand-right.png`
- `hand-up.png`
- `hand.png`
- `happy-alt.png`
- `happy-beaming.png`
- `happy-heart-eyes.png`
- `happy.png`
- `hard-hat.png`
- `hdd.png`
- `heart-circle.png`
- `heart-square.png`
- `heart.png`
- `help-circle.png`
- `hide.png`
- `home-alt-2.png`
- `home-circle.png`
- `home-heart.png`
- `home-smile.png`
- `home.png`
- `hot.png`
- `hotel.png`
- `hourglass-bottom.png`
- `hourglass-top.png`
- `hourglass.png`
- `id-card.png`
- `image-add.png`
- `image-alt.png`
- `image.png`
- `inbox.png`
- `info-circle.png`
- `info-square.png`
- `injection.png`
- `institution.png`
- `invader.png`
- `joystick-alt.png`
- `joystick-button.png`
- `joystick.png`
- `key.png`
- `keyboard.png`
- `label.png`
- `landmark.png`
- `landscape.png`
- `laugh.png`
- `layer-minus.png`
- `layer-plus.png`
- `layer.png`
- `layout.png`
- `leaf.png`
- `left-arrow-alt.png`
- `left-arrow-circle.png`
- `left-arrow-square.png`
- `left-arrow.png`
- `left-down-arrow-circle.png`
- `left-top-arrow-circle.png`
- `lemon.png`
- `like.png`
- `location-plus.png`
- `lock-alt.png`
- `lock-open-alt.png`
- `lock-open.png`
- `lock.png`
- `log-in-circle.png`
- `log-in.png`
- `log-out-circle.png`
- `log-out.png`
- `low-vision.png`
- `magic-wand.png`
- `magnet.png`
- `map-alt.png`
- `map-pin.png`
- `map.png`
- `mask.png`
- `medal.png`
- `megaphone.png`
- `meh-alt.png`
- `meh-blank.png`
- `meh.png`
- `memory-card.png`
- `message-add.png`
- `message-alt-add.png`
- `message-alt-check.png`
- `message-alt-detail.png`
- `message-alt-dots.png`
- `message-alt-edit.png`
- `message-alt-error.png`
- `message-alt-minus.png`
- `message-alt-x.png`
- `message-alt.png`
- `message-check.png`
- `message-detail.png`
- `message-dots.png`
- `message-edit.png`
- `message-error.png`
- `message-minus.png`
- `message-rounded-add.png`
- `message-rounded-check.png`
- `message-rounded-detail.png`
- `message-rounded-dots.png`
- `message-rounded-edit.png`
- `message-rounded-error.png`
- `message-rounded-minus.png`
- `message-rounded-x.png`
- `message-rounded.png`
- `message-square-add.png`
- `message-square-check.png`
- `message-square-detail.png`
- `message-square-dots.png`
- `message-square-edit.png`
- `message-square-error.png`
- `message-square-minus.png`
- `message-square-x.png`
- `message-square.png`
- `message-x.png`
- `message.png`
- `meteor.png`
- `microchip.png`
- `microphone-alt.png`
- `microphone-off.png`
- `microphone.png`
- `minus-circle.png`
- `minus-square.png`
- `mobile-vibration.png`
- `mobile.png`
- `moon.png`
- `mouse-alt.png`
- `mouse.png`
- `movie-play.png`
- `movie.png`
- `music.png`
- `navigation.png`
- `network-chart.png`
- `news.png`
- `no-entry.png`
- `note.png`
- `notepad.png`
- `notification-off.png`
- `notification.png`
- `objects-horizontal-center.png`
- `objects-horizontal-left.png`
- `objects-horizontal-right.png`
- `objects-vertical-bottom.png`
- `objects-vertical-center.png`
- `objects-vertical-top.png`
- `offer.png`
- `package.png`
- `paint-roll.png`
- `paint.png`
- `palette.png`
- `paper-plane.png`
- `parking.png`
- `party.png`
- `paste.png`
- `pear.png`
- `pen.png`
- `pencil.png`
- `phone-call.png`
- `phone-incoming.png`
- `phone-off.png`
- `phone-outgoing.png`
- `phone.png`
- `photo-album.png`
- `piano.png`
- `pie-chart-alt-2.png`
- `pie-chart-alt.png`
- `pie-chart.png`
- `pin.png`
- `pizza.png`
- `plane-alt.png`
- `plane-land.png`
- `plane-take-off.png`
- `plane.png`
- `planet.png`
- `playlist.png`
- `plug.png`
- `plus-circle.png`
- `plus-square.png`
- `pointer.png`
- `polygon.png`
- `popsicle.png`
- `printer.png`
- `purchase-tag-alt.png`
- `purchase-tag.png`
- `pyramid.png`
- `quote-alt-left.png`
- `quote-alt-right.png`
- `quote-left.png`
- `quote-right.png`
- `quote-single-left.png`
- `quote-single-right.png`
- `radiation.png`
- `radio.png`
- `receipt.png`
- `rectangle.png`
- `registered.png`
- `rename.png`
- `report.png`
- `rewind-circle.png`
- `right-arrow-alt.png`
- `right-arrow-circle.png`
- `right-arrow-square.png`
- `right-arrow.png`
- `right-down-arrow-circle.png`
- `right-top-arrow-circle.png`
- `rocket.png`
- `ruler.png`
- `sad.png`
- `save.png`
- `school.png`
- `search-alt-2.png`
- `search.png`
- `select-multiple.png`
- `send.png`
- `server.png`
- `shapes.png`
- `share-alt.png`
- `share.png`
- `shield-alt-2.png`
- `shield-minus.png`
- `shield-plus.png`
- `shield-x.png`
- `shield.png`
- `ship.png`
- `shocked.png`
- `shopping-bag-alt.png`
- `shopping-bag.png`
- `shopping-bags.png`
- `show.png`
- `shower.png`
- `skip-next-circle.png`
- `skip-previous-circle.png`
- `skull.png`
- `sleepy.png`
- `slideshow.png`
- `smile.png`
- `sort-alt.png`
- `spa.png`
- `speaker.png`
- `spray-can.png`
- `spreadsheet.png`
- `square-rounded.png`
- `square.png`
- `star-half.png`
- `star.png`
- `sticker.png`
- `stopwatch.png`
- `store-alt.png`
- `store.png`
- `sun.png`
- `sushi.png`
- `t-shirt.png`
- `tachometer.png`
- `tag-alt.png`
- `tag-x.png`
- `tag.png`
- `taxi.png`
- `tennis-ball.png`
- `terminal.png`
- `thermometer.png`
- `time-five.png`
- `time.png`
- `timer.png`
- `tired.png`
- `to-top.png`
- `toggle-left.png`
- `toggle-right.png`
- `tone.png`
- `torch.png`
- `traffic-barrier.png`
- `traffic-cone.png`
- `traffic.png`
- `train.png`
- `trash-alt.png`
- `trash.png`
- `tree-alt.png`
- `tree.png`
- `trophy.png`
- `truck.png`
- `tv.png`
- `universal-access.png`
- `up-arrow-alt.png`
- `up-arrow-circle.png`
- `up-arrow-square.png`
- `up-arrow.png`
- `upside-down.png`
- `upvote.png`
- `user-account.png`
- `user-badge.png`
- `user-check.png`
- `user-circle.png`
- `user-detail.png`
- `user-minus.png`
- `user-pin.png`
- `user-plus.png`
- `user-rectangle.png`
- `user-voice.png`
- `user-x.png`
- `user.png`
- `vector.png`
- `vial.png`
- `video-off.png`
- `video-plus.png`
- `video-recording.png`
- `video.png`
- `videos.png`
- `virus-block.png`
- `virus.png`
- `volume-full.png`
- `volume-low.png`
- `volume-mute.png`
- `volume.png`
- `wallet-alt.png`
- `wallet.png`
- `washer.png`
- `watch-alt.png`
- `watch.png`
- `webcam.png`
- `widget.png`
- `window-alt.png`
- `wine.png`
- `wink-smile.png`
- `wink-tongue.png`
- `wrench.png`
- `x-circle.png`
- `x-square.png`
- `x.png`
- `yin-yang.png`
- `zap.png`
- `zoom-in.png`
- `zoom-out.png`

### Fonts
- `content/resource/fonts/`
  - `gordin-black.ttf`
  - `gordin-bold.ttf`
  - `gordin-light.ttf`
  - `gordin-regular.ttf`
  - `gordin-semibold.ttf`
  - `inter-italic.ttf`
  - `inter.ttf`

### Shaders
- `content/shaders/fxc/`
  - `curvy_inverted_ps30.vcs`
  - `curvy_ps30.vcs`

### Sounds
- `content/sound/parallax/ui/`
  - `credits_names_in.ogg`
  - `credits_names_out.ogg`
  - `dossier_intro_text_line_01.ogg`
  - `dossier_intro_text_line_02.ogg`
  - `dossier_intro_text_line_03.ogg`
  - `dossier_mission_failure_text_line_01.ogg`
  - `dossier_mission_failure_text_line_02.ogg`
  - `dossier_mission_failure_text_line_03.ogg`
  - `dossier_mission_failure_text_line.ogg`
  - `dossier_text_line_01.ogg`
  - `dossier_text_line_02.ogg`
  - `dossier_text_line_03.ogg`
  - `dossier_text_singular_01.ogg`
  - `dossier_text_singular_02.ogg`
  - `dossier_text_singular_03.ogg`
  - `dossier_text_singular_04.ogg`
  - `dossier_text_singular_05.ogg`
  - `dossier_text_singular_06.ogg`
  - `dossier_text_singular_07.ogg`
  - `dossier_text_singular_08.ogg`
  - `hint.ogg`
  - `knock_knock.ogg`
  - `pano_affirm.ogg`
  - `pano_appear.ogg`
  - `pano_menu_close.ogg`
  - `pano_menu_return.ogg`
  - `pano_rollover.ogg`
  - `pano_scroll_click.ogg`
  - `pano_select.ogg`
  - `pano_sub_menu.ogg`
  - `pano_toggle.ogg`
  - `notifications/error.wav`
  - `notifications/generic.wav`
  - `notifications/hint.wav`

---

## 15. Documentation & Manuals (`docs/`, `manuals/`)

### `docs/`
- `docs/index.md` – MkDocs landing content.
- `docs/assets/` – Static assets (logo, CSS, favicon).
  - `docs/assets/images/favicon.png`
  - `docs/assets/images/parallax-logo.png`
  - `docs/assets/stylesheets/extra.css`

### `manuals/`
Handwritten documentation:
- `00-INTRODUCTION.md`
- `01-ARCHITECTURE.md`
- `02-CORE_SYSTEMS.md`
- `03-SCHEMA_DEVELOPMENT.md`
- `04-ADVANCED_TOPICS.md`
- `05-API_REFERENCE.md`
- `06-EXAMPLES.md`
- `07-BEST_PRACTICES.md`
- `README.md` (table of contents)
- `intermediate/` (database setup, item creation, modules, style)

---

## 16. Tools & Automation (`tools/`)

- `tools/generate_docs.py`  
  Lua annotation → MkDocs generator.  
  Used by GitHub Actions to build API pages.

---

## 17. Root Files

| File | Purpose |
|------|---------|
| `.editorconfig` | Editor formatting rules. |
| `.gitattributes` | Git attributes. |
| `.gitignore` | Ignored files. |
| `.glualint.json` | Glua lint configuration. |
| `LICENSE` | License terms. |
| `README.md` | Repository overview and links. |
| `parallax.txt` | Framework info or metadata. |
| `version.json` | Version metadata. |

---

## 18. Integration Notes & Extension Points

### Primary Extension Points
- **Schema**: `gamemode/schema` directories and files.
- **Modules**: `gamemode/modules` add functionality without schema edits.
- **Hooks**: `SCHEMA:HookName`, `MODULE:HookName`
- **Networking**: `ax.net` wrappers
- **Character vars**: `ax.character:RegisterVar`

### Common Flow
1. Framework boot loads directories.
2. Schema boot loads schema content.
3. Modules load after schema.
4. UI and hooks initialized.

---

## 19. Summary

This guide enumerates **every file and subsystem** in the Parallax framework repository.  
Use it to understand the full structure, locate features, and safely extend the framework with schema content or modules.