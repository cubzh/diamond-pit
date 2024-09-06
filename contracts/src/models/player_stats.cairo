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
            2 => 50,
            3 => 100,
            4 => 250,
            5 => 800,
            _ => 800,
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
         match self.pickaxe_level {
            0 => 5,
            1 => 20,
            2 => 80,
            3 => 135,
            4 => 450,
            5 => 1000,
            _ => 1000,
        }
    }

    fn get_rebirth_multiplier(self: PlayerStats) -> u16 {
        self.rebirth + 1
    }
}
