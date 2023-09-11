// Khai báo phiên bản Solidity
pragma solidity ^0.8.0;

// Import chuẩn giao thức ERC-20
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// Khai báo hợp đồng
contract CarWallet is AccessControl {
    bytes32 public constant INVESTOR_ROLE = keccak256("INVESTOR_ROLE");
    bytes32 public constant DRIVER_ROLE = keccak256("DRIVER_ROLE");
    address public driverWallet;
    address public investorWallet;
    address public owner;
    uint256 public totalRevenue;
    uint256 public investorWithDrawed;
    uint256 public driverWithDrawed;
    uint256 public investorWithDrawable;
    uint256 public driverWithDrawable;
    IERC20 public token; // Đối tượng token
    uint256 public withdrawalThreshold; // Ngưỡng tiền để chuyển cho lái xe

    constructor(
        address _driverWallet,
        address _investorWallet,
        address _tokenAddress,
        uint256 _withdrawalThreshold
    ) {
        driverWallet = _driverWallet;
        investorWallet = _investorWallet;
        _grantRole(INVESTOR_ROLE, _driverWallet);
        _grantRole(DRIVER_ROLE, _investorWallet);
        owner = msg.sender;
        token = IERC20(_tokenAddress); // Khởi tạo đối tượng token
        withdrawalThreshold = _withdrawalThreshold;
    }
    function getMax(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function withdrawInvestor() public onlyRole(INVESTOR_ROLE) returns (bool) {
        totalRevenue =
            token.balanceOf(address(this)) +
            investorWithDrawed +
            driverWithDrawed;

        if (totalRevenue >= withdrawalThreshold) {
            investorWithDrawable = getMax(
                0,
                withdrawalThreshold / 2 - investorWithDrawed
            );
            if (investorWithDrawable > 0) {
                token.transfer(msg.sender, investorWithDrawable);
            }
        } else {
            investorWithDrawable = totalRevenue / 2 - investorWithDrawed;
            token.transfer(msg.sender, investorWithDrawable);
        }
        investorWithDrawed = investorWithDrawed + investorWithDrawable;
        investorWithDrawable = 0;
        return true;
    }


    function withdrawDriver() public onlyRole(DRIVER_ROLE) returns (bool) {
        totalRevenue =
            token.balanceOf(address(this)) +
            investorWithDrawed +
            driverWithDrawed;
        if (totalRevenue > withdrawalThreshold) {
            driverWithDrawable =
                getMax(0, withdrawalThreshold / 2) +
                (totalRevenue - withdrawalThreshold) -
                driverWithDrawed;
            token.transfer(msg.sender, driverWithDrawable);
        } else {
            driverWithDrawable = totalRevenue / 2 - driverWithDrawed;
            token.transfer(msg.sender, driverWithDrawable);
        }

        driverWithDrawed = driverWithDrawed + driverWithDrawable;
        driverWithDrawable = 0;
        return true;
    }


    function updateAll() public returns (bool) {
        totalRevenue =
            token.balanceOf(address(this)) +
            investorWithDrawed +
            driverWithDrawed;

        if (totalRevenue > withdrawalThreshold) {
            driverWithDrawable =
                getMax(0, withdrawalThreshold / 2) +
                (totalRevenue - withdrawalThreshold) -
                driverWithDrawed;
            investorWithDrawable = getMax(
                0,
                withdrawalThreshold / 2 - investorWithDrawed
            );
        } else {
            driverWithDrawable = totalRevenue / 2 - driverWithDrawed;
            investorWithDrawable = totalRevenue / 2 - investorWithDrawed;
        }
        return true;
    }
}
