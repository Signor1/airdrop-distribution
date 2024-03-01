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

contract MetaBeyond is VRFConsumerBaseV2 {
    //VRF co-ordinator
    VRFCoordinatorV2Interface COORDINATOR;

    IERC20 public metaToken;

    struct Users {
        uint256 id;
        address userAddress;
        bool hasFollowed;
        bool hasPosted;
        bool hasLiked;
        uint256 userPoints;
        bool hasRegistered;
        bool entryPointReach;
    }

    uint256 userId;

    address[] winners;

    bool hasAirdropEnded;

    uint8 constant pointforFollow = 20;
    uint8 constant pointforLike = 10;
    uint8 constant pointForPostSharing = 30;

    mapping(address => Users) registeredUsers;

    //subscription Id from the VRF
    uint64 subscriptionId;

    // Array to store past request IDs
    uint256[] public requestIds;
    // ID of the last request made for randomness
    uint256 public lastRequestId;

    // Key hash used for Chainlink VRF
    bytes32 keyHash =
        0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;

    // Number of confirmations required for a randomness request
    uint16 requestConfirmations;

    uint32 numWords = 5; // Number of random words to be generated
    uint32 callbackGasLimit = 400000;

    struct RequestStatus {
        bool fulfilled; // Whether the request has been successfully fulfilled
        bool exists; // Whether a requestId exists
        uint256[] randomWords; // Array to store the generated random words
    }

    mapping(uint => RequestStatus) requests;

    constructor(
        uint64 _subscriptionId,
        address _metaToken
    ) VRFConsumerBaseV2(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625) {
        metaToken = IERC20(_metaToken);

        COORDINATOR = VRFCoordinatorV2Interface(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
        );
        subscriptionId = _subscriptionId;
    }

    //events
    event UserRegistered(uint256 id, address userAdress);
    event UserFollowed(uint256 id, address userAdress);
    event UserLiked(uint256 id, address userAdress);
    event UserShared(uint256 id, address userAdress);
    event UserEntryPointReached(uint256 id, address userAdress);
    event DistributionSuccessful(address userAdress, uint256 amount);

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

                //inserting the address of users with 50 points or more in the 'winners' array
                winners.push(registeredUsers[msg.sender].userAddress);

                //check whether the defined number of winners have been reached, if yes? Get random winners
                checkAndGetRandomWinners();
            }
        } else {
            revert USER_ENTRY_POINT_REACHED();
        }

        emit UserEntryPointReached(registeredUsers[msg.sender].id, msg.sender);
    }

    //airdrop distribution method
    function checkAndGetRandomWinners() private {
        if (winners.length == 20) {
            getRequestId();
        }
    }

    //getting the request id
    function getRequestId() private returns (uint256 requestId) {
        // chainlink vrf
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        RequestStatus storage requestStatus = requests[requestId];
        requestStatus.exists = true;

        requestIds.push(requestId);
        lastRequestId = requestId;

        return requestId;
    }

    //to be called when the request id is retrieved
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(requests[_requestId].exists, "Request not found");

        requests[_requestId].fulfilled = true;
        requests[_requestId].randomWords = _randomWords;

        shareAirdrop(_requestId);
    }

    //after the random words are generated, the airdrop is distributed to the randomly chosen winners. Picked (randomly) Winners will recieve the airdrop, the rest of the airdrop (the token) is sent to this contract
    function shareAirdrop(uint256 _requestId) private {
        for (uint256 i = 0; i < numWords; i++) {
            uint256 index = (requests[_requestId].randomWords[i] + i) %
                winners.length;

            uint amount = registeredUsers[winners[index]].userPoints * 10;

            metaToken.transfer(winners[index], amount);

            emit DistributionSuccessful(winners[index], amount);
        }

        //after distribution the airdrop ends
        hasAirdropEnded = true;
    }

    //check whether user is registered
    function doesUserExist() private view {
        if (registeredUsers[msg.sender].hasRegistered == false) {
            revert ONLY_REGISTERED_USER_IS_ALLOWED();
        }
    }
}
