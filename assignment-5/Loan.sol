pragma solidity >= 0.5.0 <0.7.0;
import "@aztec/protocol/contracts/ERC1724/ZkAssetMintable.sol";
import "@aztec/protocol/contracts/libs/NoteUtils.sol";
import "@aztec/protocol/contracts/interfaces/IZkAsset.sol";
import "./LoanUtilities.sol";

// this contract represents a confidential loan
contract Loan is ZkAssetMintable {

  using SafeMath for uint256;
  using NoteUtils for bytes;
  using LoanUtilities for LoanUtilities.LoanVariables;
  LoanUtilities.LoanVariables public loanVariables;


  IZkAsset public settlementToken;
  // [0] interestRate
  // [1] interestPeriod
  // [2] duration
  // [3] settlementCurrencyId
  // [4] loanSettlementDate
  // [5] lastInterestPaymentDate address public borrower;
  address public lender;
  address public borrower;

  mapping(address => bytes) lenderApprovals;

  event LoanPayment(string paymentType, uint256 lastInterestPaymentDate);
  event LoanDefault();
  event LoanRepaid();

  // Note struct containing its owners address and the hash of the note
  struct Note {
    address owner;
    bytes32 noteHash;
  }

  // 
  function _noteCoderToStruct(bytes memory note) internal pure returns (Note memory codedNote) {
      (address owner, bytes32 noteHash,) = note.extractNote();
      return Note(owner, noteHash );
  }

  // initiate a loan lender (contract deployer) and borrower 
  constructor(
    bytes32 _notional,
    uint256[] memory _loanVariables,
    address _borrower,
    address _aceAddress,
    address _settlementCurrency
   ) public ZkAssetMintable(_aceAddress, address(0), 1, true, false) {
      loanVariables.loanFactory = msg.sender;
      loanVariables.notional = _notional;
      loanVariables.id = address(this);
      loanVariables.interestRate = _loanVariables[0];
      loanVariables.interestPeriod = _loanVariables[1];
      loanVariables.duration = _loanVariables[2];
      loanVariables.borrower = _borrower;
      borrower = _borrower;
      loanVariables.settlementToken = IZkAsset(_settlementCurrency);
      loanVariables.aceAddress = _aceAddress;
  }

  function requestAccess() public {
    lenderApprovals[msg.sender] = '0x';
  }

  function approveAccess(address _lender, bytes memory _sharedSecret) public {
    lenderApprovals[_lender] = _sharedSecret;
  }

  // lender borrows money after proofs correctly validated
  function settleLoan(
    bytes calldata _proofData,
    bytes32 _currentInterestBalance,
    address _lender
  ) external {
    // check sender is not loan dapp
    LoanUtilities.onlyLoanDapp(msg.sender, loanVariables.loanFactory);

    // swap proofs 
    LoanUtilities._processLoanSettlement(_proofData, loanVariables);

    // update state of LoanVariables struct
    loanVariables.loanSettlementDate = block.timestamp;
    loanVariables.lastInterestPaymentDate = block.timestamp;
    loanVariables.currentInterestBalance = _currentInterestBalance;
    loanVariables.lender = _lender;
    lender = _lender;
  }

  // mint AZTEC notes 
  function confidentialMint(uint24 _proof, bytes calldata _proofData) external {
    // sender cant be loanDapp
    LoanUtilities.onlyLoanDapp(msg.sender, loanVariables.loanFactory);
    require(msg.sender == owner, "only owner can call the confidentialMint() method");
    require(_proofData.length != 0, "proof invalid");
    // overide this function to change the mint method to msg.sender
    (bytes memory _proofOutputs) = ace.mint(_proof, _proofData, msg.sender);

    (, bytes memory newTotal, ,) = _proofOutputs.get(0).extractProofOutput();

    (, bytes memory mintedNotes, ,) = _proofOutputs.get(1).extractProofOutput();

    (,
    bytes32 noteHash,
    bytes memory metadata) = newTotal.extractNote();

    logOutputNotes(mintedNotes);
    emit UpdateTotalMinted(noteHash, metadata);
  }

  // if proofs valid, withdraw interest from loan
  function withdrawInterest(
    bytes memory _proof1,
    bytes memory _proof2,
    uint256 _interestDurationToWithdraw
  ) public {
    // dividend proof
    (,bytes memory _proof1OutputNotes) = LoanUtilities._validateInterestProof(_proof1, _interestDurationToWithdraw, loanVariables);

    require(_interestDurationToWithdraw.add(loanVariables.lastInterestPaymentDate) < block.timestamp, ' withdraw is greater than accrued interest');
    // join-split proof
    (bytes32 newCurrentInterestNoteHash) = LoanUtilities._processInterestWithdrawal(_proof2, _proof1OutputNotes, loanVariables);

    // after validated, update state variable
    loanVariables.currentInterestBalance = newCurrentInterestNoteHash;
    loanVariables.lastInterestPaymentDate = loanVariables.lastInterestPaymentDate.add(_interestDurationToWithdraw);

    emit LoanPayment('INTEREST', loanVariables.lastInterestPaymentDate);

  }

  // only the borrower can adjust interest balance (?)
  // does join split proof, checks if interest note matches the input note
  // and output note is owned by the ACE contract
  function adjustInterestBalance(bytes memory _proofData) public {
    LoanUtilities.onlyBorrower(msg.sender,borrower);

    (bytes32 newCurrentInterestBalance) = LoanUtilities._processAdjustInterest(_proofData, loanVariables);
    loanVariables.currentInterestBalance = newCurrentInterestBalance;
  }

  // borrower can repay the loan
  function repayLoan(
    bytes memory _proof1,
    bytes memory _proof2
  ) public {
    LoanUtilities.onlyBorrower(msg.sender, borrower);

    uint256 remainingInterestDuration = loanVariables.loanSettlementDate.add(loanVariables.duration).sub(loanVariables.lastInterestPaymentDate);
    // dividend proof to validate interest ratio
    (,bytes memory _proof1OutputNotes) = LoanUtilities._validateInterestProof(_proof1, remainingInterestDuration, loanVariables);
    // check if loan end of life has been reached (?)
    require(loanVariables.loanSettlementDate.add(loanVariables.duration) < block.timestamp, 'loan has not matured');

    // send proof2 for join-split proof to validate correctness of output amount
    LoanUtilities._processLoanRepayment(
      _proof2,
      _proof1OutputNotes,
      loanVariables
    );

    emit LoanRepaid();
  }

  // lender can mark loan as default if the last interest payment date is in the past
  function markLoanAsDefault(bytes memory _proof1, bytes memory _proof2, uint256 _interestDurationToWithdraw) public {
    require(_interestDurationToWithdraw.add(loanVariables.lastInterestPaymentDate) < block.timestamp, 'withdraw is greater than accrued interest');
    LoanUtilities._validateDefaultProofs(_proof1, _proof2, _interestDurationToWithdraw, loanVariables);
    emit LoanDefault();
  }
}
