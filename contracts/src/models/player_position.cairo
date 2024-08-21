use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct PlayerPosition {
    #[key]
    player: ContractAddress,
    pub x: u32,
    pub y: u32,
    pub z: u32,
    pub time: u64,
}
