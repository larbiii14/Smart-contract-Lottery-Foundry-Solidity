// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Raffle } from "src/Raffle.sol"; // Adjust if needed based on your file structure
import { Script, console } from "foundry-devops/forge-std/src/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";
import {VRFCoordinatorV2_5} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFCoordinatorV2_5.sol";

contract DeployRaffle is Script {
    uint256 entranceFee = 0.01 ether; // Example entrance fee (adjust as needed)
    uint256 interval = 30; // 30 seconds
    // address vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
    bytes32 gasLane = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    uint256 subscriptionId = 36723438303479479318165635801543732170074967735622738639588447659406156023220;
    uint32 callbackGasLimit = 500000; // Adjust gas limit if needed

function deployContract() public returns (Raffle, HelperConfig) {
    // Deploy HelperConfig contract
    HelperConfig helperConfig = new HelperConfig();
    HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

    // Deploy Raffle contract
    Raffle raffle = new Raffle(
        entranceFee,
        interval,
        config.vrfCoordinatorV2_5,
        config.gasLane,
        config.subscriptionId,
        config.callbackGasLimit
    );

    // If no subscription yet, create one
    if (config.subscriptionId == 0) {
        // Create Subscription
        CreateSubscription createSubscription = new CreateSubscription();
        (config.subscriptionId, config.vrfCoordinatorV2_5 ) = 
            createSubscription.createSubscription(config.vrfCoordinatorV2_5, config.account);

        // Fund it

        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(config.vrfCoordinatorV2_5, config.subscriptionId, config.link, config.account);
    }

    return (raffle, helperConfig);
}

    function run() public {

        // Deploy the Raffle contract via deployContract() to get proper config
        (Raffle raffle, HelperConfig helperConfig) = deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast(config.account);

        // Log the contract address
        console.log("Raffle contract deployed to:", address(raffle));

        // Add raffle as consumer to VRF subscription
        // AddConsumer addConsumer = new AddConsumer();
        // addConsumer.addConsumer(
        //     address(raffle),
        //     config.vrfCoordinatorV2_5,
        //     uint256(config.subscriptionId),
        //     config.account
        // );
        // Call addConsumer directly from your EOA
        VRFCoordinatorV2_5 coordinator = VRFCoordinatorV2_5(config.vrfCoordinatorV2_5);
        coordinator.addConsumer(config.subscriptionId, address(raffle));

        vm.stopBroadcast();
    }

}
