/**
 *Submitted for verification at Etherscan.io on 2020-01-30
*/

pragma solidity ^0.5.0;

import "./ONS.sol";
import "./ONSRegistry.sol";

/**
 * The ONS registry contract.
 */
contract ONSRegistryWithFallback is ONSRegistry {

  
    /**
     * @dev Returns the address of the resolver for the specified node.
     * @param node The specified node.
     * @return address of the resolver.
     */
    function resolver(bytes32 node) public view returns (address) {
        return super.resolver(node);
    }

    /**
     * @dev Returns the address that owns the specified node.
     * @param node The specified node.
     * @return address of the owner.
     */
    function owner(bytes32 node) public view returns (address) {
        return super.owner(node);
    }

    /**
     * @dev Returns the TTL of a node, and any records associated with it.
     * @param node The specified node.
     * @return ttl of the node.
     */
    function ttl(bytes32 node) public view returns (uint64) {
          return super.ttl(node);
    }

    function _setOwner(bytes32 node, address owner) internal {
        address addr = owner;
        if (addr == address(0x0)) {
            addr = address(this);
        }

        super._setOwner(node, addr);
    }
}