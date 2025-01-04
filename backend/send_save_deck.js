import fs from "fs";
import fcl from "@onflow/fcl";
import { SHA3 } from "sha3";
import pkg from "elliptic";
const { ec } = pkg;
import { argv } from "node:process";

var player_id;
var player_deck;

argv.forEach((val, index) => {
  if (index == 2) {
    player_id = val;
  } else if (index == 3) {
    player_deck = JSON.parse(val);
  }
});

fcl
  .config()
  .put("flow.network", "emulator")
  .put("accessNode.api", "http://localhost:8888");

try {
  var KEY_ID_IT = 0;
  // 以下はProposerのKeyが300ある場合を想定したものなのでエミュレータでは0とする
  // if (fs.existsSync("/tmp/sequence.txt")) {
  //   KEY_ID_IT = parseInt(
  //     fs.readFileSync("/tmp/sequence.txt", { encoding: "utf8" })
  //   );
  // } else {
  //   KEY_ID_IT = new Date().getMilliseconds() % 300;
  // }
  // KEY_ID_IT = !KEY_ID_IT || KEY_ID_IT >= 300 ? 1 : KEY_ID_IT + 1;
  // fs.writeFileSync("/tmp/sequence.txt", KEY_ID_IT.toString());

  const ec_ = new ec("p256");

  /* CHANGE THESE THINGS FOR YOU */
  /* 注意! これはエミュレータのプライベートキーなので、テストネットやメインエットに影響がないのでコードに埋めているが、本来は決して行ってはならない */
  const PRIVATE_KEY = `9ba63c9cd20a8214bcd8178b6d65d6cb54725670bba95a56f30d3bb1de9baaf4`;
  const ADDRESS = "0xf8d6e0586b0a20c7";
  const KEY_ID = 0;

  const sign = (message) => {
    const key = ec_.keyFromPrivate(Buffer.from(PRIVATE_KEY, "hex"));
    const sig = key.sign(hash(message)); // hashMsgHex -> hash
    const n = 32;
    const r = sig.r.toArrayLike(Buffer, "be", n);
    const s = sig.s.toArrayLike(Buffer, "be", n);
    return Buffer.concat([r, s]).toString("hex");
  };
  const hash = (message) => {
    const sha = new SHA3(256);
    sha.update(Buffer.from(message, "hex"));
    return sha.digest();
  };

  async function authorizationFunction(account) {
    return {
      ...account,
      tempId: `${ADDRESS}-${KEY_ID}`,
      addr: fcl.sansPrefix(ADDRESS),
      keyId: Number(KEY_ID),
      signingFunction: async (signable) => {
        return {
          addr: fcl.withPrefix(ADDRESS),
          keyId: Number(KEY_ID),
          signature: sign(signable.message),
        };
      },
    };
  }
  async function authorizationFunctionProposer(account) {
    return {
      ...account,
      tempId: `${ADDRESS}-${KEY_ID_IT}`,
      addr: fcl.sansPrefix(ADDRESS),
      keyId: Number(KEY_ID_IT),
      signingFunction: async (signable) => {
        return {
          addr: fcl.withPrefix(ADDRESS),
          keyId: Number(KEY_ID_IT),
          signature: sign(signable.message),
        };
      },
    };
  }

  console.log(player_id, player_deck, KEY_ID, KEY_ID_IT);
  /* Save the player's card deck. */
  let transactionId = await fcl.mutate({
    cadence: `
      import AwesomeCardGame from 0xf8d6e0586b0a20c7

      transaction(player_id: UInt, player_deck: [UInt16]) {
        prepare(signer: auth(BorrowValue) &Account) {
          let admin = signer.storage.borrow<&AwesomeCardGame.Admin>(from: /storage/AwesomeCardGameAdmin)
            ?? panic("Could not borrow reference to the Administrator Resource.")
          admin.save_deck(player_id: player_id, player_deck: player_deck)
        }
        execute {
          log("success")
        }
      }
    `,
    args: (arg, t) => [
      arg(player_id, t.UInt),
      arg(player_deck, t.Array(t.UInt16)),
    ],
    proposer: authorizationFunctionProposer,
    payer: authorizationFunction,
    authorizations: [authorizationFunction],
    limit: 999,
  });
  console.log(`TransactionId: ${transactionId}`);
  fcl.tx(transactionId).subscribe((res) => {
    console.log(res);
  });
} catch (error) {
  console.error(error);
}
