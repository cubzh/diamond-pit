use starknet::ContractAddress;
use diamond_pit::helpers::block::{BlockHelper};
use diamond_pit::helpers::math::fast_power_2;

pub const MAX_U128: u128 = 340282366920938463463374607431768211455;

const BLOCK_MASK: u128 = 4095; // (2 ^ 12) - 1
const BLOCK_BITS_SIZE: u8 = 12; // Size in bits of one block, 5 bits type, 7 bits hp

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct BlocksColumn {
    #[key]
    pub x: u8,
    #[key]
    pub y: u8,
    #[key]
    pub z_layer: u8, // 0 is first 10 blocks, 1 is 10 to 19
    pub data: u128
}

#[generate_trait]
pub impl BlocksColumnImpl of BlocksColumnTrait {
    fn hit_block(ref self: BlocksColumn, z: u8, mut strength: u16) -> (u16, bool) {
        let block_raw: u16 = self.get_block(z);
        let (_, hp) = BlockHelper::get_block_info(block_raw);
        if (hp <= 0) { // If air or already broken, return 0
            return (0, false);
        }
        if strength > hp.into() {
            strength = hp.into();
        }
        let new_hp = hp - strength.try_into().unwrap();
        let final_hit = new_hp <= 0;
        let new_block_info: u16 = block_raw - strength.into();
        self.set_block(new_block_info, z);
        (new_block_info, final_hit)
    }

    fn block_exists(self: BlocksColumn, z: u8) -> bool {
        let (block_type, hp) = BlockHelper::get_block_info(self.get_block(z));
        block_type > 0 && hp > 0
    }

    fn get_block(self: BlocksColumn, z: u8) -> u16 {
        let pow_z: u128 = fast_power_2((z * BLOCK_BITS_SIZE).into()).into();
        return ((self.data / pow_z) & BLOCK_MASK).try_into().unwrap();
    }
}

#[generate_trait]
impl BlocksColumnHelperImpl of BlocksColumnHelperTrait {
    fn set_block(ref self: BlocksColumn, block: u16, z: u8) {
        let shift: u128 = fast_power_2((z * BLOCK_BITS_SIZE).into()).into();
        let clean_mask: u128 = (MAX_U128 ^ (BLOCK_MASK * shift));
        self.data = (self.data & clean_mask) + (block.into() * shift);
    }
}

#[cfg(test)]
mod tests {
    use super::{BlocksColumn, BlocksColumnTrait};
    use diamond_pit::helpers::block::BlockHelper;

    #[test]
    fn test_hit_block_0() {
        let mut column = BlocksColumn { x: 0, y: 0, z_layer: 0, data: 430 };
        let (block_type, block_hp) = BlockHelper::get_block_info(column.get_block(0));
        assert!(block_type == 3, "init block type failed");
        assert!(block_hp == 46, "init block failed");
        let (block, _) = column.hit_block(0, 1);
        let (block_type, block_hp) = BlockHelper::get_block_info(block);
        assert!(block_type == 3, "hit changed type");
        assert!(block_hp == 45, "hit hp failed");
    }

    #[test]
    fn test_hit_block_1() {
        let mut column = BlocksColumn { x: 0, y: 0, z_layer: 0, data: 2974126 };
        let (block, final_hit) = column.hit_block(1, 1);
        assert!(block == 725, "hit block failed");
        assert!(!final_hit, "hit block failed");
        let (block, final_hit) = column.hit_block(1, 2);
        assert!(block == 723, "hit block failed 2");
        assert!(!final_hit, "hit block failed");
    }

    #[test]
    fn test_hit_block_last_hp() {
        let mut column = BlocksColumn { x: 0, y: 0, z_layer: 0, data: 2625966 };
        let (block_type, block_hp) = BlockHelper::get_block_info(column.get_block(1));
        assert!(block_type == 5, "init block type failed");
        assert!(block_hp == 1, "init block failed");

        let (block, final_hit) = column.hit_block(1, 1);
        assert!(final_hit, "final hit does not work");

        let (block_type, block_hp) = BlockHelper::get_block_info(block);
        assert!(block_type == 5, "hit changed type");
        assert!(block_hp == 0, "hit last hp failed");
    }
}
