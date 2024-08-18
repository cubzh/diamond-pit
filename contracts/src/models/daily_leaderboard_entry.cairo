use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct DailyLeaderboardEntry {
    #[key]
    player: ContractAddress,
    #[key]
    day: u32,
    pub nb_coins_collected: u64,
    pub nb_blocks_broken: u16,
    pub nb_hits: u16,
}
