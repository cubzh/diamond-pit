use starknet::ContractAddress;
use dojo_examples::helpers::block::{BlockType, BlockHelperTrait};
use dojo_examples::helpers::math::{fast_power_2};

const SLOT_MASK: u64 = 255;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct PlayerInventory {
    #[key]
    player: ContractAddress,
    pub data: u64,
    pub coins: u64,
}

#[generate_trait]
pub impl PlayerInventoryImpl of PlayerInventoryTrait {
    fn get_amount(self: PlayerInventory, block_type: BlockType) -> u16 {
        let index: u64 = BlockHelperTrait::block_type_to_u8(block_type).into();
        ((self.data / fast_power_2((index * 8).into()).try_into().unwrap()) & SLOT_MASK).try_into().unwrap()
    }
    
    fn add(ref self: PlayerInventory, block_type: BlockType, qty: u16) {
        let index: u64 = BlockHelperTrait::block_type_to_u8(block_type).into();
        self.data = self.data + (qty.into() * fast_power_2((index * 8).into())).try_into().unwrap();
    }

    fn slots_left(self: PlayerInventory, max_slots: u16) -> u16 {
        max_slots - (self.get_amount(BlockType::Stone).into() +
            self.get_amount(BlockType::Coal).into() +
            self.get_amount(BlockType::Copper).into() +
            self.get_amount(BlockType::Iron).into() +
            self.get_amount(BlockType::DeepStone).into() +
            self.get_amount(BlockType::Gold).into() +
            self.get_amount(BlockType::Diamond).into())
    }

    fn sell_all(ref self: PlayerInventory) -> u64 {
        let mut coins_to_add: u64 =
            self.get_amount(BlockType::Stone).into() * BlockHelperTrait::block_price_per_type(BlockType::Stone).into() +
            self.get_amount(BlockType::Coal).into() * BlockHelperTrait::block_price_per_type(BlockType::Coal).into() +
            self.get_amount(BlockType::Copper).into() * BlockHelperTrait::block_price_per_type(BlockType::Copper).into() +
            self.get_amount(BlockType::Iron).into() * BlockHelperTrait::block_price_per_type(BlockType::Iron).into() +
            self.get_amount(BlockType::DeepStone).into() * BlockHelperTrait::block_price_per_type(BlockType::DeepStone).into() +
            self.get_amount(BlockType::Gold).into() * BlockHelperTrait::block_price_per_type(BlockType::Gold).into() +
            self.get_amount(BlockType::Diamond).into() * BlockHelperTrait::block_price_per_type(BlockType::Diamond).into();

        // Clear inventory
        self.data = 0;

        self.coins = self.coins + coins_to_add;
        coins_to_add
    }
}

#[cfg(test)]
mod tests {
    use super::{PlayerInventory, PlayerInventoryTrait};
    use dojo_examples::helpers::block::{BlockType};
 
    #[test]
    fn test_get_stone() {
        let mut inventory = PlayerInventory { player: starknet::contract_address_const::<'PLAYER'>(), data: 8192, coins: 0 };
        assert!(inventory.get_amount(BlockType::Stone) == 32, "failed get stone");
        assert!(inventory.get_amount(BlockType::Gold) == 0, "failed get gold");
    }

    #[test]
    fn test_get_diamond() {
        let mut inventory = PlayerInventory { player: starknet::contract_address_const::<'PLAYER'>(), data: 9439544818968559616, coins: 0 };
        assert!(inventory.get_amount(BlockType::Diamond) == 131, "failed get slot");
    }

    #[test]
    fn test_add_gold_and_iron() {
        let mut inventory = PlayerInventory { player: starknet::contract_address_const::<'PLAYER'>(), data: 9439544818968559616, coins: 0 };
        assert!(inventory.get_amount(BlockType::Gold) == 0, "failed init gold");
        inventory.add(BlockType::Gold, 141);
        assert!(inventory.get_amount(BlockType::Gold) == 141, "failed add gold");
        inventory.add(BlockType::Gold, 4);
        assert!(inventory.get_amount(BlockType::Gold) == 145, "failed add gold 2");
        inventory.add(BlockType::Iron, 29);
        assert!(inventory.get_amount(BlockType::Gold) == 145, "failed add gold 3");
        assert!(inventory.get_amount(BlockType::Iron) == 29, "failed add iron");
    }

    #[test]
    fn test_get_and_sell_all() {
        let mut inventory = PlayerInventory { player: starknet::contract_address_const::<'PLAYER'>(), data: 0, coins: 0 };
        inventory.add(BlockType::Stone, 10);
        inventory.sell_all();
        assert!(inventory.coins == 10, "wrong sell stone");
        inventory.add(BlockType::Stone, 10);
        inventory.add(BlockType::Gold, 4);
        inventory.add(BlockType::Diamond, 123);
        inventory.sell_all();
        assert!(inventory.coins == 12550 + 10, "wrong sell all");
    }
}
