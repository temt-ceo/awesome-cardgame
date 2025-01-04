<script>
import { config, authenticate, unauthenticate, currentUser } from '@onflow/fcl';
import { getBalance, isRegistered, getPlayerDeck, getCurrentStatus, getMariganCards } from '../scripts';
import { createPlayer, buyCyberEn } from '../transactions'
import flowJSON from '../flow.json';
const network = 'emulator';
let walletUser;
let playerName;
let flowBalance;
let cyberEnergyBalance;
let hasResource;
let playerDeck;
let currentStatus;
let mariganCards;
config({
  'flow.network': network,
  'accessNode.api': 'http://localhost:8888',
  'discovery.wallet': 'http://localhost:8701/fcl/authn',
}).load({ flowJSON });
currentUser.subscribe(async (user) => {
  walletUser = user;
  if (user.addr) {
    hasResource = await isRegistered(user.addr);
    if (hasResource) {
      const [flowTokenBalance, cyberEnergy, pName] = await getBalance(user.addr);
      flowBalance = flowTokenBalance;
      cyberEnergyBalance = cyberEnergy;
      playerName = pName;
      playerDeck = await getPlayerDeck(user.addr);
      mariganCards = await getMariganCards(user.addr);
      mariganCards = `[` + mariganCards.join('], [') + ']'
      setInterval(async () => {
        currentStatus = await getCurrentStatus(user.addr);
        if (!Number.isNaN(parseInt(currentStatus))) {
          currentStatus = `最後にマッチングを行った時刻=${new Date(currentStatus * 1000).toLocaleString()}`
        } else if (currentStatus !== null) {
          console.log(currentStatus, Object.keys(currentStatus), currentStatus["turn"])
          const keys = Object.keys(currentStatus);
          const tmp = currentStatus;
          if (keys.length) {
          currentStatus = '';
            for (let key of keys) {
              currentStatus += `${key} : ${JSON.stringify(tmp[key])}; `;
            }
          }
        }
      }, 1000)
    }
  }
});

</script>
{#if !walletUser?.addr}
  <button onclick={authenticate}>ログイン</button>
{/if}
{#if walletUser?.addr}
  <b>{playerName}さん</b> FLOW残高: {flowBalance} / ゲーム内通貨: {cyberEnergyBalance}<br>
  <button onclick={unauthenticate}>ログアウト</button>
  {#if !hasResource}
    Playerリソースが作成されていません。
   <button onclick={() => createPlayer('新規ユーザーB')}>新規登録</button>
  {/if}
  {#if hasResource}
    Playerリソース作成済みです。
    <br>
    <button onclick={buyCyberEn}>CyberEnergy購入</button>
    <hr>
    <div>
      現在のデッキ: { playerDeck }
    </div>
    <div>
      現在のゲーム進捗状況: { currentStatus ?? 'なし' }
    </div>
    <hr>
    <div>
      マリガンカード: { mariganCards }
    </div>
  {/if}
{/if}
