use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct PlayerStats {
    #[key]
    player: ContractAddress,
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
            0 => 0,
            1 => 10,
            2 => 25,
            3 => 50,
            4 => 100,
            5 => 250,
            6 => 800,
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
            0 => 0,
            1 => 5,
            2 => 20,
            3 => 80,
            4 => 135,
            5 => 450,
            6 => 1000,
            _ => 1000,
        }
    }

    fn get_rebirth_multiplier(self: PlayerStats) -> u16 {
        self.rebirth + 1
    }
}