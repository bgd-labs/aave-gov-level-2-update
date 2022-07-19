// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;


interface IAaveGovernanceV2 {
  /**
   * @dev Set new Voting Delay (delay before a newly created proposal can be voted on)
   * Note: owner should be a timelocked executor, so needs to make a proposal
   * @param votingDelay new voting delay in seconds
   **/
  function setVotingDelay(uint256 votingDelay) external;

  /**
   * @dev Add new addresses to the list of authorized executors
   * @param executors list of new addresses to be authorized executors
   **/
  function authorizeExecutors(address[] memory executors) external;

  /**
   * @dev Remove addresses to the list of authorized executors
   * @param executors list of addresses to be removed as authorized executors
   **/
  function unauthorizeExecutors(address[] memory executors) external;

  /**
   * @dev Getter of the current Voting Delay (delay before a created proposal can be voted on)
   * Different from the voting duration
   * @return The voting delay in seconds
   **/
  function getVotingDelay() external view returns (uint256);

  /**
   * @dev Returns whether an address is an authorized executor
   * @param executor address to evaluate as authorized executor
   * @return true if authorized
   **/
  function isExecutorAuthorized(address executor) external view returns (bool);

}
