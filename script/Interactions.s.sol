// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {VRFCoordinatorV2_5} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFCoordinatorV2_5.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script, CodeConstants {
    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        address account = helperConfig.getConfig().account;
        (uint256 subId,) = createSubscription(vrfCoordinator, account);
        return (subId, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator, address account ) public returns (uint256, address) {
        console.log("creating subscription on chain Id:", block.chainid);
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Your Subscription Id is:", subId);
        return (subId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; // == 3 LINK

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig().vrfCoordinatorV2_5;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        address account = helperConfig.getConfig().account;

        fundSubscription(vrfCoordinator, subscriptionId, linkToken, account);
    }

    function fundSubscription(address VRFCoordinator, uint256 SubscriptionId, address linkToken, address account) public {
        console.log("Funding Subscription:", SubscriptionId);
        console.log("Using VRFCoordinator:", VRFCoordinator);
        console.log("On ChainId:", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(VRFCoordinator).fundSubscription(SubscriptionId, FUND_AMOUNT * 100);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(VRFCoordinator, FUND_AMOUNT, abi.encode(SubscriptionId));
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script, CodeConstants {

    /// @notice Read config and call addConsumer(...)
    function addConsumerUsingConfig(address raffleContract) public {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        // Cast subscriptionId to uint64
        uint64 subId = uint64(config.subscriptionId);
        address vrfCoordinator = config.vrfCoordinatorV2_5;
        address account = helperConfig.getConfig().account;

        addConsumer(raffleContract, vrfCoordinator, subId, account);
    }

    /// @notice Adds `raffleContract` to the subscription
    function addConsumer(
        address raffleContract,
        address vrfCoordinator,
        uint256 subId,
        address account
    ) public {
        console.log("Adding consumer to subscription:", subId);
        console.log("Consumer address:", raffleContract);
        console.log("VRF Coordinator:", vrfCoordinator);
        console.log("On chainId:", block.chainid);

        //vm.startBroadcast(account);

        if (block.chainid == LOCAL_CHAIN_ID) {
            // local mock
            VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, raffleContract);
        } else {
            // real coordinator
            VRFCoordinatorV2_5(vrfCoordinator).addConsumer(subId, raffleContract);
        }

        //vm.stopBroadcast();

        console.log("Consumer added (tx submitted)");
    }

    /// @notice Forge entry point
    function run() external {
        // Get most recent Raffle deployment
        address mostRecentDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        require(mostRecentDeployed != address(0), "mostRecentDeployed address not set");

        addConsumerUsingConfig(mostRecentDeployed);
    }
}