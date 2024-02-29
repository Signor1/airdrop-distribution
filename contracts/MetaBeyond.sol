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

    uint256 userId;

    uint256[] winners;

    bool hasAirdropEnded;

    uint8 constant pointforFollow = 20;
    uint8 constant pointforLike = 10;
    uint8 constant pointForPostSharing = 30;

    mapping(address => Users) registeredUsers;

    //registrations
    function register() external {
        if (hasAirdropEnded) {
            revert AIRDROP_DISTRIBUTION_HAS_ENDED();
        }
        if (msg.sender == address(0)) {
            revert ZERO_ADDRESS_NOT_ALLOWED();
        }

        if (registeredUsers[msg.sender].hasRegistered == true) {
            revert CANNOT_REGISTER_AGAIN();
        }

        uint256 id = userId + 1;

        registeredUsers[msg.sender] = Users(
            id,
            msg.sender,
            false,
            false,
            false,
            0,
            true,
            false
        );

        userId = id + userId;
    }

    //follow our page
    function followUs() external {
        if (msg.sender == address(0)) {
            revert ZERO_ADDRESS_NOT_ALLOWED();
        }

        doesUserExist();

        if (registeredUsers[msg.sender].hasFollowed) {
            revert ALREADY_FOLLOWED_OUR_PAGE();
        }

        registeredUsers[msg.sender].hasFollowed = true;

        registeredUsers[msg.sender].userPoints =
            registeredUsers[msg.sender].userPoints +
            pointforFollow;

        updateEntryPoints();
    }

    //like our pinned post
    function likeOurPinnedPost() external {
        if (msg.sender == address(0)) {
            revert ZERO_ADDRESS_NOT_ALLOWED();
        }

        doesUserExist();

        if (registeredUsers[msg.sender].hasLiked) {
            revert ALREADY_LIKED_OUR_POST();
        }

        registeredUsers[msg.sender].hasLiked = true;

        registeredUsers[msg.sender].userPoints =
            registeredUsers[msg.sender].userPoints +
            pointforLike;

        updateEntryPoints();
    }

    //share our pinned post
    function sharePinnedPost() external {
        if (msg.sender == address(0)) {
            revert ZERO_ADDRESS_NOT_ALLOWED();
        }

        doesUserExist();

        if (registeredUsers[msg.sender].hasPosted) {
            revert ALREADY_SHARED_OUR_POST();
        }

        registeredUsers[msg.sender].hasPosted = true;

        registeredUsers[msg.sender].userPoints =
            registeredUsers[msg.sender].userPoints +
            pointForPostSharing;

        updateEntryPoints();
    }
}
