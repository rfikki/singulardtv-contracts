import "AbstractSingularDTVToken.sol";
import "AbstractSingularDTVCrowdfunding.sol";


/// @title Fund contract - Implements revenue distribution.
/// @author Stefan George - <stefan.george@consensys.net>
contract SingularDTVFund {

    /*
     *  External contracts
     */
    SingularDTVToken public singularDTVToken;
    SingularDTVCrowdfunding public singularDTVCrowdfunding;

    /*
     *  Storage
     */
    address public owner;
    address constant public workshop = {{MistWallet}};
    uint public totalRevenue;

    // User's address => Revenue at time of withdraw
    mapping (address => uint) public revenueAtTimeOfWithdraw;

    /*
     *  Modifiers
     */
    modifier noEther() {
        if (msg.value > 0) {
            throw;
        }
        _
    }

    modifier onlyOwner() {
        // Only guard is allowed to do this action.
        if (msg.sender != owner) {
            throw;
        }
        _
    }

    modifier onlySingularDTVToken() {
        // Only guard is allowed to do this action.
        if (msg.sender != address(singularDTVToken)) {
            throw;
        }
        _
    }

    modifier campaignEndedSuccessfully() {
        if (!singularDTVCrowdfunding.campaignEndedSuccessfully()) {
            throw;
        }
        _
    }

    /*
     *  Contract functions
     */
    /// @dev Deposits revenue. Returns success.
    function depositRevenue()
        external
        campaignEndedSuccessfully
        returns (bool)
    {
        totalRevenue += msg.value;
        return true;
    }

    function calcRevenueShare(address forAddress) internal returns (uint) {
        return singularDTVToken.balanceOf(forAddress) * (totalRevenue - revenueAtTimeOfWithdraw[forAddress]) / singularDTVToken.totalSupply();
    }

    /// @dev Withdraws revenue share for user. Returns revenue share.
    /// @param reinvestToWorkshop User can reinvest his revenue share. The workshop always reinvests its revenue share.
    function withdrawRevenue(bool reinvestToWorkshop)
        external
        noEther
        returns (uint)
    {
        uint value = calcRevenueShare(msg.sender);
        revenueAtTimeOfWithdraw[msg.sender] = totalRevenue;
        if (reinvestToWorkshop || msg.sender == workshop) {
            if (value > 0 && !workshop.send(value)) {
                throw;
            }
        }
        else {
            if (value > 0 && !msg.sender.send(value)) {
                throw;
            }
        }
        return value;
    }

    /// @dev Withdraws revenue share for user. Returns revenue share.
    /// @param forAddress Shareholder's address.
    function withdrawRevenueFor(address forAddress)
        external
        noEther
        onlySingularDTVToken
        returns (uint)
    {
        uint value = calcRevenueShare(forAddress);
        revenueAtTimeOfWithdraw[forAddress] = totalRevenue;
        if (value > 0 && !forAddress.send(value)) {
            throw;
        }
        return value;
    }

    /// @dev Setup function sets external contracts' addresses.
    /// @param singularDTVTokenAddress Token address.
    function setup(address singularDTVCrowdfundingAddress, address singularDTVTokenAddress)
        external
        noEther
        onlyOwner
        returns (bool)
    {
        if (address(singularDTVCrowdfunding) == 0 || address(singularDTVToken) == 0) {
            singularDTVCrowdfunding = SingularDTVCrowdfunding(singularDTVCrowdfundingAddress);
            singularDTVToken = SingularDTVToken(singularDTVTokenAddress);
            return true;
        }
        return false;
    }

    /// @dev Contract constructor function sets guard and initial token balances.
    function SingularDTVFund() {
        // Set owner address
        owner = msg.sender;
    }
}
