use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct PlayerStats {
    #[key]
    player: ContractAddress,
    pub name: felt252,
    pub backpack_level: u8,
    pub pickaxe_level: u8,
    pub rebirth: u16,
    //hatIndex: u8,
}

#[generate_trait]
pub impl PlayerStatsImpl of PlayerStatsTrait {
    fn get_pickaxe_strength(self: PlayerStats) -> u16 {
         match self.pickaxe_level {
            0 => 1,
            1 => 2,
            2 => 3,
            3 => 4,
            4 => 8,
            5 => 12,
            6 => 20,
            _ => 20,
        }
    }

    fn get_pickaxe_next_upgrade_price(self: PlayerStats) -> u16 {
         match self.pickaxe_level {
            0 => 10,
            1 => 25,
            2 => 100,
            3 => 300,
            4 => 750,
            5 => 2500,
            _ => 2500,
        }
    }

    fn get_backpack_max_slots(self: PlayerStats) -> u16 {
         match self.backpack_level {
            0 => 5,
            1 => 15,
            2 => 25,
            3 => 40,
            4 => 75,
            5 => 100,
            6 => 160,
            _ => 160,
        }
    }

    fn get_backpack_next_upgrade_price(self: PlayerStats) -> u16 {
         match self.backpack_level {
            0 => 5,
            1 => 15,
            2 => 25,
            3 => 75,
            4 => 300,
            5 => 1000,
            6 => 3000,
            _ => 3000
        }
    }

    fn get_rebirth_multiplier(self: PlayerStats) -> u16 {
        self.rebirth + 1
    }
}
