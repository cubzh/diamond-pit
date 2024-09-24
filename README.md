# Diamond Pit

<div align="center">
  <a href="https://app.cu.bzh/?script=github.com/caillef/diamond-pit">
    <img src="play_button.png" alt="Play Now" width="30%" height="30%">
  </a>
  <p></p>
  <p></p>
</div>

Diamond Pit is an example game built on [Cubzh](https://github.com/cubzh/cubzh) using the [Dojo SDK](https://github.com/dojoengine/dojo), demonstrating fully on-chain game integration.

⭐️ Best way to help us: add a star to [Cubzh](https://github.com/cubzh/cubzh) repository ⭐️

## Game Description

In Diamond Pit, players navigate a vast pit, mining blocks to sell and upgrade their equipment. Key features include:

- A central, massive mining pit
- Upgradable pickaxes and backpacks
- Rebirth system for progression
- Collectible pets obtained from eggs
- Goal: Collect all 6 unique pets

## Customizing the Game

To create your own version:

1. Fork this repository
2. Update the image URL in the README
3. Make desired changes in `world.lua`
4. Push your changes and access your version at:
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
- Implement off-chain messages for smoother player movements
- Add a feature to select a pet that follows the player and provides boosts
