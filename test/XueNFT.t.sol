// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Test } from "forge-std/src/Test.sol";
import { console2 } from "forge-std/src/console2.sol";

import "../../src/XueNFT.sol";

/// @title XueNFTTest
/// @notice Do NOT modify this contract or you might get 0 points for the assignment.
/// @dev This contract includes tests for the XueNFT contract functionality.
contract XueNFTTest is Test {
    /*//////////////////////////////////////////////////////////////
                           STORAGE VARIABLES
    //////////////////////////////////////////////////////////////*/

    XueNFT internal nft;
    address internal Kevin;
    address internal Louis;
    address internal Jennifer;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                             SETUP FUNCTION
    //////////////////////////////////////////////////////////////*/

    function setUp() public {
        _deployAndSetUpNewNFT();
    }

    /*//////////////////////////////////////////////////////////////
                             DEFAULT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Name() public view {
        assertEq(nft.name(), "XueNFT");
    }

    function test_Symbol() public view {
        assertEq(nft.symbol(), "NFT");
    }

    function test_BalanceOf() public {
        assertEq(nft.balanceOf(Kevin), 1);
        assertEq(nft.balanceOf(Louis), 1);
        vm.expectRevert();
        nft.balanceOf(address(0));
    }

    function test_OwnerOf() public {
        assertEq(nft.ownerOf(0), Kevin);
        assertEq(nft.ownerOf(1), Louis);
        vm.expectRevert();
        nft.ownerOf(3);
    }

    /*//////////////////////////////////////////////////////////////
                  PART 1: COMPLETE APPROVE FUNCTION
    //////////////////////////////////////////////////////////////*/

    function test_Approve() public returns (bool) {
        vm.prank(Kevin);
        vm.expectEmit(true, true, true, false);
        emit Approval(Kevin, Louis, 0);
        nft.approve(Louis, 0);

        assertEq(nft.getApproved(0), Louis);
        return true;
    }

    function test_SetApprovalForAll() public returns (bool) {
        vm.prank(Kevin);
        vm.expectEmit(true, true, true, false);
        emit ApprovalForAll(Kevin, Louis, true);
        nft.setApprovalForAll(Louis, true);

        assertTrue(nft.isApprovedForAll(Kevin, Louis));

        vm.prank(Kevin);
        vm.expectEmit(true, true, true, false);
        emit ApprovalForAll(Kevin, Louis, false);
        nft.setApprovalForAll(Louis, false);

        assertFalse(nft.isApprovedForAll(Kevin, Louis));

        vm.prank(Kevin);
        vm.expectRevert();
        nft.setApprovalForAll(address(0), true);

        return true;
    }

    function test_Approve_RevertWhen_NotTokenOwner() public returns (bool) {
        vm.prank(Kevin);
        vm.expectRevert();
        nft.approve(Louis, 1);
        return true;
    }

    function test_Approve_ThenSetApprovalForAll() public returns (bool) {
        vm.prank(Kevin);
        vm.expectEmit(true, true, true, false);
        emit ApprovalForAll(Kevin, Louis, true);
        nft.setApprovalForAll(Louis, true);

        vm.prank(Louis);
        vm.expectEmit(true, true, true, false);
        emit Approval(Kevin, Jennifer, 0);
        nft.approve(Jennifer, 0);

        assertEq(nft.getApproved(0), Jennifer);
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                 PART 2: COMPLETE TRANSFERFROM FUNCTION
    //////////////////////////////////////////////////////////////*/

    function test_TransferFrom() public returns (bool) {
        vm.prank(Kevin);
        nft.approve(Louis, 0);

        vm.prank(Louis);
        vm.expectEmit(true, true, true, false);
        emit Transfer(Kevin, Louis, 0);
        nft.transferFrom(Kevin, Louis, 0);

        assertEq(nft.balanceOf(Kevin), 0);
        assertEq(nft.balanceOf(Louis), 2);
        assertEq(nft.ownerOf(0), Louis);
        assertEq(nft.ownerOf(1), Louis);

        return true;
    }

    function test_TransferFrom_RevertWhen_ZeroAddress() public returns (bool) {
        vm.prank(Kevin);
        nft.approve(Louis, 0);

        vm.prank(Louis);
        vm.expectRevert();
        nft.transferFrom(Kevin, address(0), 0);

        return true;
    }

    function test_TransferFrom_RevertWhen_NotOwner() public returns (bool) {
        vm.prank(Kevin);
        nft.approve(Louis, 0);

        vm.prank(Louis);
        vm.expectRevert();
        nft.transferFrom(Kevin, address(0), 1);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                PART 3: COMPLETE SAFETRANSFERFROM FUNCTION
    //////////////////////////////////////////////////////////////*/

    function test_SafeTransferFrom_EOA() public returns (bool) {
        vm.prank(Kevin);
        nft.approve(Louis, 0);

        vm.prank(Louis);
        vm.expectEmit(true, true, true, false);
        emit Transfer(Kevin, Louis, 0);
        nft.safeTransferFrom(Kevin, Louis, 0);

        assertEq(nft.balanceOf(Kevin), 0);
        assertEq(nft.balanceOf(Louis), 2);
        assertEq(nft.ownerOf(0), Louis);
        assertEq(nft.ownerOf(1), Louis);

        return true;
    }

    function test_SafeTransferFrom_CA_Success() public returns (bool) {
        MockSuccessReceiver receiver = new MockSuccessReceiver();

        vm.prank(Kevin);
        nft.approve(Louis, 0);

        vm.prank(Louis);
        vm.expectEmit(true, true, true, false);
        emit Transfer(Kevin, address(receiver), 0);
        nft.safeTransferFrom(Kevin, address(receiver), 0);

        assertEq(nft.balanceOf(Kevin), 0);
        assertEq(nft.balanceOf(address(receiver)), 1);
        assertEq(nft.ownerOf(0), address(receiver));
        assertEq(nft.ownerOf(1), Louis);

        return true;
    }

    function test_SafeTransferFrom_CA_Failure() public returns (bool) {
        MockBadReceiver receiver = new MockBadReceiver();

        vm.prank(Kevin);
        nft.approve(Louis, 0);

        vm.prank(Louis);
        vm.expectRevert();
        nft.safeTransferFrom(Kevin, address(receiver), 0);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                           MIXED OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function test_Approve_ThenTransferFrom() public {
        vm.prank(Kevin);
        nft.approve(Louis, 0);

        vm.prank(Louis);
        vm.expectEmit(true, true, true, false);
        emit Transfer(Kevin, Louis, 0);
        nft.transferFrom(Kevin, Louis, 0);

        assertEq(nft.balanceOf(Kevin), 0);
        assertEq(nft.balanceOf(Louis), 2);
        assertEq(nft.ownerOf(0), Louis);
        assertEq(nft.ownerOf(1), Louis);
    }

    function test_ApproveJennifer_ThenTransferFrom() public {
        vm.prank(Kevin);
        nft.approve(Louis, 0);

        vm.prank(Louis);
        vm.expectEmit(true, true, true, false);
        emit Transfer(Kevin, Jennifer, 0);
        nft.transferFrom(Kevin, Jennifer, 0);

        assertEq(nft.balanceOf(Kevin), 0);
        assertEq(nft.balanceOf(Jennifer), 1);
        assertEq(nft.ownerOf(0), Jennifer);
        assertEq(nft.ownerOf(1), Louis);
    }

    function test_SetApprovalForAll_ThenTransferFrom() public {
        vm.prank(Kevin);
        nft.setApprovalForAll(Louis, true);

        vm.prank(Louis);
        vm.expectEmit(true, true, true, false);
        emit Transfer(Kevin, Jennifer, 0);
        nft.transferFrom(Kevin, Jennifer, 0);

        assertEq(nft.balanceOf(Kevin), 0);
        assertEq(nft.balanceOf(Jennifer), 1);
        assertEq(nft.ownerOf(0), Jennifer);
        assertEq(nft.ownerOf(1), Louis);
    }

    /*//////////////////////////////////////////////////////////////
                           GET SCORE
    //////////////////////////////////////////////////////////////*/

    function test_CheckApproveRelatedPoints() public {
        if (
            test_Approve() && test_SetApprovalForAll() && test_Approve_RevertWhen_NotTokenOwner()
                && test_Approve_ThenSetApprovalForAll()
        ) {
            console2.log("Get 30 points");
        }
    }

    function test_CheckTransferFromPoints() public {
        if (
            test_TransferFrom() && test_TransferFrom_RevertWhen_ZeroAddress() && test_TransferFrom_RevertWhen_NotOwner()
        ) {
            console2.log("Get 30 points");
        }
    }

    function test_CheckSafeTransferFromPoints() public {
        if (test_SafeTransferFrom_EOA() && test_SafeTransferFrom_CA_Failure() && test_SafeTransferFrom_CA_Success()) {
            console2.log("Get 40 points");
        }
    }

    function test_CheckMixOperation() public {
        test_Approve_ThenTransferFrom();
        _resetState();
        test_ApproveJennifer_ThenTransferFrom();
        _resetState();
        test_SetApprovalForAll_ThenTransferFrom();
        console2.log("Get 100 points");
    }

    /*//////////////////////////////////////////////////////////////
                       HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _deployAndSetUpNewNFT() internal {
        nft = new XueNFT("XueNFT", "NFT");
        Kevin = makeAddr("Kevin");
        Louis = makeAddr("Louis");
        Jennifer = makeAddr("Jennifer");

        vm.prank(Kevin);
        nft.claim();

        vm.prank(Louis);
        nft.claim();
    }

    function _resetState() internal {
        vm.roll(block.number + 1);
        _deployAndSetUpNewNFT();
    }
}

contract MockSuccessReceiver is IERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        return IERC721TokenReceiver.onERC721Received.selector;
    }
}

contract MockBadReceiver is IERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4) {
        return bytes4(keccak256("approve(address,uint256)"));
    }
}
