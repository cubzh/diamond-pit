use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct PetInventory {
    #[key]
    owner: ContractAddress,
    pub bunnies: u32,
    pub birds: u32,
    pub rams: u32,
    pub chickens: u32,
    pub rhinos: u32,
    pub reptiles: u32
}

#[generate_trait]
pub impl PetInventoryImpl of PetInventoryTrait {
    fn add_pet(ref self: PetInventory, pet_id: u8) {
        match pet_id {
            0 => (),
            1 => self.bunnies += 1,
            2 => self.birds += 1,
            3 => self.rams += 1,
            4 => self.chickens += 1,
            5 => self.rhinos += 1,
            6 => self.reptiles += 1,
            _ => (),
        }
    }
}
