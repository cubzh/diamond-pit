use core::poseidon::poseidon_hash_span;

fn _uniform_random(seed: felt252, max: u128) -> u128 {
    let hash: u256 = poseidon_hash_span(array![seed].span()).into();
    hash.low % max
}

// define the interface
#[dojo::interface]
pub trait IActions {
    fn hit_block(ref world: IWorldDispatcher, x: u8, y: u8, z: u8);
    fn inspect_block(ref world: IWorldDispatcher, x: u8, y: u8, z: u8);
    fn generate_world(ref world: IWorldDispatcher, z_layer: u8);
    fn sell_all(ref world: IWorldDispatcher);
    fn upgrade_backpack(ref world: IWorldDispatcher);
    fn upgrade_pickaxe(ref world: IWorldDispatcher);
}

// dojo decorator
#[dojo::contract]
pub mod actions {
    use super::{IActions, _uniform_random};
    use starknet::{ContractAddress, get_caller_address};
    use diamond_pit::models::{
        blocks_column::{BlocksColumn, BlocksColumnTrait, MAX_U128},
        player_inventory::{PlayerInventory, PlayerInventoryTrait},
        daily_leaderboard_entry::{DailyLeaderboardEntry},
        player_stats::{PlayerStats, PlayerStatsTrait},
    };
    use diamond_pit::helpers::{block::{BlockHelper, BlockType}, math::{fast_power_2}};

    pub mod Errors {
        pub const NOT_ENOUGH_COINS: felt252 = 'not enough coins';
        pub const BLOCK_NOT_FOUND: felt252 = 'block not found';
    }

    #[abi(embed_v0)]
    impl ActionsImpl of IActions<ContractState> {
        fn hit_block(ref world: IWorldDispatcher, x: u8, y: u8, z: u8) {
            let player = get_caller_address();
            let day: u64 = starknet::get_block_info().unbox().block_timestamp / 86400;
            let mut player_leaderboard_entry = get!(world, (player, day), (DailyLeaderboardEntry));
            player_leaderboard_entry.nb_hits += 1;

            let z_layer = z / 10;
            let mut column = get!(world, (x, y, z_layer), (BlocksColumn));
            assert(column.block_exists(z % 10), Errors::BLOCK_NOT_FOUND);

            // Anti-cheat, can't break blocks that are not accessible
            // if x > 0 && x < 9 && y > 0 && y < 9 {
            //    let mut column1 = get!(world, (x + 1, y, z_layer), (BlocksColumn));
            //    let mut column2 = get!(world, (x - 1, y, z_layer), (BlocksColumn));
            //    let mut column3 = get!(world, (x, y + 1, z_layer), (BlocksColumn));
            //    let mut column4 = get!(world, (x, y - 1, z_layer), (BlocksColumn));

            //    // Avoid being able to
            //    if z % 10 > 0 && z % 10 < 9 && column.block_exists(z % 10 + 1) &&
            //    column.block_exists(z % 10 - 1) &&
            //        column1.block_exists(z % 10) && column2.block_exists(z % 10) &&
            //        column3.block_exists(z % 10) && column4.block_exists(z % 10) {
            //        return;
            //    }
            // }

            let playerStats = get!(world, (player), (PlayerStats));
            let strength = playerStats.get_pickaxe_strength();
            let (new_block, final_hit) = column.hit_block(z % 10, strength);
            if final_hit {
                player_leaderboard_entry.nb_blocks_broken += 1;
                let mut inventory = get!(world, (player), (PlayerInventory));
                let (block_type, _) = BlockHelper::get_block_info(new_block);
                let nb_blocks = playerStats.get_rebirth_multiplier();
                let slots_left = inventory.slots_left(playerStats.get_backpack_max_slots());
                if slots_left >= nb_blocks {
                    inventory.add(BlockHelper::block_u8_to_type(block_type), nb_blocks);
                    set!(world, (inventory));
                } else { // Send event backpack max capacity reach
                }
            }
            set!(world, (column, player_leaderboard_entry));
        }

        fn sell_all(ref world: IWorldDispatcher) {
            let player = get_caller_address();
            let day: u64 = starknet::get_block_info().unbox().block_timestamp / 86400;
            let mut player_leaderboard_entry = get!(world, (player, day), (DailyLeaderboardEntry));

            let mut inventory = get!(world, (player), (PlayerInventory));
            let amountSold = inventory.sell_all();
            player_leaderboard_entry.nb_coins_collected += amountSold;
            set!(world, (inventory, player_leaderboard_entry));
        }

        fn upgrade_pickaxe(ref world: IWorldDispatcher) {
            let player = get_caller_address();
            let (mut stats, mut inventory) = get!(world, (player), (PlayerStats, PlayerInventory));
            let next_upgrade_price: u64 = stats.get_pickaxe_next_upgrade_price().into();
            assert(inventory.coins >= next_upgrade_price, Errors::NOT_ENOUGH_COINS);
            inventory.coins -= next_upgrade_price;
            stats.pickaxe_level += 1;
            set!(world, (inventory, stats));
        }

        fn upgrade_backpack(ref world: IWorldDispatcher) {
            let player = get_caller_address();
            let (mut stats, mut inventory) = get!(world, (player), (PlayerStats, PlayerInventory));
            let next_upgrade_price: u64 = stats.get_backpack_next_upgrade_price().into();
            assert(inventory.coins >= next_upgrade_price, Errors::NOT_ENOUGH_COINS);
            inventory.coins -= next_upgrade_price;
            stats.backpack_level += 1;
            set!(world, (inventory, stats));
        }

        // Debug
        fn inspect_block(ref world: IWorldDispatcher, x: u8, y: u8, z: u8) {
            let z_layer = z / 10;
            let mut column = get!(world, (x, y, z_layer), (BlocksColumn));
            let block = column.get_block(z % 10);
            let (block_type, block_hp) = BlockHelper::get_block_info(block);
            println!("{} (type {}, hp {})", block, block_type, block_hp);
        }

        // Tools
        fn generate_world(ref world: IWorldDispatcher, z_layer: u8) {
            let timestamp: u64 = starknet::get_block_info().unbox().block_timestamp;

            let mut y: u8 = 0;
            loop {
                if y >= 10 {
                    break;
                }
                let seed_rnd = _uniform_random(
                    timestamp.into() + y.into() * 5099 + z_layer.into(), 10000
                );
                let mut x: u8 = 0;
                loop {
                    if x >= 10 {
                        break;
                    }
                    let mut data: u128 = 42846909754239046452576930880831620; // 10 Stone
                    if z_layer > 1 {
                        data = 169440052209945320062463317574197770
                    }; // 10 Deepstone 
                    let rnd_value: u128 = (seed_rnd.into() + x.into() * 100049) % 10;
                    let shift = fast_power_2(rnd_value * 12);
                    let block: u128 = match z_layer {
                        0 => BlockHelper::new(BlockType::Coal),
                        1 => BlockHelper::new(BlockType::Copper),
                        2 => BlockHelper::new(BlockType::Iron),
                        3 => BlockHelper::new(BlockType::Gold),
                        4 => BlockHelper::new(BlockType::Diamond),
                        _ => BlockHelper::new(BlockType::Coal),
                    }.into();
                    data = (data & (MAX_U128 ^ (4095 * shift))) + block * shift;
                    set!(world, (BlocksColumn { x, y, z_layer, data }));
                    x += 1;
                };
                y += 1;
            };
        }
    }
}

