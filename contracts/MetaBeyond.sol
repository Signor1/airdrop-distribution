// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//custom errors
error ZERO_ADDRESS_NOT_ALLOWED();
error CANNOT_REGISTER_AGAIN();
error ONLY_REGISTERED_USER_IS_ALLOWED();
error AIRDROP_DISTRIBUTION_HAS_ENDED();
error ALREADY_FOLLOWED_OUR_PAGE();
error ALREADY_LIKED_OUR_POST();
error ALREADY_SHARED_OUR_POST();
error USER_ENTRY_POINT_REACHED();

contract MetaBeyond {
    struct Users {
        uint256 id;
        address userAdress;
        bool hasFollowed;
        bool hasPosted;
        bool hasLiked;
        uint256 userPoints;
        bool hasRegistered;
        bool entryPointReach;
    }
}
