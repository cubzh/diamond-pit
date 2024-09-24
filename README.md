# Diamond Pit

<div align="center">
  <a href="https://app.cu.bzh/?script=github.com/cubzh/diamond-pit">
    <img src="play_button.png" alt="Play Now" width="30%" height="30%">
  </a>
  <p></p>
  <img src="diamondpit.gif" alt="Play Now" width="100%" height="100%">
</div>

Diamond Pit is an example game built on [Cubzh](https://github.com/cubzh/cubzh) using the [Dojo SDK](https://github.com/dojoengine/dojo), demonstrating fully on-chain game integration.

Cubzh is an open-source and fully scriptable game engine, at the intersection of Minecraft and Roblox.

Dojo is a provable game engine and toolchain for creating fully autonomous, on-chain games and worlds on Starknet.

The Dojo API is available in Lua when launching the dojo edition of Cubzh, as specified here in the cubzh.json: https://github.com/cubzh/diamond-pit/blob/main/cubzh.json#L6

⭐️ Best way to help us: add a star to [Cubzh](https://github.com/cubzh/cubzh) repository ⭐️

## Game Description

In Diamond Pit, players navigate a vast pit, mining blocks to sell and upgrade their equipment. Key features include:

- A central, massive mining pit
- Upgradable pickaxes and backpacks
- Rebirth system for progression
- Collectible pets obtained from eggs
- Goal: Collect all 6 unique pets

## Run your own version

1. Fork this repository
2. Your version of the game is now accessible at https://app.cu.bzh/?script=github.com/<username>/<repo>:<commithash>
3. Update the "Play" button URL in the README (replace with URL of your fork)
4. Visit your Github repository page and click "Play"

## Make changes on the game client

1. Make desired changes in `world.lua`
2. Push your changes and access your version at:
   ```
   https://app.cu.bzh/?script=github.com/<username>/<repo>:<commithash>
   ```
   Note: Include the commit hash to bypass the one-day cache.

## Deploying Contracts

1. Install Dojo version v1.0.0-alpha.12
2. Navigate to the contracts directory:
  ```
  cd contracts
  ```
3. Build the project:
  ```
  sozo build
  ```
4. Update the RPC URL in `dojo_dev.toml`
5. Apply migrations:
  ```
  sozo migrate apply
  ```
6. Generate the pit:
  ```
  ./regenerate.sh
  ```
7. Set up a cron job to run this script every 5 minutes

## Future Development

- Cubzh x Dojo tutorial coming by the end of October with a VSCode extension to iterate faster
- Starknet mainnet and testnet integrations with Dojo Controller
- Implement off-chain messages for smoother player movements
- Feature: select a pet that follows the player and provides bonuses
