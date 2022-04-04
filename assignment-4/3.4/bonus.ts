import {
  Field,
  prop,
  PublicKey,
  CircuitValue,
  Signature,
  UInt64,
  UInt32,
  KeyedAccumulatorFactory,
  ProofWithInput,
  proofSystem,
  branch,
  MerkleStack,
  shutdown,
} from 'snarkyjs';

const AccountDbDepth: number = 32;
const AccountDb = KeyedAccumulatorFactory<PublicKey, RollupAccount>(
  AccountDbDepth
);
type AccountDb = InstanceType<typeof AccountDb>;

class RollupAccount extends CircuitValue {
  @prop balance: UInt64;
  @prop nonce: UInt32;
  @prop publicKey: PublicKey;

  constructor(balance: UInt64, nonce: UInt32, publicKey: PublicKey) {
    super();
    this.balance = balance;
    this.nonce = nonce;
    this.publicKey = publicKey;
  }
}

class RollupTransaction extends CircuitValue {
  @prop amount: UInt64;
  @prop nonce: UInt32;
  @prop sender: PublicKey;
  @prop receiver: PublicKey;

  constructor(
    amount: UInt64,
    nonce: UInt32,
    sender: PublicKey,
    receiver: PublicKey
  ) {
    super();
    this.amount = amount;
    this.nonce = nonce;
    this.sender = sender;
    this.receiver = receiver;
  }
}

class RollupDeposit extends CircuitValue {
  @prop publicKey: PublicKey;
  @prop amount: UInt64;
  constructor(publicKey: PublicKey, amount: UInt64) {
    super();
    this.publicKey = publicKey;
    this.amount = amount;
  }
}

class RollupState extends CircuitValue {
  @prop pendingDepositsCommitment: Field;
  @prop accountDbCommitment: Field;
  constructor(p: Field, c: Field) {
    super();
    this.pendingDepositsCommitment = p;
    this.accountDbCommitment = c;
  }
}

class RollupStateTransition extends CircuitValue {
  @prop source: RollupState;
  @prop target: RollupState;
  constructor(source: RollupState, target: RollupState) {
    super();
    this.source = source;
    this.target = target;
  }
}

// a recursive proof system is kind of like an "enum"
@proofSystem
class RollupProof extends ProofWithInput<RollupStateTransition> {
  // process deposit into the rollup
  @branch static processDeposit(
    pending: MerkleStack<RollupDeposit>,
    accountDb: AccountDb
  ): RollupProof {
    // get the state before the new deposit is processed
    let before = new RollupState(pending.commitment, accountDb.commitment());
    // get the account associated with the deposit, remove pending deposit if present
    let deposit = pending.pop();
    // check if account exists in storage
    let [{ isSome }, mem] = accountDb.get(deposit.publicKey);
    isSome.assertEquals(false);

    // combine proof with the account
    let account = new RollupAccount(
      UInt64.zero,
      UInt32.zero,
      deposit.publicKey
    );
    accountDb.set(mem, account);

    // store the commitment into a new state
    let after = new RollupState(pending.commitment, accountDb.commitment());

    return new RollupProof(new RollupStateTransition(before, after));
  }

  // Transaction on rollup
  @branch static transaction(
    t: RollupTransaction,
    s: Signature,
    pending: MerkleStack<RollupDeposit>,
    accountDb: AccountDb
  ): RollupProof {
    // generate privkey, verify the signature matches with the rollup transaction 
    s.verify(t.sender, t.toFields()).assertEquals(true);
    let stateBefore = new RollupState(
      pending.commitment,
      accountDb.commitment()
    );
    
    // check if sender account exists and nonce is the expected value
    let [senderAccount, senderPos] = accountDb.get(t.sender);
    senderAccount.isSome.assertEquals(true);
    senderAccount.value.nonce.assertEquals(t.nonce);
    
    // subtract the amount send from the sender and increment nonce
    senderAccount.value.balance = senderAccount.value.balance.sub(t.amount);
    senderAccount.value.nonce = senderAccount.value.nonce.add(1);

    // store the new information
    accountDb.set(senderPos, senderAccount.value);

    // add the value send by sender to receiver
    let [receiverAccount, receiverPos] = accountDb.get(t.receiver);
    receiverAccount.value.balance = receiverAccount.value.balance.add(t.amount);
    accountDb.set(receiverPos, receiverAccount.value);

    // update the previous state with the new state and commit to account-database
    let stateAfter = new RollupState(
      pending.commitment,
      accountDb.commitment()
    );
    return new RollupProof(new RollupStateTransition(stateBefore, stateAfter));
  }

  // Combine 2 proofs into 1, recursion takes place in this function
  @branch static merge(p1: RollupProof, p2: RollupProof): RollupProof {
    p1.publicInput.target.assertEquals(p2.publicInput.source);
    return new RollupProof(
      new RollupStateTransition(p1.publicInput.source, p2.publicInput.target)
    );
  }
}

shutdown();
