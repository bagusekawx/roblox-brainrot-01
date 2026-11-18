# Brainrot Bay — a 3D Roblox brainrot game

[![roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/c/roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/bagusekawx/roblox-brainrot-01/rank.svg)](https://make.fun/c/roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/bagusekawx/roblox-brainrot-01/reward.svg)](https://make.fun/c/roblox-brainrot-01)

An entry for make.fun's [Make the best AI Roblox brainrot game](https://make.fun/c/roblox-brainrot-01)
bounty (roblox-brainrot-01): **Brainrot Bay**, a bright 3D island where absurd
meme characters walk a spawn path, players buy them onto their base plots, and
thieves, base locks, a tsunami and rebirths keep the loop tense.

## The game

- **The cast** — ten originals on a six-rung rarity ladder (Common to Brainrot
  God): Sir Croaksalot, Boba Blob, Noodle Naga, Turbo Tortoise, Captain
  Meowtain, Professor Pickles, DJ Quack, Queen Beestro, Sir Loin the Steak
  Knight and Baron Von Bubble. Golden (2x) and Rainbow (5x) mutations roll on
  spawn. Every character is built from primitives — no external assets.
- **The loop** — brainrots walk the path past the spawn gate; press E to buy
  one with cash; it moves to your base and earns $/s; buy the next tier.
- **The tension** — steal a brainrot off another player's base and carry it
  home, while its owner can lock their base for 30 seconds and a tsunami sweeps
  the island every few minutes, knocking every carried brainrot loose.
- **The progression** — rebirth for a permanent +25% income per level, and an
  upgrade shop for walk speed, carry capacity and extra base slots.
- **The world** — a sand island with a spawn path, six coloured base plots,
  palm trees, a lighthouse, crates and a welcome sign, under a 3D camera with a
  ScreenGui HUD (cash, income, brainrot count, rebirth multiplier, shop, lock,
  event banner, carry warning).

## Layout

- `main.ts` (Node 22, standard library only) hands the game in: it copies
  `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` (leaving out
  every name that starts with a dot) and writes `/output/dossier.json` with
  `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`:
  `rojo build default.project.json --output game.rbxl`.
- `src/shared/BrainrotData.luau` is the cast, rarity ladder, mutations and
  shop, shared by server and client. `src/server/` holds one module per system
  (PlayerState, BrainrotFactory, BrainrotSpawner, PlotManager, Shop, Steal,
  Rebirth, TsunamiEvent) plus the entrypoint `init.server.luau`.
  `src/client/Game.client.luau` builds the HUD and sends requests to the server.
- `screenshots/` holds the captures of the game running in Roblox Studio; one
  of them is the game's first thumbnail on Roblox. `PLAY.json` names the
  published place. `TOUR.json` is the optional tour for the finalist review:
  for each screenshot, the keys and the one module function that bring the game
  to that screen.

Run it as the grader does, writing `out/` in place of `/output`:

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
