module contract::cat {
    use sui::table::{Self, Table};
    use sui::package;

    use std::string::String;


    // errors

    // owner has not claimed
    const EWrongOwner: u64 = 1;


    public struct CAT has drop {}

    public struct MintCap has key {
        id: UID,
    }
    
    public struct Cat has key, store {
        id: UID,
        name: String,
        eyes: String,
        color: String,
        date_of_birth: u64,
        photo: String,
        chip: Option<u64> // 15 digit number
    }
    

    public struct Registry has key {
        id: UID,
        cats_with_owners: Table<address, ID>,
        cats_looking_for_owners: Table<ID, Cat>
    }

    fun init(otw: CAT, ctx: &mut TxContext) {
        let cap = MintCap {
            id: object::new(ctx)
        };

        let registry = Registry {
            id: object::new(ctx),
            cats_with_owners: table::new<address, ID>(ctx),
            cats_looking_for_owners: table::new<ID, Cat>(ctx)
        };

        let publisher = package::claim<CAT>(otw, ctx);

        transfer::share_object(registry);
        transfer::transfer(cap, ctx.sender()); // need to use transfer
        transfer::public_transfer(publisher, ctx.sender());

    }


    public fun new(
        _: &MintCap,
        name: String,
        eyes: String,
        color: String,
        date_of_birth: u64,
        photo: String,
        chip_serial_num: u64,
        ctx: &mut TxContext
    ): Cat {
        let mut chip = option::none<u64>();
        if(chip_serial_num > 0) {
            chip.fill(chip_serial_num);
        };
        let uid = object::new(ctx);
        
        Cat {
            id: uid,
            name,
            eyes,
            color,
            date_of_birth,
            photo,
            chip
        }
    }

    public fun say_goodbye(self: Cat) {
        let Cat {id, name:_, eyes: _, color: _, date_of_birth: _, photo: _, chip: _} = self;
        object::delete(id);
    }

    public fun claim_ownership(cat: &mut Cat, registry: &mut Registry, ctx: &mut TxContext) {
        registry.cats_with_owners.add<address, ID>(ctx.sender(), object::id(cat));
    }


    public fun give_for_adoption(cat: Cat, registry: &mut Registry, ctx: &mut TxContext) {
        let owner = ctx.sender();
        let cat_id = registry.cats_with_owners.remove<address, ID>(owner);
        assert!(cat_id == object::id(&cat), EWrongOwner);
        registry.cats_looking_for_owners.add<ID, Cat>(cat_id, cat);
    }

    public fun adopt(cat_id: ID, registry: &mut Registry, ctx: &mut TxContext): Cat {
        let cat = registry.cats_looking_for_owners.remove<ID, Cat>(cat_id);
        registry.cats_with_owners.add<address, ID> (ctx.sender(), cat_id);
        cat
    }

    public fun sniff_sniff(cat_id: ID, registry: &mut Registry, _: &MintCap) {
        let cat = registry.cats_looking_for_owners.remove<ID, Cat>(cat_id);
        say_goodbye(cat);
    }
}
