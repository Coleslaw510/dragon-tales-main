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
- `Data/dragons.json` — species catalog
- `Data/economy.json` — costs, timers, shop, island, starting layout
- `App/DragonTalesApp.swift` — `@main` SwiftUI entry (holds one `GameScene`)
- `App/GameScene.swift` — root scene: state, camera, HUD, tick (0.5s), autosave
- `App/GameScene+Input.swift` — touch routing, pan, pinch zoom, tap-to-select
- `App/GameScene+Actions.swift` — shop buys, placement, hatch, collect, selection info
- `App/Data/Models.swift` — catalog structs + Codable save structs
- `App/Data/Catalog.swift` — load `Data/*.json`, textures from `Art/`, prices/timers
- `App/Game/GameState.swift` — park rules: eggs, habitats, hatching
- `App/Economy/Wallet.swift` — gold, per-dragon gold/hr, habitat storage cap, collect
- `App/Save/SaveStore.swift` — JSON save in Documents, new game
- `App/Island/IslandGrid.swift` — 96pt grid, 2x2 footprints, grass-oval bounds
- `App/Island/IslandBuilder.swift` — island + clouds backdrop, building nodes
- `App/Island/CameraController.swift` — pan/zoom clamp
- `App/Island/PlacementController.swift` — habitat ghost drag/snap/confirm
- `App/Island/HabitatNode.swift` — habitat sprite, dragons, stored-coin badge
- `App/Island/NurseryNode.swift` — nursery (hatchery art) + egg countdowns
- `App/Dragons/DragonNode.swift` — park dragon (idle bob)
- `App/Shop/ShopOverlay.swift` — Eggs / Habitats tabs
- `App/UI/HUD.swift` — gold, Shop, info bar, toasts, placement buttons
- `App/UI/ModalPanel.swift`, `App/UI/Prompts.swift` — overlays, habitat picker
- `App/UI/ButtonNode.swift`, `App/UI/Effects.swift`, `App/UI/Format.swift` — buttons, actions, formatting
- `App/Resources/Assets.xcassets` — AppIcon
- `project.yml` — XcodeGen spec
- `.github/workflows/build.yml` — unsigned IPA on push to `main`

## Planned files

Add these when the milestone starts. One feature per file; keep files under ~300 lines.

- `App/Breeding/BreedingController.swift` — element-pair recipes, costs, results
- `App/Breeding/HatcheryController.swift` — move nursery timers here if breeding needs it
- `App/Book/DragonBook.swift` — discovered species collection

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

- [ ] 1. Skeleton + island scene — `App/DragonTalesApp.swift`, `App/GameScene.swift` (extend), later `App/Island/IslandScene.swift`
- [ ] 2. Data loading — `App/Data/Catalog.swift`, `App/Data/Models.swift`, `Data/*.json`
- [ ] 3. Habitats placement — `App/Island/IslandScene.swift`, `App/Island/HabitatNode.swift`
- [ ] 4. Breeding — `App/Breeding/BreedingController.swift`
- [ ] 5. Incubation / hatching timers — `App/Breeding/HatcheryController.swift`
- [ ] 6. Feeding / leveling — `App/Dragons/DragonNode.swift`
- [ ] 7. Economy / coins / income — `App/Economy/Wallet.swift`
- [ ] 8. Shop — `App/Shop/ShopOverlay.swift`
- [ ] 9. Dragon book — `App/Book/DragonBook.swift`
- [ ] 10. Save / load — `App/Save/SaveStore.swift`
- [ ] 11. Polish / sound — `App/UI/HUD.swift`, audio TBD (no sounds in repo yet)

## Session log

- 2026-11-18: Repo created (public, ColeMcClintock/dragon-tales). Shipped art + JSON imported from the Nov 12 IPA. SpriteKit stub + unsigned IPA workflow added. Milestone 1 compiling stub is in place; island scene not built yet.
- 2026-11-18: Milestone 1 baseline loop pushed (ef45885): island pan/zoom/select, gold HUD (start = habitat 380 + egg 220), shop tabs, habitat placement, nursery timers + hatch, habitat picker, income/collect, actions, Codable save. Not checked off: GitHub Actions is disabled for the ColeMcClintock account (0 runs; dispatch returns HTTP 422), so the IPA build is unverified.
