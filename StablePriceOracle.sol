/**
 *Submitted for verification at Etherscan.io on 2019-04-30
*/

pragma solidity ^0.5.0;

import "./PriceOracle.sol";
import "./SafeMath.sol";
import "./StringUtils.sol";
import "./Ownable.sol";

interface ICableOraclePriceData
{
    function get(string calldata priceType, address source) external view returns (uint256 price, uint256 timestamp);
}


// StablePriceOracle sets a price in USD, based on an oracle.
contract StablePriceOracle is Ownable, PriceOracle {
    using SafeMath for *;
    using StringUtils for *;

    // Oracle address
    ICableOraclePriceData usdOracle;

    // Rent in attodollars (1e-18) per second
    uint[] public rentPrices;

    event OracleChanged(address oracle);
    event RentPriceChanged(uint[] prices);

     address private dataSource;

    constructor(ICableOraclePriceData _usdOracle, address _dataSource,uint[] memory _rentPrices) public {
        setOracle(_usdOracle);
        setPrices(_rentPrices);
        setDataSource(_dataSource);
    }

    /**
     * @dev Sets the price oracle address
     * @param _usdOracle The address of the price oracle to use.
     */
    function setOracle(ICableOraclePriceData _usdOracle) public onlyOwner {
        usdOracle = _usdOracle;
        emit OracleChanged(address(_usdOracle));
    }

    /**
     * @dev Sets the price oracle DataSource
     * @param _dataSource The address of the price dataSource to use.
     */
    function setDataSource(address _dataSource) public onlyOwner {
        dataSource = _dataSource;
    }

    /**
     * @dev Sets rent prices.
     * @param _rentPrices The price array. Each element corresponds to a specific
     *                    name length; names longer than the length of the array
     *                    default to the price of the last element.
     */
    function setPrices(uint[] memory _rentPrices) public onlyOwner {
        rentPrices = _rentPrices;
        emit RentPriceChanged(_rentPrices);
    }

    function getLatestPrice(string memory priceType, address source) public view returns (uint256) 
    {
        ICableOraclePriceData oracle = ICableOraclePriceData(usdOracle);
        (uint256  value, uint256 timestamp) = oracle.get(priceType, source);
        return value;
    }
    
    /**
    * @notice A specific example to get BTC-USD price
    */
    function getOktPrice() public view returns (uint256) 
    {
        return getLatestPrice("OKT", dataSource);
    }

    /**
     * @dev Returns the price to register or renew a name.
     * @param name The name being registered or renewed.
     * @return The price of this renewal or registration, in wei.
     */
    function price(string calldata name) view external returns(uint) {
        uint len = name.strlen();
        if(len > rentPrices.length) {
            len = rentPrices.length;
        }
        require(len > 0);
        uint priceUSD = rentPrices[len - 1];

        // Price of one ether in attodollars
        uint oktPrice = uint(getOktPrice());

        return priceUSD.mul(1e24).div(oktPrice);
    }
}