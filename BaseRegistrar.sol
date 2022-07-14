
pragma solidity >=0.4.24;

import "./IERC721.sol";
import "./Ownable.sol";
import "./ONS.sol";

contract BaseRegistrar is IERC721, Ownable {
  
    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);
    event NameMigrated(uint256 indexed id, address indexed owner);
    event NameRegistered(uint256 indexed id, address indexed owner);
    event NameRenewed(uint256 indexed id);

    // The ONS registry
    ONS public ons;

    // The namehash of the TLD this registrar owns (eg, .okt okc)
    mapping(uint8=>bytes32) public baseNodes;


    // A map of addresses that are authorised to register and renew names.
    mapping(address=>bool) public controllers;

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) external;

    // Revoke controller permission for an address.
    function removeController(address controller) external;

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver,uint8 _index) external;


    // Returns true iff the specified name is available for registration.
    function available(uint256 id,uint8 _index) public view returns(bool);

    /**
     * @dev Register a name.
     */
    function register(uint256 id, address owner,uint8 _index) external returns(bool); 


    /**
     * @dev Reclaim ownership of a name in ONS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner,uint8 _index) external;
}
