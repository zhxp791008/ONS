/**
 *Submitted for verification at Etherscan.io on 2020-01-30
*/

pragma solidity ^0.5.0;
import "./ONS.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./ERC165.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./BaseRegistrar.sol";


contract BaseRegistrarImplementation is BaseRegistrar, ERC721 {

    mapping(uint8=>mapping(uint256=>bool)) private registered;


    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant private ERC721_ID = bytes4(
        keccak256("balanceOf(address)") ^
        keccak256("ownerOf(uint256)") ^
        keccak256("approve(address,uint256)") ^
        keccak256("getApproved(uint256)") ^
        keccak256("setApprovalForAll(address,bool)") ^
        keccak256("isApprovedForAll(address,address)") ^
        keccak256("transferFrom(address,address,uint256)") ^
        keccak256("safeTransferFrom(address,address,uint256)") ^
        keccak256("safeTransferFrom(address,address,uint256,bytes)")
    );
    bytes4 constant private RECLAIM_ID = bytes4(keccak256("reclaim(uint256,address)"));

    constructor(ONS _ons)
    ERC721("ONS", "ONS")
    public {
        ons = _ons;
    }


    function addBaseNode(uint8 _index,bytes32 _baseNode) external onlyOwner {
        require(baseNodes[_index]==0x0000000000000000000000000000000000000000000000000000000000000000);
        baseNodes[_index] = _baseNode;
    }



    modifier onlyController {
        require(controllers[msg.sender]);
        _;
    }

    /**
     * @dev Gets the owner of the specified token ID. Names become unowned
     *      when their registration expires.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        return super.ownerOf(tokenId);
    }

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
        emit ControllerAdded(controller);
    }

    // Revoke controller permission for an address.
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
        emit ControllerRemoved(controller);
    }

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver,uint8 _index) external onlyOwner {
        ons.setResolver(baseNodes[_index], resolver);
    }

    /**
     * @dev Register a name.
     * @param id The token ID (keccak256 of the label).
     * @param owner The address that should own the registration.
     */
    function register(uint256 id, address owner,uint8 _index) external returns(bool) {
      return _register(id, owner, true,_index);
    }

    /**
     * @dev Register a name, without modifying the registry.
     * @param id The token ID (keccak256 of the label).
     * @param owner The address that should own the registration.
     */
    function registerOnly(uint256 id, address owner,uint8 _index) external returns(bool) {
      return _register(id, owner, false,_index);
    }

    function available(uint256 id,uint8 _index) public view returns(bool) {
        // Not available if it's registered here or in its grace period.
        return !registered[_index][id];
    }
    
    function _register(uint256 id, address owner, bool updateRegistry,uint8 _index) internal onlyController returns(bool) {
        require(ons.owner(baseNodes[_index]) == address(this));
        require(available(id,_index));
        registered[_index][id] = true;
        tlds[id] = _index+1;
        _mint(owner, id); 
        if(updateRegistry) {
            ons.setSubnodeOwner(baseNodes[_index], bytes32(id), owner);
        }

        emit NameRegistered(id, owner);

        return true;
    }

    mapping(uint256=>uint8) private tlds;  

    /**
     * @dev Reclaim ownership of a name in ONS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner,uint8 _index) external {
        require(tlds[id] == (_index+1));
        require(ons.owner(baseNodes[_index]) == address(this));
        require(_isApprovedOrOwner(msg.sender, id));
        ons.setSubnodeOwner(baseNodes[_index], bytes32(id), owner);
    }

    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return interfaceID == INTERFACE_META_ID ||
               interfaceID == ERC721_ID ||
               interfaceID == RECLAIM_ID;
    }
}