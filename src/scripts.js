import { query } from "@onflow/fcl";

export const getBalance = async function (address) {
  const result = await query({
    cadence: `
    import "AwesomeCardGame"
    import "FlowToken"
    import "FungibleToken"

    access(all) fun main(address: Address): [AnyStruct] {
      let data: [AnyStruct] = []
      let vaultRef = getAccount(address).capabilities
          .borrow<&FlowToken.Vault>(/public/flowTokenBalance)
        ?? panic("Something wrong happened.")
      let cap = getAccount(address).capabilities.borrow<&AwesomeCardGame.Player>(/public/AwesomeCardGamePlayer)
        ?? panic("Doesn't have capability!")

      data.append(vaultRef.balance)
      data.append(cap.get_player_score().cyber_energy)
      data.append(cap.get_player_score().player_name)      
      return data
    }
    `,
    args: (arg, t) => [arg(address, t.Address)],
  });
  return result;
};
export const isRegistered = async function (address) {
  const result = await query({
    cadence: `
    import "AwesomeCardGame"
    access(all) fun main(address: Address): &AwesomeCardGame.Player? {
        return getAccount(address).capabilities.borrow<&AwesomeCardGame.Player>(/public/AwesomeCardGamePlayer)
    }
    `,
    args: (arg, t) => [arg(address, t.Address)],
  });
  return result;
};

export const getPlayerDeck = async function (address) {
  const result = await query({
    cadence: `
    import "AwesomeCardGame"
    access(all) fun main(address: Address): [UInt16] {
      let cap = getAccount(address).capabilities.borrow<&AwesomeCardGame.Player>(/public/AwesomeCardGamePlayer)
        ?? panic("Doesn't have capability!")
      return cap.get_player_deck()
    }
    `,
    args: (arg, t) => [arg(address, t.Address)],
  });
  return result;
};

export const getCurrentStatus = async function (address) {
  const result = await query({
    cadence: `
    import "AwesomeCardGame"
    access(all) fun main(address: Address): AnyStruct {
      let cap = getAccount(address).capabilities.borrow<&AwesomeCardGame.Player>(/public/AwesomeCardGamePlayer)
        ?? panic("Doesn't have capability!")
      return cap.get_current_status()
    }
    `,
    args: (arg, t) => [arg(address, t.Address)],
  });
  return result;
};

export const getMariganCards = async function (address) {
  const result = await query({
    cadence: `
    import "AwesomeCardGame"
    access(all) fun main(address: Address): AnyStruct {
      let cap = getAccount(address).capabilities.borrow<&AwesomeCardGame.Player>(/public/AwesomeCardGamePlayer)
        ?? panic("Doesn't have capability!")
      return cap.get_marigan_cards()
    }
    `,
    args: (arg, t) => [arg(address, t.Address)],
  });
  return result;
};
