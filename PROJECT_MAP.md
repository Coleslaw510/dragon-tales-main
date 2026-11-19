# DragonTales — Project Map

Read this file first in every new chat. Do not scan the repo unless a task names a file.

## Game

iOS dragon-breeding park (DragonVale-style): place habitats on an island, breed element combos, incubate eggs, feed and level dragons, collect coin income, shop, and a dragon book. Ships as an unsigned sideload IPA (not App Store).

## Stack

Swift 5, SpriteKit, iOS 16+, SwiftUI wrapper (`SpriteView`). XcodeGen (`project.yml`). Unsigned CI IPA via GitHub Actions (`macos-15`, `CODE_SIGNING_ALLOWED=NO`). Bundle ID `com.coleslaw510.dragontales`. No new art — use `Art/` and `Data/` only.

## Layout

- `PROJECT_MAP.md` — this file (the one doc a future chat should read)
- `Art/dragons/` — 145 dragon sprites + 12 eggs (`{id}.png`, `egg_{element|rare|legendary}.png`)
- `Art/habitats/` — `habitat_{element}.png` (10 elements)
- `Art/buildings/` — grove, hatchery, farm, 6 decorations
- `Art/tiles/` — island base, sky, grass/path tiles, cliffs, clouds, expansion plots
- `Art/ui/` — coin/gem/food/xp icons, app icons
- `Art/fx/` — Kenney Particle Pack subset (sparkles, stars, smoke/poof, glow, magic circles)
- `Audio/sfx/` — Kenney Interface Sounds + RPG Audio (tap, confirm, open/close, hatch pop, coins); `.m4a`
- `Audio/music/` — Tiny Puzzle BGM Loops (moss garden idle, tea time shop); `.m4a`
- `Fonts/` — Fredoka (OFL) + `OFL.txt`
- `CREDITS.md` — sources, authors, and licenses for the packs above
- `Data/dragons.json` — species catalog
- `Data/economy.json` — costs, timers, shop, island, starting layout
- `App/DragonTalesApp.swift` — `@main` SwiftUI entry (holds one `GameScene`)
- `App/GameScene.swift` — root scene: state, camera, HUD, tick (0.5s), autosave
- `App/GameScene+Input.swift` — touch routing, pan, pinch zoom, tap-to-select
- `App/GameScene+Actions.swift` — shop buys, placement, hatch, collect, selection info
- `App/Data/Models.swift` — catalog structs + Codable save structs
- `App/Data/Catalog.swift` — load `Data/*.json`, textures from `Art/`, prices/timers
- `App/Game/GameState.swift` — park rules: eggs, habitats, hatching, move, discovered species
- `App/Game/GameTimers.swift` — generic `TimerRef` (egg now, breeding later) + gem speed-up cost/skip
- `App/Economy/Wallet.swift` — gold, gems, per-dragon gold/hr, habitat cap (= gold/hr x `storageHours` 4), collect
- `App/Save/SaveStore.swift` — JSON save in Documents, new game
- `App/Island/IslandGrid.swift` — 96pt grid, 2x2 footprints, grass-oval bounds
- `App/Island/IslandBuilder.swift` — island + clouds backdrop, building nodes
- `App/Island/CameraController.swift` — pan/zoom clamp
- `App/Island/PlacementController.swift` — ghost + footprint marker drag/snap (new habitat or move)
- `App/Island/GameScene+Placement.swift` — new-habitat placement, long-press move mode, confirm/cancel
- `App/Island/HabitatNode.swift` — habitat sprite, wandering dragons, coin badge (>= 50% of cap)
- `App/Island/CaveNode.swift` — Breeding Cave (grove art) + countdown / egg-ready pill
- `App/Breeding/BreedingOdds.swift` — offspring pool + odds, rarity weights and breed timers (tuning constants)
- `App/Breeding/BreedingController.swift` — cave cost, place cave, start breed, collect egg to nursery
- `App/Breeding/BreedingPanel.swift` — pick 2 dragons, offspring list with %, confirm
- `App/Breeding/GameScene+Breeding.swift` — cave tap/buy/collect flows, info text
- `App/Island/NurseryNode.swift` — nursery (hatchery art) + shape-drawn nest holding `hatchery.slots` eggs
- `App/Dragons/DragonNode.swift` — park dragon (bob, random-walk wander, faces direction; art faces left)
- `App/Shop/ShopOverlay.swift`, `App/Shop/ShopItems.swift` — section menu (Eggs / Habitats / Buildings) + item grids
- `App/Book/DragonBook.swift` — Dragon Book: paged grid, silhouettes for undiscovered
- `App/UI/HUD.swift` — gold, gems, Shop, book button, info bar, speed-up button, toasts, placement buttons
- `App/UI/ModalPanel.swift`, `App/UI/Prompts.swift` — overlays, habitat picker
- `App/UI/ButtonNode.swift`, `App/UI/Effects.swift`, `App/UI/Format.swift` — buttons, actions, formatting
- `App/Resources/Assets.xcassets` — AppIcon
- `project.yml` — XcodeGen spec (App + Art + Data + Audio + Fonts)
- `.github/workflows/build.yml` — unsigned IPA on push to `main`

## Planned files

Add these when the milestone starts. One feature per file; keep files under ~300 lines.

- `App/Breeding/HatcheryController.swift` — move nursery timers here if breeding needs it

## Data models (from JSON)

**Elements** (10): fire, water, earth, air, lightning, plant, ice, light, metal, star (renamed from shadow).

**Rarities:** common, rare, epic, legendary.

**Dragon species** (145): `id`, `name`, `elements[]`, `rarity`, `kind` (base 10 / combo 90 / reward 45), `sprite`, `blurb`, `incubateSeconds`, `breedSeconds`, `incomePerMinute`, `baseHP`, `baseAttack`. Base = one element. Combo = two elements (`economy.json` `breeding.recipes` is empty; derive the pair from the two elements). Reward = one element, not bred in the park.

**Economy:** starting coins/gems/food and layout (grove, hatchery, fire habitat + Blaze, farm). Habitats: capacity 4, coin income, storage cap, 12h offline cap. Breeding costs 120 coins; rarity weights 50/28/14/6. Hatchery: 4 slots; fallback seconds by rarity. Farms: 4 crops with grow timers and food yields. Feeding: 1 food, +8 XP, max level 10, `xpToNext`. Shop: base egg 220, habitat 380, 6 decorations. Island grid `cell` 96, zoom 0.55–5.2, 4 plots. Gems skip timers at 90s/gem. Player XP: 30 thresholds; awards for hatch/discover/feed/breed. `sellRefundRatio` 0.5.

## Conventions

- One feature per session and per file. Do not rewrite unrelated files.
- No file over ~300 lines; split rather than grow.
- Do not generate or replace art. Filenames stay as shipped (including `icon_gem.png`).
- New chats: start from this map plus the one milestone you are doing. After a milestone, append one line to Session log and open a fresh chat for the next.
- Keep diffs and replies short.

## Build / IPA

Local: `brew install xcodegen && xcodegen generate`, then `xcodebuild -project DragonTales.xcodeproj -scheme DragonTales -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' ARCHS=arm64 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" build`. Zip `Payload/DragonTales.app` as `DragonTales.ipa`.

CI: push to `main` or run **Build unsigned IPA**; download the artifact. Sideload with AltStore, Sideloadly, or similar. The repo is public so macOS Actions minutes stay free.

## Milestones

- [x] 1. Skeleton + island scene — `App/DragonTalesApp.swift`, `App/GameScene.swift` (extend), later `App/Island/IslandScene.swift`
- [x] 2. Loop polish — wander, gems + speed-up, nursery nest, 50% coin badge, 4h cap, move mode, shop menu, Dragon Book
- [ ] 3. Habitats placement — `App/Island/IslandScene.swift`, `App/Island/HabitatNode.swift`
- [x] 4. Breeding — Breeding Cave (done as Milestone 3) — `App/Breeding/`
- [ ] 5. Incubation / hatching timers — `App/Breeding/HatcheryController.swift`
- [ ] 6. Feeding / leveling — `App/Dragons/DragonNode.swift`
- [ ] 7. Economy / coins / income — `App/Economy/Wallet.swift`
- [ ] 8. Shop — `App/Shop/ShopOverlay.swift`
- [ ] 9. Dragon book — `App/Book/DragonBook.swift`
- [ ] 10. Save / load — `App/Save/SaveStore.swift`
- [ ] 11. Polish / sound — `App/UI/HUD.swift`, assets in `Art/fx/`, `Audio/`, `Fonts/` (not wired up yet)

## Session log

- 2026-11-18: Repo created (public; now Coleslaw510/dragon-tales-main). Shipped art + JSON imported from the Nov 12 IPA. SpriteKit stub + unsigned IPA workflow added. Milestone 1 compiling stub is in place; island scene not built yet.
- 2026-11-18: Milestone 1 baseline loop done (d5542de): island pan/zoom/select, gold HUD (start = habitat 380 + egg 220), shop tabs, habitat placement, nursery timers + hatch, habitat picker, income/collect, actions, Codable save. IPA build passed: https://github.com/Coleslaw510/dragon-tales-main/actions/runs/44445549337
- 2026-11-18: Milestone 2 loop polish done (d5a945c, 586c0ea): dragon wander, gems + generic timer speed-up, multi-egg nest, coin badge at 50%, cap = gold/hr x 4h, long-press move mode, shop section menu, Dragon Book. IPA build passed: https://github.com/Coleslaw510/dragon-tales-main/actions/runs/44448635208
- 2026-11-18: Milestone 3 Breeding Cave done (182f211): cave in shop Buildings (400 gold, place/move), pick 2 dragons with offspring % list, BreedingOdds.swift (subset + 2+ elements, same base -> base, rarity weights 50/28/14/6, timers by rarity), gem speed-up, egg to nursery (blocked when full). IPA build passed: https://github.com/Coleslaw510/dragon-tales-main/actions/runs/44450220218
- 2026-11-19: Added free polish assets (Kenney particles + SFX, Tiny Puzzle BGM loops, Fredoka). See CREDITS.md.
