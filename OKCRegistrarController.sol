/**
 *Submitted for verification at Etherscan.io on 2020-01-30
*/
pragma solidity ^0.5.0;
import "./PriceOracle.sol";
import "./ONS.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./BaseRegistrar.sol";
import "./StringUtils.sol";
import "./Resolver.sol";


/**
 * @dev A registrar controller for registering and renewing names at fixed cost.
 */
contract OKCRegistrarController is Ownable {
    using StringUtils for *;

    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));
    bytes4 constant private COMMITMENT_CONTROLLER_ID = bytes4(
        keccak256("rentPrice(string)") ^
        keccak256("available(string,uint8)") ^
        keccak256("register(string,address,bytes32)") 
    );

    bytes4 constant private COMMITMENT_WITH_CONFIG_CONTROLLER_ID = bytes4(
        keccak256("registerWithConfig(string,address,uint256,bytes32,address,address)") 
    );

    BaseRegistrar base;
    PriceOracle prices;



    event NameRegistered(string name, bytes32 indexed label, address indexed owner, uint cost);
    event NewPriceOracle(address indexed oracle); 

    constructor(BaseRegistrar _base, PriceOracle _prices) public {
        base = _base;
        prices = _prices;
    }

    function rentPrice(string memory name) view public returns(uint) {
        return prices.price(name);
    }

    function valid(string memory name) public pure returns(bool) {
        return name.strlen() >= 1;
    }

    function available(string memory name,uint8 _index) public view returns(bool) {
        bytes32 label = keccak256(bytes(name));
        return valid(name) && base.available(uint256(label),_index);
    }

    

    function register(string calldata name, address owner,uint8 _index) external payable {
      registerWithConfig(name, owner,  address(0), address(0),_index);
    }

    function toBytes(uint8 x) pure public returns (bytes memory b){
        b = new bytes(32);
        assembly{ mstore(add(b,32),x)}
    }
   
   function strConcat(string memory _a, string memory _b) public pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bret[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
    }    
    
    function toStr(uint256 value) public pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory data = abi.encodePacked(value);
        bytes memory str = new bytes(1);
        uint i = data.length - 1;
        str[0] = alphabet[uint(uint8(data[i] & 0x0f))];
        return string(str);
    }
    

    function uintToString(uint _uint) public pure returns (string memory str) {
        if(_uint==0) return '0';
        while (_uint != 0) {
            uint remainder = _uint % 10;
            _uint = _uint / 10;
            str = strConcat(toStr(remainder),str);
        }
 
    }
   
    function registerWithConfig(string memory name, address owner,address resolver, address addr,uint8 _index) public payable {
        uint cost = _consumeCost(name, _index);
        string memory names = strConcat(name,"-");
        string memory namevalue = strConcat(names,uintToString(_index));
        bytes32 label = keccak256(bytes(namevalue));
        uint256 tokenId = uint256(label); 
        if(resolver != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            base.register(tokenId, address(this),_index);

            // The nodehash of this label
            bytes32 nodehash = keccak256(abi.encodePacked(base.baseNodes(_index), label));

            // Set the resolver
            base.ons().setResolver(nodehash, resolver);

            // Configure the resolver
            if (addr != address(0)) {
                Resolver(resolver).setAddr(nodehash, addr);
            }

            // Now transfer full ownership to the expeceted owner
            base.reclaim(tokenId, owner,_index);
            base.transferFrom(address(this), owner, tokenId); 
        
        } else {
            require(addr == address(0));
        }

        emit NameRegistered(name, label, owner, cost);

        // Refund any extra payment
        if(msg.value > cost) {
            msg.sender.transfer(msg.value - cost);
        }
    }

    function setPriceOracle(PriceOracle _prices) public onlyOwner {
        prices = _prices;
        emit NewPriceOracle(address(prices));
    }



    function withdraw() public onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == INTERFACE_META_ID ||
               interfaceID == COMMITMENT_CONTROLLER_ID ||
               interfaceID == COMMITMENT_WITH_CONFIG_CONTROLLER_ID;
    }

    function _consumeCost(string memory name,uint8 _index) internal returns (uint256) {
        require(available(name,_index));
        uint cost = rentPrice(name);
        require(msg.value >= cost);
        return cost;
    }
}