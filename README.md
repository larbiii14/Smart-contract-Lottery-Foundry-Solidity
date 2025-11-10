Foundry Smart Contract Lottery (Raffle) on Sepolia

This project is a decentralized lottery (raffle) smart contract built with Solidity 0.8.19 and deployed using Foundry on the Sepolia testnet. It demonstrates a complete workflow for deploying and interacting with a Chainlink VRF-powered contract, including subscription creation, funding, and consumer management.

Key Features

Raffle Smart Contract: Allows participants to enter a lottery with a fixed ETH entrance fee.
Chainlink VRF v2.5 Integration: Ensures provably fair random winner selection.
Automated Deployment Script: Uses Foundry scripts to deploy the contract, set up subscriptions, and add consumers.
Broadcast to Sepolia Testnet: Supports real blockchain interactions, with transaction tracking and logging.
Modular Design: Includes separate scripts for deployment, subscription creation, funding, and consumer management.
Tech Stack

Solidity 0.8.19
Foundry (Forge & Cast)
Chainlink VRF v2.5
Sepolia Testnet
Usage

Clone the repo:

git clone https://github.com/larbiii14/foundry-smart-contract-lottery.git
cd foundry-smart-contract-lottery
Set up environment variables:

export SEPOLIA_RPC_URL="your_sepolia_rpc_url"
export PRIVATE_KEY="your_wallet_private_key"
Deploy the Raffle contract:

forge script script/DeployRaffle.s.sol:DeployRaffle --rpc-url $SEPOLIA_RPC_URL --account myaccount --broadcast -vvvv
Check your deployed contract address in the logs or JSON broadcast file.

Goal

This repo is perfect for learning Foundry scripting, Chainlink VRF integration, and end-to-end smart contract deployment on Ethereum testnets.
