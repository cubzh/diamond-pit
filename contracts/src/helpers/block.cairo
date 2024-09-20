use diamond_pit::helpers::math::fast_power_2;

const TWO_POW_7: u128 = 128;
const BLOCK_HP_MASK: u16 = 127;

#[derive(Copy, Drop)]
pub enum BlockType {
    Air,
    Stone,
    Coal,
    Copper,
    DeepStone,
    Iron,
    Gold,
    Diamond,
    Starknet,
}

#[generate_trait]
pub impl BlockHelper of BlockHelperTrait {
    fn new(block_type: BlockType) -> u16 {
        let block_value: u16 = (Self::block_type_to_u8(block_type).into() * TWO_POW_7)
            .try_into()
            .unwrap();
        return (block_value + Self::block_max_hp_per_type(block_type).into()).try_into().unwrap();
    }

    fn get_block_info(block: u16) -> (u8, u8) {
        let block_type: u8 = (block / TWO_POW_7.try_into().unwrap()).try_into().unwrap();
        let block_hp: u8 = (block & BLOCK_HP_MASK).try_into().unwrap();
        (block_type, block_hp)
    }

    fn block_max_hp_per_type(block_type: BlockType) -> u8 {
        match block_type {
            BlockType::Air => 0,
            BlockType::Stone => 4,
            BlockType::Coal => 10,
            BlockType::Copper => 25,
            BlockType::DeepStone => 10,
            BlockType::Iron => 40,
            BlockType::Gold => 80,
            BlockType::Diamond => 125,
            BlockType::Starknet => 127,
        }
    }

    fn block_price_per_type(block_type: BlockType) -> u16 {
        match block_type {
            BlockType::Air => 0,
            BlockType::Stone => 1,
            BlockType::Coal => 4,
            BlockType::Copper => 7,
            BlockType::DeepStone => 2,
            BlockType::Iron => 20,
            BlockType::Gold => 60,
            BlockType::Diamond => 100,
            BlockType::Starknet => 1000,
        }
    }

    fn block_type_to_u8(block_type: BlockType) -> u8 {
        match block_type {
            BlockType::Air => 0,
            BlockType::Stone => 1,
            BlockType::Coal => 2,
            BlockType::Copper => 3,
            BlockType::DeepStone => 4,
            BlockType::Iron => 5,
            BlockType::Gold => 6,
            BlockType::Diamond => 7,
            BlockType::Starknet => 8,
        }
    }

    fn block_u8_to_type(block_type: u8) -> BlockType {
        match block_type {
            0 => BlockType::Air,
            1 => BlockType::Stone,
            2 => BlockType::Coal,
            3 => BlockType::Copper,
            4 => BlockType::DeepStone,
            5 => BlockType::Iron,
            6 => BlockType::Gold,
            7 => BlockType::Diamond,
            8 => BlockType::Starknet,
            _ => BlockType::Air,
        }
    }
}


#[cfg(test)]
mod tests {
    use super::{BlockHelper, BlockType};

    #[test]
    fn test_create_block() {
        assert(BlockHelper::new(BlockType::Air) == 0, 'wrong block 1');
        assert(BlockHelper::new(BlockType::Stone) == 132, 'wrong block 2');
        assert(BlockHelper::new(BlockType::Gold) == 848, 'wrong block 3');
        assert(BlockHelper::new(BlockType::Diamond) == 1021, 'wrong block 4');
    }
}
