/**
 *Submitted for verification at Etherscan.io on 2020-01-30
*/

import "./Ownable.sol";
import "./ResolverBase.sol";
import "./ABIResolver.sol";
import "./AddrResolver.sol";
import "./ContentHashResolver.sol";
import "./InterfaceResolver.sol";
import "./NameResolver.sol";
import "./PubkeyResolver.sol";
import "./TextResolver.sol";

pragma solidity ^0.5.0;


/**
 * A simple resolver anyone can use; only allows the owner of a node to set its
 * address.
 */
contract OwnedResolver is Ownable, ABIResolver, AddrResolver, ContentHashResolver, InterfaceResolver, NameResolver, PubkeyResolver, TextResolver {
    function isAuthorised(bytes32 node) internal view returns(bool) {
        return msg.sender == owner();
    }
}