// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test, CodeConstants {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    address public PLAYER = makeAddr("player");
    uint256 public constant PLAYER_STARTING_BALANCE = 10 ether;

function setUp() external {
    DeployRaffle deployer = new DeployRaffle();
    (raffle, helperConfig) = deployer.deployContract();
    HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

    entranceFee = config.raffleEntranceFee;
    interval = config.automationUpdateInterval;
    vrfCoordinator = config.vrfCoordinatorV2_5;
    gasLane = config.gasLane;
    subscriptionId = config.subscriptionId;
    callbackGasLimit = config.callbackGasLimit;

    vm.deal(PLAYER, PLAYER_STARTING_BALANCE);

    // Register Raffle as consumer using subscription owner
    vm.prank(config.account); // <-- impersonate subscription owner
    VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subscriptionId, address(raffle));
}

    function testRaffleStateStartsOpen() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertWhenNoEntranceFees() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__SendMoreEthToRaffle.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayers() public {
        //Arrange
        vm.prank(PLAYER);
        //Act
        raffle.enterRaffle{value: entranceFee}();
        //Assert
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEnteringRaggleEmitsEvent() public {
        //Arrange
        vm.prank(PLAYER);
        //Act
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        //Assert
        raffle.enterRaffle{value: entranceFee}();
    }

    function testPreventEnteringWhileCalculating() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        //Act, Assert
        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function checkUpKeepReturnsFalseIfItHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool UpKeepNeeded,) = raffle.checkUpkeep("");

        //assert
        assert(!UpKeepNeeded);
    }

    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");

        // Act
        (bool UpKeepNeeded,) = raffle.checkUpkeep("");

        //assert
        assert(!UpKeepNeeded);
    }

    /*//////////////////////////////////////////////////////////////
                             PERFORMUPKEEP
    //////////////////////////////////////////////////////////////*/

    function testcheckperformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act / Assert
        raffle.performUpkeep("");
    }

    function testcheckperformUpkeepCanOnlyRunIfCheckUpkeepIsFalse() public {
    // Arrange
    uint256 currentBalance = 0;
    uint256 numPlayers = 0;
    Raffle.RaffleState rState = raffle.getRaffleState();

    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    currentBalance = currentBalance + entranceFee;
    numPlayers = 1;


    // Act Assert
    vm.expectRevert(
        abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance,
        numPlayers, rState)
    );
    raffle.performUpkeep("");
    }

    modifier RafflEntered {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public RafflEntered {
        // Act
        vm.recordLogs(); // Collect any emitted events (by performUpkeep function) into an array
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // Assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }

    /*//////////////////////////////////////////////////////////////
                           FULLFILRANDOMWORDS
    //////////////////////////////////////////////////////////////*/

    modifier skipFork {
        if(block.chainid != LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

    function testFullfillrandomwordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId) public RafflEntered skipFork {
        // Arrange / Act / Assert
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
    }

function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public RafflEntered skipFork {
    // Arrange: add 3 more entrants
    for (uint256 i = 1; i <= 3; i++) {
        address newPlayer = address(uint160(i + 2));
        hoax(newPlayer, 1 ether);
        raffle.enterRaffle{value: entranceFee}();
    }

    uint256 totalPlayers = 4; // including PLAYER
    uint256 prize = entranceFee * totalPlayers;


    uint256 startingTime = raffle.getLastTimeStamp();

    // Act: perform upkeep and fulfill randomness
    vm.recordLogs();
    raffle.performUpkeep(""); 
    Vm.Log[] memory entries = vm.getRecordedLogs();
    uint256 requestId = uint256(entries[1].topics[1]);

    VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(requestId, address(raffle));

    // Assert
    address recentWinner = raffle.getRecentWinner();
    Raffle.RaffleState raffleState = raffle.getRaffleState();
    uint256 endingTime = raffle.getLastTimeStamp();
    uint256 endingRaffleBalance = address(raffle).balance;

    assert(raffleState == Raffle.RaffleState.OPEN);
    assert(endingTime > startingTime);
    assert(endingRaffleBalance == 0); // Contract balance should be emptied
    // Winner's balance should increase by at least entranceFee * totalPlayers
    assert(recentWinner.balance >= prize);
}
}
