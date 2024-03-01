// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

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
    IERC20 public metaToken;

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

    constructor(address _metaToken) {
        metaToken = IERC20(_metaToken);
    }

    //events
    event UserRegistered(uint256 id, address userAdress);
    event UserFollowed(uint256 id, address userAdress);
    event UserLiked(uint256 id, address userAdress);
    event UserShared(uint256 id, address userAdress);
    event UserEntryPointReached(uint256 id, address userAdress);
    event DistributionSuccessful(
        address userAdress,
        uint256 id,
        uint256 amount
    );

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

        emit UserRegistered(id, msg.sender);
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

        emit UserFollowed(registeredUsers[msg.sender].id, msg.sender);
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

        emit UserLiked(registeredUsers[msg.sender].id, msg.sender);
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

        emit UserShared(registeredUsers[msg.sender].id, msg.sender);
    }

    //users entry point update
    function updateEntryPoints() private {
        if (registeredUsers[msg.sender].entryPointReach == false) {
            if (registeredUsers[msg.sender].userPoints == 50) {
                registeredUsers[msg.sender].entryPointReach = true;

                winners.push(registeredUsers[msg.sender].id);

                //
                if (winners.length == 20) {}
            }
        } else {
            revert USER_ENTRY_POINT_REACHED();
        }

        emit UserEntryPointReached(registeredUsers[msg.sender].id, msg.sender);
    }

    //airdrop distribution method
    function distributePrize() private {
        if (winners.length == 20) {
            // chainlink vrf
            //IERC20 for transfer

            hasAirdropEnded = true;
        }
    }

    //check whether user is registered
    function doesUserExist() private view {
        if (registeredUsers[msg.sender].hasRegistered == false) {
            revert ONLY_REGISTERED_USER_IS_ALLOWED();
        }
    }
}
