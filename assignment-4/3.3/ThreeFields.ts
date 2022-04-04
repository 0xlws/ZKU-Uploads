import {
  Field,
  PrivateKey,
  PublicKey,
  SmartContract,
  state,
  State,
  method,
  UInt64,
  Mina,
  Party,
  isReady,
  shutdown,
} from 'snarkyjs';

class ThreeFields extends SmartContract {
  @state(Field) a: State<Field>;
  @state(Field) b: State<Field>;
  @state(Field) c: State<Field>;

  constructor(
    initialBalance: UInt64,
    address: PublicKey,
    a: Field,
    b: Field,
    c: Field
  ) {
    super(address);
    this.balance.addInPlace(initialBalance);
    this.a = State.init(a);
    this.b = State.init(b);
    this.c = State.init(c);
  }

  @method async update(x: Field, y: Field, z: Field) {
    const a = await this.a.get();
    const b = await this.b.get();
    const c = await this.c.get();
    this.a.set(x);
    this.b.set(y);
    this.c.set(z);
    this.balance.subInPlace(UInt64.fromNumber(1337));
    // throw new Error('TODO: Create 3 fields');
  }
}

export async function run() {
  await isReady;

  const Local = Mina.LocalBlockchain();
  Mina.setActiveInstance(Local);
  const account1 = Local.testAccounts[0].privateKey;
  const account2 = Local.testAccounts[1].privateKey;

  const snappPrivkey = PrivateKey.random();
  const snappPubkey = snappPrivkey.toPublicKey();

  let snappInstance: ThreeFields;
  const initA = new Field(0);
  const initB = new Field(0);
  const initC = new Field(0);

  // Deploys the snapp
  await Mina.transaction(account1, async () => {
    // account2 sends 1000000000 to the new snapp account
    const amount = UInt64.fromNumber(1000000000);
    const p = await Party.createSigned(account2);
    p.balance.subInPlace(amount);

    snappInstance = new ThreeFields(amount, snappPubkey, initA, initB, initC);
  })
    .send()
    .wait();

  await Mina.transaction(account1, async () => {
    await snappInstance.update(new Field(667), new Field(2), new Field(3));
  })
    .send()
    .wait();

  const account = await Mina.getAccount(snappPubkey);

  console.log('ThreeFields');
  const state1 = account.snapp.appState[0];
  const state2 = account.snapp.appState[1];
  const state3 = account.snapp.appState[2];
  const finalStateVal = state1.mul(state2).add(state3);
  console.log('final state value', finalStateVal.toString());
  return finalStateVal;
}

run();
shutdown();
