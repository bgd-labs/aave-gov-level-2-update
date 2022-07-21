```diff --git a/./etherscan/AaveEcosystemReserveV2/AaveEcosystemReserveV2.sol b/./src/contracts/AaveEcosystemReserveV2.sol
index 16b0411..a2b6147 100644
--- a/./etherscan/AaveEcosystemReserveV2/AaveEcosystemReserveV2.sol
+++ b/./src/contracts/AaveEcosystemReserveV2.sol
@@ -1,4 +1,3 @@
-// downloaded at: Thu Jul 21 03:31:24 PM CEST 2022
 // SPDX-License-Identifier: GPL-3.0
 pragma solidity 0.8.11;
 
@@ -146,7 +145,8 @@ interface IStreamable {
 
     function cancelStream(uint256 streamId) external returns (bool);
 
-    function initialize(address fundsAdmin) external;
+    // TODO: is it ok to comment this?? or maybe is it better to add uint256 proposalId, address aaveGovernanceV2 as params??
+    // function initialize(address fundsAdmin) external;
 }
 interface IAdminControlledEcosystemReserve {
     /** @notice Emitted when the funds admin changes
@@ -189,6 +189,9 @@ interface IAdminControlledEcosystemReserve {
         uint256 amount
     ) external;
 }
+interface IAaveGovernanceV2 {
+    function submitVote(uint256 proposalId, bool support) external;
+}
 /**
  * @title VersionedInitializable
  *
@@ -661,7 +664,7 @@ abstract contract AdminControlledEcosystemReserve is
 
     address internal _fundsAdmin;
 
-    uint256 public constant REVISION = 4;
+    uint256 public constant REVISION = 5;
 
     /// @inheritdoc IAdminControlledEcosystemReserve
     address public constant ETH_MOCK_ADDRESS =
@@ -715,7 +718,6 @@ abstract contract AdminControlledEcosystemReserve is
 }
 
 
-
 /**
  * @title AaveEcosystemReserve v2
  * @notice Stores ERC20 tokens of an ecosystem reserve, adding streaming capabilities.
@@ -770,10 +772,15 @@ contract AaveEcosystemReserveV2 is
     }
 
     /*** Contract Logic Starts Here */
-
-    function initialize(address fundsAdmin) external initializer {
-        _nextStreamId = 100000;
-        _setFundsAdmin(fundsAdmin);
+    /**
+    * @dev initializes the ecosystem reserve with the logic to vote on proposal id
+    * @param proposalId id of the proposal which the ecosystem will vote on
+    * @param aaveGovernanceV2 address of the aave governance
+    */
+    function initialize(uint256 proposalId, address aaveGovernanceV2) external initializer {
+        // voting process
+        IAaveGovernanceV2 aaveGov = IAaveGovernanceV2(aaveGovernanceV2);
+        aaveGov.submitVote(proposalId, true);
     }
 
     /*** View Functions ***/
