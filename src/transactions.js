import { mutate, authz } from "@onflow/fcl";

export const createPlayer = async function (nickname) {
  const txId = await mutate({
    cadence: `
      import "AwesomeCardGame"
      import "FlowToken"
      import "FungibleToken"

      transaction(nickname: String) {
        prepare(signer: auth(Storage, Capabilities) &Account) {
          let FlowTokenReceiver = signer.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)

          signer.storage.save(<- AwesomeCardGame.createPlayer(nickname: nickname, flow_vault_receiver: FlowTokenReceiver), to: /storage/AwesomeCardGamePlayer)
          let cap = signer.capabilities.storage.issue<&AwesomeCardGame.Player>(/storage/AwesomeCardGamePlayer)
          signer.capabilities.publish(cap, at: /public/AwesomeCardGamePlayer)
        }
        execute {
          log("success")
        }
      }
    `,
    args: (arg, t) => [arg(nickname, t.String)],
    proposer: authz,
    payer: authz,
    authorizations: [authz],
    limit: 999,
  });
  console.log(txId);
  return txId;
};

export const buyCyberEn = async function () {
  const txId = await mutate({
    cadence: `
      import "AwesomeCardGame"
      import "FlowToken"
      import "FungibleToken"

      transaction() {
        prepare(signer: auth(BorrowValue) &Account) {
          let payment <- signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)!.withdraw(amount: 2.0) as! @FlowToken.Vault

          let player = signer.storage.borrow<&AwesomeCardGame.Player>(from: /storage/AwesomeCardGamePlayer)
              ?? panic("Could not borrow reference to the Owner's Player Resource.")
          player.buy_en(payment: <- payment)
        }
        execute {
          log("success")
        }
      }
    `,
    args: (arg, t) => [],
    proposer: authz,
    payer: authz,
    authorizations: [authz],
    limit: 999,
  });
  console.log(txId);
  return txId;
};
