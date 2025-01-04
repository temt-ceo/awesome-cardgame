import "FlowToken"
import "FungibleToken"

access(all) contract AwesomeCardGame {

  access(self) let playerList: {UInt: CyberScoreStruct}
  access(self) var totalPlayers: UInt
  access(self) let playerDeck: {UInt: [UInt16]}
  access(self) let battleInfo: {UInt: BattleStruct}
  access(self) let playerMatchingInfo: {UInt: PlayerMatchingStruct}
  access(all) let starterDeck: [UInt16]
  access(self) let FlowTokenVault: Capability<&{FungibleToken.Receiver}>
  access(self) let PlayerFlowTokenVault: {UInt: Capability<&{FungibleToken.Receiver}>}
  access(self) var matchingLimits: [UFix64]
  access(self) var matchingPlayers: [UInt]
  access(self) let rankingPeriod: UInt
  access(self) var rankingBattleCount: UInt
  access(self) var ranking1stWinningPlayerId: UInt
  access(self) var ranking2ndWinningPlayerId: UInt

  // [Struct] PlayerMatchingStruct
  access(all) struct PlayerMatchingStruct {
    access(all) var lastTimeMatching: UFix64?
    access(all) var marigan_cards: [[UInt8]]

    access(contract) fun set_lastTimeMatching(new_value: UFix64) {
      self.lastTimeMatching = new_value
    }
    access(contract) fun set_marigan_cards(new_value: [[UInt8]]) {
      self.marigan_cards = new_value
    }

    init() {
      self.lastTimeMatching = nil
      self.marigan_cards = []
    }
  }

  // [Struct] BattleStruct
  access(all) struct BattleStruct {
    access(all) var turn: UInt8 // 現在のターン
    access(all) var is_first_turn: Bool // 先行/後攻
    access(all) let is_first: Bool // 自分は先攻か後攻か
    access(all) let opponent: UInt // 対戦相手のplayer_id
    access(all) let matched_time: UFix64 // マッチングした日時
    access(all) var game_started: Bool // ゲームは開始しているか
    access(all) var last_time_turnend: UFix64? // 前の攻撃が終わった時間
    access(all) var opponent_life: UInt8
    access(all) var opponent_cp: UInt8
    access(all) var opponent_field_unit: {UInt8: UInt16}
    access(all) var opponent_field_unit_action: {UInt8: UInt8}
    access(all) var opponent_field_unit_bp_amount_of_change: {UInt8: Int}
    access(all) var opponent_trigger_cards: Int
    access(all) var opponent_remain_deck: Int
    access(all) var opponent_hand: Int
    access(all) var opponent_dead_count: Int
    access(all) var your_life: UInt8
    access(all) var your_cp: UInt8
    access(all) var your_field_unit: {UInt8: UInt16}
    access(all) var your_field_unit_action: {UInt8: UInt8}
    access(all) var your_field_unit_bp_amount_of_change: {UInt8: Int}
    access(all) var your_trigger_cards: {UInt8: UInt16}
    access(all) var your_remain_deck: [UInt16]
    access(all) var your_hand: {UInt8: UInt16}
    access(all) var your_dead_count: Int

    access(contract) fun set_game_started(new_value: Bool) {
      self.game_started = new_value
    }
    access(contract) fun set_your_remain_deck(new_value: [UInt16]) {
      self.your_remain_deck = new_value
    }
    access(contract) fun set_last_time_turnend(new_value: UFix64) {
      self.last_time_turnend = new_value
    }
    access(contract) fun set_turn(new_value: UInt8) {
      self.turn = new_value
    }
    access(contract) fun set_is_first_turn(new_value: Bool) {
      self.is_first_turn = new_value
    }

    init(is_first: Bool, opponent: UInt, matched_time: UFix64) {
      self.turn = 1
      self.is_first_turn = true
      self.is_first = is_first
      self.opponent = opponent
      self.matched_time = matched_time
      self.game_started = false
      self.last_time_turnend = nil
      self.opponent_life = 7
      self.opponent_cp = 2
      self.opponent_field_unit = {}
      self.opponent_field_unit_action = {}
      self.opponent_field_unit_bp_amount_of_change = {}
      self.opponent_trigger_cards = 0
      self.opponent_remain_deck = 30
      self.opponent_hand = 0
      self.opponent_dead_count = 0
      self.your_life = 7
      self.your_cp = 2
      self.your_field_unit = {}
      self.your_field_unit_action = {}
      self.your_field_unit_bp_amount_of_change = {}
      self.your_trigger_cards = {}
      self.your_remain_deck = []
      self.your_hand = {}
      self.your_dead_count = 0
    }
  }

  access(all) resource Player {
    access(all) let player_id: UInt
    access(all) let nickname: String

    init(nickname: String) {
      AwesomeCardGame.totalPlayers = AwesomeCardGame.totalPlayers + 1
      self.player_id = AwesomeCardGame.totalPlayers
      self.nickname = nickname

      AwesomeCardGame.playerList[self.player_id] = CyberScoreStruct(player_name: nickname)
    }

    access(all) fun get_player_score(): CyberScoreStruct {
      return AwesomeCardGame.playerList[self.player_id]!
    }

    access(all) fun buy_en(payment: @FlowToken.Vault) {
      pre {
        payment.balance == 2.0: "payment is not 2FLOW coin."
        AwesomeCardGame.playerList[self.player_id] != nil: "CyberScoreStruct not found."
      }
      AwesomeCardGame.FlowTokenVault.borrow()!.deposit(from: <- payment)
      if let cyberScore = AwesomeCardGame.playerList[self.player_id] {
        cyberScore.set_cyber_energy(new_value: cyberScore.cyber_energy + 100)
        AwesomeCardGame.playerList[self.player_id] = cyberScore
      }
    }

    access(all) fun get_player_deck(): [UInt16] {
      if let deck = AwesomeCardGame.playerDeck[self.player_id] {
        return deck
      } else {
        return AwesomeCardGame.starterDeck;
      }
    }

    access(all) fun get_current_status(): AnyStruct {
      if let info = AwesomeCardGame.battleInfo[self.player_id] {
        return info
      }
      if let obj = AwesomeCardGame.playerMatchingInfo[self.player_id] {
        return obj.lastTimeMatching
      }
      return nil
    }

    access(all) fun get_marigan_cards(): [[UInt16]] {
      if let playerMatchingInfo = AwesomeCardGame.playerMatchingInfo[self.player_id] {
        log(playerMatchingInfo)
        log(9999999)
        var ret_arr: [[UInt16]] = []
        for i in [0, 1, 2, 3, 4] {
          if let deck = AwesomeCardGame.playerDeck[self.player_id] {
            var tmp = deck.slice(from: 0, upTo: deck.length)
            ret_arr.append([tmp[playerMatchingInfo.marigan_cards[i][0]], tmp[playerMatchingInfo.marigan_cards[i][1]], tmp[playerMatchingInfo.marigan_cards[i][2]], tmp[playerMatchingInfo.marigan_cards[i][3]]])
          } else {
            var tmp = AwesomeCardGame.starterDeck.slice(from: 0, upTo: AwesomeCardGame.starterDeck.length)
            ret_arr.append([tmp[playerMatchingInfo.marigan_cards[i][0]], tmp[playerMatchingInfo.marigan_cards[i][1]], tmp[playerMatchingInfo.marigan_cards[i][2]], tmp[playerMatchingInfo.marigan_cards[i][3]]])
          }
        }
        return ret_arr
      }
      return []
    }
  }

  access(all) fun createPlayer(nickname: String, flow_vault_receiver: Capability<&{FungibleToken.Receiver}>): @AwesomeCardGame.Player {
    let player <- create Player(nickname: nickname)

    if (AwesomeCardGame.PlayerFlowTokenVault[player.player_id] == nil) {
      AwesomeCardGame.PlayerFlowTokenVault[player.player_id] = flow_vault_receiver
    }
    return <- player
  }

  access(all) struct CyberScoreStruct {
    access(all) let player_name: String
    access(all) var score: [{UFix64: UInt8}]
    access(all) var win_count: UInt
    access(all) var loss_count: UInt
    access(all) var ranking_win_count: UInt
    access(all) var ranking_2nd_win_count: UInt
    access(all) var period_win_count: UInt
    access(all) var period_loss_count: UInt
    access(all) var cyber_energy: UInt8
    access(all) var balance: UFix64

    access(contract) fun set_cyber_energy(new_value: UInt8) {
      self.cyber_energy = new_value
    }
    access(contract) fun set_win_count(new_value: UInt) {
      self.win_count = new_value
    }
    access(contract) fun set_loss_count(new_value: UInt) {
      self.loss_count = new_value
    }
    access(contract) fun set_period_win_count(new_value: UInt) {
      self.period_win_count = new_value
    }
    access(contract) fun set_period_loss_count(new_value: UInt) {
      self.period_loss_count = new_value
    }
    access(contract) fun set_ranking_win_count(new_value: UInt) {
      self.ranking_win_count = new_value
    }
    access(contract) fun set_ranking_2nd_win_count(new_value: UInt) {
      self.ranking_2nd_win_count = new_value
    }

    init(player_name: String) {
      self.player_name = player_name
      self.score = []
      self.win_count = 0
      self.loss_count = 0
      self.ranking_win_count = 0
      self.ranking_2nd_win_count = 0
      self.period_win_count = 0
      self.period_loss_count = 0
      self.cyber_energy = 0
      self.balance = 0.0
    }
  }

  /*
  ** [Resource] Admin (Game Server Processing)
  */
  access(all) resource Admin {
    /*
    ** Save the Player's Card Deck
    */
    access(all) fun save_deck(player_id: UInt, player_deck: [UInt16]) {
      if player_deck.length == 30 {
        AwesomeCardGame.playerDeck[player_id] = player_deck
      }
    }

    /*
    ** Player Matching Transaction
    */
    access(all) fun matching_start(player_id: UInt) {
      pre {
        // preの中の条件に合わない場合はエラーメッセージが返ります。 ここでは"Still matching."。
        AwesomeCardGame.playerMatchingInfo[player_id] == nil ||
        AwesomeCardGame.playerMatchingInfo[player_id]!.lastTimeMatching == nil ||
        AwesomeCardGame.playerMatchingInfo[player_id]!.lastTimeMatching! + 60.0 <= getCurrentBlock().timestamp : "Still matching."
      }
      var counter = 0
      var outdated = -1
      let current_time = getCurrentBlock().timestamp
      if let obj = AwesomeCardGame.playerMatchingInfo[player_id] {
        obj.set_lastTimeMatching(new_value: current_time)
        AwesomeCardGame.playerMatchingInfo[player_id] = obj // save
      } else {
        let newObj = PlayerMatchingStruct()
        newObj.set_lastTimeMatching(new_value: current_time)
        AwesomeCardGame.playerMatchingInfo[player_id] = newObj
      }

      // Search where matching times are already past 60 seconds
      for time in AwesomeCardGame.matchingLimits {
        if outdated == -1 && current_time > time + 60.0 {
          outdated = counter
        }
        counter = counter + 1
      }

      // If there are some expired matching times
      if outdated > -1 {
        // Save only valid matchin times
        if (outdated == 0) {
          AwesomeCardGame.matchingLimits = []
          AwesomeCardGame.matchingPlayers = []
        } else {
          AwesomeCardGame.matchingLimits = AwesomeCardGame.matchingLimits.slice(from: 0, upTo: outdated)
          AwesomeCardGame.matchingPlayers = AwesomeCardGame.matchingPlayers.slice(from: 0, upTo: outdated)
        }
      }

      /* 既にマッチングリストに入っている場合。このまま進むと自分とマッチングしかねない */
      if (AwesomeCardGame.matchingPlayers.firstIndex(of: player_id) != nil) {
        return
      }

      if (AwesomeCardGame.matchingLimits.length >= 1) {
        // Pick the opponent from still matching players.
        let time = AwesomeCardGame.matchingLimits.removeLast()
        let opponent = AwesomeCardGame.matchingPlayers.removeLast()

        var is_first = false
        // Decides which is first
        if (AwesomeCardGame.matchingLimits.length % 2 == 1) {
          is_first = true
        }

        AwesomeCardGame.playerMatchingInfo[player_id] = PlayerMatchingStruct() // マッチング成立したのでnilで初期化
        AwesomeCardGame.battleInfo[player_id] = BattleStruct(is_first: is_first, opponent: opponent, matched_time: current_time)
        AwesomeCardGame.battleInfo[opponent] = BattleStruct(is_first: !is_first, opponent: player_id, matched_time: current_time)

        // charge the play fee (料金徴収)
        if let cyberScore = AwesomeCardGame.playerList[player_id] {
          cyberScore.set_cyber_energy(new_value: cyberScore.cyber_energy - 30)
          AwesomeCardGame.playerList[player_id] = cyberScore
        }

        // charge the play fee (料金徴収)
        if let cyberScore = AwesomeCardGame.playerList[opponent] {
          cyberScore.set_cyber_energy(new_value: cyberScore.cyber_energy - 30)
          AwesomeCardGame.playerList[opponent] = cyberScore
        }
      } else {
        // Put player_id in the matching list.
        AwesomeCardGame.matchingLimits.append(current_time)
        AwesomeCardGame.matchingPlayers.append(player_id)
      }

      // Creates Pseudorandom Numbe for the marigan cards(擬似乱数生成関数、revertibleRandomを使います。)
      let modulo: UInt8 = 30
      var marigan_cards1: [UInt8] = []
      var marigan_cards2: [UInt8] = []
      var marigan_cards3: [UInt8] = []
      var marigan_cards4: [UInt8] = []
      var marigan_cards5: [UInt8] = []
      for i in [0, 1, 2, 3, 4] {
        var used1: UInt8 = 99
        var used2: UInt8 = 99
        var used3: UInt8 = 99
        var used4: UInt8 = 99
        let tmp: [UInt8] = []
        while (used4 == 99) {
          let withdrawPosition = revertibleRandom(modulo: modulo)
          if (used1 == 99) {
            used1 = withdrawPosition
            tmp.append(withdrawPosition)
          } else if (used1 != withdrawPosition && used2 == 99) {
            used2 = withdrawPosition
            tmp.append(withdrawPosition)
          } else if (used1 != withdrawPosition && used2 != withdrawPosition && used3 == 99) {
            used3 = withdrawPosition
            tmp.append(withdrawPosition)
          } else if (used1 != withdrawPosition && used2 != withdrawPosition && used3 != withdrawPosition) {
            used4 = withdrawPosition
            tmp.append(withdrawPosition)
          }
        }
        if (i == 0) {
          marigan_cards1 = tmp.slice(from: 0, upTo: tmp.length)
        } else if (i == 1) {
          marigan_cards2 = tmp.slice(from: 0, upTo: tmp.length)
        } else if (i == 2) {
          marigan_cards3 = tmp.slice(from: 0, upTo: tmp.length)
        } else if (i == 3) {
          marigan_cards4 = tmp.slice(from: 0, upTo: tmp.length)
        } else if (i == 4) {
          marigan_cards5 = tmp.slice(from: 0, upTo: tmp.length)
        }
      }
      if let playerMatchingInfo = AwesomeCardGame.playerMatchingInfo[player_id] {
        playerMatchingInfo.set_marigan_cards(new_value: [marigan_cards1, marigan_cards2, marigan_cards3, marigan_cards4, marigan_cards5])
        AwesomeCardGame.playerMatchingInfo[player_id] = playerMatchingInfo // save
      }
    }
    /* 
    ** Game Start Transaction
    */
    access(all) fun game_start(player_id: UInt, drawed_cards: [UInt16]) {
      pre {
        drawed_cards.length == 4 : "Invalid argument."
        AwesomeCardGame.battleInfo[player_id] != nil && AwesomeCardGame.battleInfo[player_id]!.game_started == false : "Game already started."
      }
      var drawed_pos: [UInt8] = []
      if let playerMatchingInfo = AwesomeCardGame.playerMatchingInfo[player_id] {
        for arr in playerMatchingInfo.marigan_cards {
          if let deck = AwesomeCardGame.playerDeck[player_id] {
            var arrCopy = deck.slice(from: 0, upTo: deck.length)
            let card_id1 = arrCopy[arr[0]]
            let card_id2 = arrCopy[arr[1]]
            let card_id3 = arrCopy[arr[2]]
            let card_id4 = arrCopy[arr[3]]
            if (card_id1 == drawed_cards[0] && card_id2 == drawed_cards[1] && card_id3 == drawed_cards[2] && card_id4 == drawed_cards[3]) {
              drawed_pos = arr
            }
          } else {
            var arrCopy = AwesomeCardGame.starterDeck.slice(from: 0, upTo: AwesomeCardGame.starterDeck.length)
            let card_id1 = arrCopy[arr[0]]
            let card_id2 = arrCopy[arr[1]]
            let card_id3 = arrCopy[arr[2]]
            let card_id4 = arrCopy[arr[3]]
            if (card_id1 == drawed_cards[0] && card_id2 == drawed_cards[1] && card_id3 == drawed_cards[2] && card_id4 == drawed_cards[3]) {
              drawed_pos = arr
            }
          }
        }
        if (drawed_pos.length == 0) {
          // Maybe the player did marigan more than 5 times. Set first cards to avoid errors.
          drawed_pos = playerMatchingInfo.marigan_cards[0]
        }
      }


      if let info = AwesomeCardGame.battleInfo[player_id] {
        info.set_game_started(new_value: true)
        if let deck = AwesomeCardGame.playerDeck[player_id] {
          info.set_your_remain_deck(new_value: deck)
        } else {
          info.set_your_remain_deck(new_value: AwesomeCardGame.starterDeck)
        }
        info.set_last_time_turnend(new_value: getCurrentBlock().timestamp)
        // Set hand
        var key: UInt8 = 1
        for pos in drawed_pos {
          let card_id = info.your_remain_deck.remove(at: pos)
          info.your_hand[key] = card_id
          key = key + 1
        }
        /** 今回はバトルはしない予定なので、以下部分は省略 
        if (info.is_first == true) {
          info.your_cp = 2
        } else {
          info.your_cp = 3
        }
        **/
        // Save
        AwesomeCardGame.battleInfo[player_id] = info

        let opponent = info.opponent
        if let opponentInfo = AwesomeCardGame.battleInfo[opponent] {
          opponentInfo.set_last_time_turnend(new_value: info.last_time_turnend!) // set time same time
          /** 今回はバトルはしない予定なので、以下部分は省略 
          // opponentInfo.game_started = true
          opponentInfo.opponent_remain_deck = info.your_remain_deck.length
          opponentInfo.opponent_hand = info.your_hand.keys.length
          opponentInfo.opponent_cp = info.your_cp
          **/
          // Save
          AwesomeCardGame.battleInfo[opponent] = opponentInfo
        }
      }
    }
    access(all) fun turn_change(player_id: UInt, from_opponent: Bool, trigger_cards: {UInt8: UInt16}) {
      if let info = AwesomeCardGame.battleInfo[player_id] {

        // Check is turn already changed.
        if info.is_first != info.is_first_turn {
          return;
        }

        // 決着がついていない攻撃がまだある
        /** 今回はバトルはしないので、以下部分は割愛
        if (info.your_attacking_card != nil && info.your_attacking_card!.attacked_time + 20.0 > info.last_time_turnend!) {
                :
        **/

        // トリガーゾーンのカードを合わせる
        for position in trigger_cards.keys {
          // セット済みは除外
          if info.your_trigger_cards[position] != trigger_cards[position] {
            // ハンドの整合性を合わせる(トリガーゾーンに移動した分、ハンドから取る)
            var isRemoved = false
            if info.your_trigger_cards[position] != trigger_cards[position] && trigger_cards[position] != 0 {
              let card_id = trigger_cards[position]
              info.your_trigger_cards[position] = card_id
              for hand_position in info.your_hand.keys {
                  if card_id == info.your_hand[hand_position] && isRemoved == false {
                    info.your_hand[hand_position] = nil
                    isRemoved = true
                  }
              }
              if (isRemoved == false) {
                panic("You set the card on trigger zone which is not exist in your hand")
              }
            }
          }
        }

        var handCnt = 0
        let handPositions: [UInt8] = [1, 2, 3, 4, 5 ,6, 7]
        for hand_position in handPositions {
          if info.your_hand[hand_position] != nil {
            handCnt = handCnt + 1
          }
        }

        // Set Field Unit Actions To Defence Only
        /** 今回はバトルはしないので、以下部分は割愛
        for position in info.your_field_unit.keys {
                :
        **/

        // Process Turn Change
        info.set_last_time_turnend(new_value: getCurrentBlock().timestamp)
        info.set_is_first_turn(new_value: !info.is_first_turn)
        if (info.is_first_turn) {
          info.set_turn(new_value: info.turn + 1)
        }

        let opponent = info.opponent
        if let infoOpponent = AwesomeCardGame.battleInfo[opponent] {

          // Turn Change
          infoOpponent.set_last_time_turnend(new_value: info.last_time_turnend!)
          infoOpponent.set_is_first_turn(new_value: !infoOpponent.is_first_turn)
          infoOpponent.set_turn(new_value: info.turn)
          /** 今回はバトルはしないので、以下部分は割愛
          infoOpponent.opponent_hand = handCnt
                  :
          **/

          // draw card
          let cardRemainCounts = infoOpponent.your_remain_deck.length

          let modulo: UInt8 = infoOpponent.your_remain_deck.length > 25 ? 25 : (infoOpponent.your_remain_deck.length > 20 ? 20 : (infoOpponent.your_remain_deck.length > 15 ? 15 : (infoOpponent.your_remain_deck.length > 10 ? 10 : (infoOpponent.your_remain_deck.length > 5 ? 5 : 1))))
          let withdrawPosition1 = revertibleRandom(modulo: modulo - 1)
          let withdrawPosition2 = revertibleRandom(modulo: modulo - 2)

          var isSetCard1 = false
          var isSetCard2 = false
          var handCnt2 = 0
          let handPositions: [UInt8] = [1, 2, 3, 4, 5 ,6, 7]
          let nextPositions: [UInt8] = [1, 2, 3, 4, 5 ,6]
          // カード位置を若い順に整列
          for hand_position in handPositions {
            var replaced: Bool = false
            if infoOpponent.your_hand[hand_position] == nil {
              for next in nextPositions {
                if replaced == false && hand_position + next <= 7 && infoOpponent.your_hand[hand_position + next] != nil {
                  infoOpponent.your_hand[hand_position] = infoOpponent.your_hand[hand_position + next]
                  infoOpponent.your_hand[hand_position + next] = nil
                  replaced = true
                }
              }
            }
          }
          for hand_position in handPositions {
            if infoOpponent.your_hand[hand_position] == nil && isSetCard1 == false {
              infoOpponent.your_hand[hand_position] = infoOpponent.your_remain_deck.remove(at: withdrawPosition1)
              isSetCard1 = true
            }
            if infoOpponent.your_hand[hand_position] == nil && isSetCard2 == false {
              infoOpponent.your_hand[hand_position] = infoOpponent.your_remain_deck.remove(at: withdrawPosition2)
              isSetCard2 = true
            }

            if infoOpponent.your_hand[hand_position] != nil {
              handCnt2 = handCnt2 + 1
            }
          }
          /** 今回はバトルはしないので、以下部分は割愛
          infoOpponent.your_field_unit_bp_amount_of_change = {} // Damage are reset
                  :
          **/

          AwesomeCardGame.battleInfo[opponent] = infoOpponent
        }
        // save
        AwesomeCardGame.battleInfo[player_id] = info
      }
      log("===========↓↓↓↓↓↓↓===========")
      log(AwesomeCardGame.rankingBattleCount)
      log(AwesomeCardGame.rankingPeriod)
      log(AwesomeCardGame.playerList)
      log("======================")
      // judge the winner
      self.judgeTheWinner(player_id: player_id)
    }

    access(all) fun judgeTheWinner(player_id: UInt) :Bool {
      pre {
        AwesomeCardGame.battleInfo[player_id] != nil : "This guy doesn't do match."
      }

      if let info = AwesomeCardGame.battleInfo[player_id] {
        if (info.turn > 10) {
          if (info.your_life > info.opponent_life || (info.your_life == info.opponent_life && info.is_first == false)) { /* Second Attack wins if lives are same. */
            let opponent = info.opponent
            AwesomeCardGame.battleInfo.remove(key: player_id)
            AwesomeCardGame.battleInfo.remove(key: opponent)
            if let cyberScore = AwesomeCardGame.playerList[player_id] {
              cyberScore.score.append({getCurrentBlock().timestamp: 1})
              cyberScore.set_win_count(new_value: cyberScore.win_count + 1)
              cyberScore.set_period_win_count(new_value: cyberScore.period_win_count + 1)
              AwesomeCardGame.playerList[player_id] = cyberScore
            }
            if let cyberScore = AwesomeCardGame.playerList[opponent] {
              cyberScore.score.append({getCurrentBlock().timestamp: 0})
              cyberScore.set_loss_count(new_value: cyberScore.loss_count + 1)
              cyberScore.set_period_loss_count(new_value: cyberScore.period_loss_count + 1)
              AwesomeCardGame.playerList[opponent] = cyberScore
            }
            AwesomeCardGame.playerMatchingInfo[player_id] = PlayerMatchingStruct() /* ゲームが終了したのでnilで初期化 */
            AwesomeCardGame.playerMatchingInfo[opponent] = PlayerMatchingStruct() /* ゲームが終了したのでnilで初期化 */
            /* Game Reward */
            let reward <- AwesomeCardGame.account.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Provider}>(from: /storage/flowTokenVault)!.withdraw(amount: 0.5) as! @FlowToken.Vault
            AwesomeCardGame.PlayerFlowTokenVault[player_id]!.borrow()!.deposit(from: <- reward)
            self.rankingTotalling(playerid: player_id);
            return true
          } else {
            let opponent = info.opponent
            AwesomeCardGame.battleInfo.remove(key: player_id)
            AwesomeCardGame.battleInfo.remove(key: opponent)
            if let cyberScore = AwesomeCardGame.playerList[player_id] {
              cyberScore.score.append({getCurrentBlock().timestamp: 0})
              cyberScore.set_loss_count(new_value: cyberScore.loss_count + 1)
              cyberScore.set_period_loss_count(new_value: cyberScore.period_loss_count + 1)
              AwesomeCardGame.playerList[player_id] = cyberScore
            }
            if let cyberScore = AwesomeCardGame.playerList[opponent] {
              cyberScore.score.append({getCurrentBlock().timestamp: 1})
              cyberScore.set_win_count(new_value: cyberScore.win_count + 1)
              cyberScore.set_period_win_count(new_value: cyberScore.period_win_count + 1)
              AwesomeCardGame.playerList[opponent] = cyberScore
            }
            AwesomeCardGame.playerMatchingInfo[player_id] = PlayerMatchingStruct() /* ゲームが終了したのでnilで初期化 */
            AwesomeCardGame.playerMatchingInfo[opponent] = PlayerMatchingStruct() /* ゲームが終了したのでnilで初期化 */
            /* Game Reward */
            let reward <- AwesomeCardGame.account.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Provider}>(from: /storage/flowTokenVault)!.withdraw(amount: 0.5) as! @FlowToken.Vault
            AwesomeCardGame.PlayerFlowTokenVault[opponent]!.borrow()!.deposit(from: <- reward)
            self.rankingTotalling(playerid: opponent);
            return true
          }
        } else if (info.turn == 10 && info.is_first_turn == false) { /* 10 turn and second attack */
          if (info.your_life <= info.opponent_life && info.is_first == true) { /* Lose if palyer is First Attack & life is less than opponent */
            let opponent = info.opponent
            AwesomeCardGame.battleInfo.remove(key: player_id)
            AwesomeCardGame.battleInfo.remove(key: opponent)
            if let cyberScore = AwesomeCardGame.playerList[player_id] {
              cyberScore.score.append({getCurrentBlock().timestamp: 0})
              cyberScore.set_loss_count(new_value: cyberScore.loss_count + 1)
              cyberScore.set_period_loss_count(new_value: cyberScore.period_loss_count + 1)
              AwesomeCardGame.playerList[player_id] = cyberScore
            }
            if let cyberScore = AwesomeCardGame.playerList[opponent] {
              cyberScore.score.append({getCurrentBlock().timestamp: 1})
              cyberScore.set_win_count(new_value: cyberScore.win_count + 1)
              cyberScore.set_period_win_count(new_value: cyberScore.period_win_count + 1)
              AwesomeCardGame.playerList[opponent] = cyberScore
            }
            AwesomeCardGame.playerMatchingInfo[player_id] = PlayerMatchingStruct() /* ゲームが終了したのでnilで初期化 */
            AwesomeCardGame.playerMatchingInfo[opponent] = PlayerMatchingStruct() /* ゲームが終了したのでnilで初期化 */
            /* Game Reward */
            let reward <- AwesomeCardGame.account.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Provider}>(from: /storage/flowTokenVault)!.withdraw(amount: 0.5) as! @FlowToken.Vault
            AwesomeCardGame.PlayerFlowTokenVault[opponent]!.borrow()!.deposit(from: <- reward)
            self.rankingTotalling(playerid: opponent);
            return true
          } else if (info.your_life >= info.opponent_life && info.is_first == false) {// Win if palyer is Second Attack & life is more than opponent
            let opponent = info.opponent
            AwesomeCardGame.battleInfo.remove(key: player_id)
            AwesomeCardGame.battleInfo.remove(key: opponent)
            if let cyberScore = AwesomeCardGame.playerList[player_id] {
              cyberScore.score.append({getCurrentBlock().timestamp: 1})
              cyberScore.set_win_count(new_value: cyberScore.win_count + 1)
              cyberScore.set_period_win_count(new_value: cyberScore.period_win_count + 1)
              AwesomeCardGame.playerList[player_id] = cyberScore
            }
            if let cyberScore = AwesomeCardGame.playerList[opponent] {
              cyberScore.score.append({getCurrentBlock().timestamp: 0})
              cyberScore.set_loss_count(new_value: cyberScore.loss_count + 1)
              cyberScore.set_period_loss_count(new_value: cyberScore.period_loss_count + 1)
              AwesomeCardGame.playerList[opponent] = cyberScore
            }
            AwesomeCardGame.playerMatchingInfo[player_id] = PlayerMatchingStruct() /* ゲームが終了したのでnilで初期化 */
            AwesomeCardGame.playerMatchingInfo[opponent] = PlayerMatchingStruct() /* ゲームが終了したのでnilで初期化 */
            /* Game Reward */
            let reward <- AwesomeCardGame.account.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Provider}>(from: /storage/flowTokenVault)!.withdraw(amount: 0.5) as! @FlowToken.Vault
            AwesomeCardGame.PlayerFlowTokenVault[player_id]!.borrow()!.deposit(from: <- reward)
            self.rankingTotalling(playerid: player_id);
            return true
          }
        }
        if (info.opponent_life == 0) {
          let opponent = info.opponent
          AwesomeCardGame.battleInfo.remove(key: player_id)
          AwesomeCardGame.battleInfo.remove(key: opponent)
          if let cyberScore = AwesomeCardGame.playerList[player_id] {
            cyberScore.score.append({getCurrentBlock().timestamp: 1})
            cyberScore.set_win_count(new_value: cyberScore.win_count + 1)
            cyberScore.set_period_win_count(new_value: cyberScore.period_win_count + 1)
            AwesomeCardGame.playerList[player_id] = cyberScore
          }
          if let cyberScore = AwesomeCardGame.playerList[opponent] {
            cyberScore.score.append({getCurrentBlock().timestamp: 0})
            cyberScore.set_loss_count(new_value: cyberScore.loss_count + 1)
            cyberScore.set_period_loss_count(new_value: cyberScore.period_loss_count + 1)
            AwesomeCardGame.playerList[opponent] = cyberScore
          }
          AwesomeCardGame.playerMatchingInfo[player_id] = PlayerMatchingStruct() /* ゲームが終了したのでnilで初期化 */
          AwesomeCardGame.playerMatchingInfo[opponent] = PlayerMatchingStruct() /* ゲームが終了したのでnilで初期化 */
          /* Game Reward */
          let reward <- AwesomeCardGame.account.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Provider}>(from: /storage/flowTokenVault)!.withdraw(amount: 0.5) as! @FlowToken.Vault
          AwesomeCardGame.PlayerFlowTokenVault[player_id]!.borrow()!.deposit(from: <- reward)
          self.rankingTotalling(playerid: player_id);
          return true
        } else if (info.your_life == 0) {
          let opponent = info.opponent
          AwesomeCardGame.battleInfo.remove(key: player_id)
          AwesomeCardGame.battleInfo.remove(key: opponent)
          if let cyberScore = AwesomeCardGame.playerList[player_id] {
            cyberScore.score.append({getCurrentBlock().timestamp: 0})
            cyberScore.set_loss_count(new_value: cyberScore.loss_count + 1)
            cyberScore.set_period_loss_count(new_value: cyberScore.period_loss_count + 1)
            AwesomeCardGame.playerList[player_id] = cyberScore
          }
          if let cyberScore = AwesomeCardGame.playerList[opponent] {
            cyberScore.score.append({getCurrentBlock().timestamp: 1})
            cyberScore.set_win_count(new_value: cyberScore.win_count + 1)
            cyberScore.set_period_win_count(new_value: cyberScore.period_win_count + 1)
            AwesomeCardGame.playerList[opponent] = cyberScore
          }
          AwesomeCardGame.playerMatchingInfo[player_id] = PlayerMatchingStruct() /* ゲームが終了したのでnilで初期化 */
          AwesomeCardGame.playerMatchingInfo[opponent] = PlayerMatchingStruct() /* ゲームが終了したのでnilで初期化 */
          /* Game Reward */
          let reward <- AwesomeCardGame.account.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Provider}>(from: /storage/flowTokenVault)!.withdraw(amount: 0.5) as! @FlowToken.Vault
          AwesomeCardGame.PlayerFlowTokenVault[opponent]!.borrow()!.deposit(from: <- reward)
          self.rankingTotalling(playerid: opponent);
          return true
        }
      }
      return false
    }

    /* Totalling Ranking values. */
    access(all) fun rankingTotalling(playerid: UInt) {
      AwesomeCardGame.rankingBattleCount = AwesomeCardGame.rankingBattleCount + 1;
      if let cyberScore = AwesomeCardGame.playerList[playerid] {
        /* When this game just started */
        if (AwesomeCardGame.ranking2ndWinningPlayerId == 0 || AwesomeCardGame.ranking1stWinningPlayerId == 0) {
          if (AwesomeCardGame.ranking1stWinningPlayerId == 0) {
            AwesomeCardGame.ranking1stWinningPlayerId = playerid;
          } else if(AwesomeCardGame.ranking2ndWinningPlayerId == 0) {
            AwesomeCardGame.ranking2ndWinningPlayerId = playerid;
          }
        } else {
          for player_id in AwesomeCardGame.playerList.keys {
            if let score = AwesomeCardGame.playerList[player_id] {
              if (score.win_count + score.loss_count > 0) {
                if (player_id != AwesomeCardGame.ranking2ndWinningPlayerId && player_id != AwesomeCardGame.ranking1stWinningPlayerId) {
                  if let rank2ndScore = AwesomeCardGame.playerList[AwesomeCardGame.ranking2ndWinningPlayerId] { /* If it's equal, first come first served. */
                    if (AwesomeCardGame.calcPoint(win_count: rank2ndScore.period_win_count, loss_count: rank2ndScore.period_loss_count) < AwesomeCardGame.calcPoint(win_count: cyberScore.period_win_count, loss_count: cyberScore.period_loss_count)) {
                      if let rank1stScore = AwesomeCardGame.playerList[AwesomeCardGame.ranking1stWinningPlayerId] {
                        if (AwesomeCardGame.calcPoint(win_count: rank1stScore.period_win_count, loss_count: rank1stScore.period_loss_count) < AwesomeCardGame.calcPoint(win_count: cyberScore.period_win_count, loss_count: cyberScore.period_loss_count)) {
                          AwesomeCardGame.ranking2ndWinningPlayerId = AwesomeCardGame.ranking1stWinningPlayerId;
                          AwesomeCardGame.ranking1stWinningPlayerId = player_id;
                        } else {
                          AwesomeCardGame.ranking2ndWinningPlayerId = player_id;
                        }
                      }
                    }
                  }
                } else if (player_id != AwesomeCardGame.ranking1stWinningPlayerId) {
                  if let rank1stScore = AwesomeCardGame.playerList[AwesomeCardGame.ranking1stWinningPlayerId] {
                    if (AwesomeCardGame.calcPoint(win_count: rank1stScore.period_win_count, loss_count: rank1stScore.period_loss_count) < AwesomeCardGame.calcPoint(win_count: cyberScore.period_win_count, loss_count: cyberScore.period_loss_count)) { /* If it's equal, first come first served. */
                      AwesomeCardGame.ranking2ndWinningPlayerId = AwesomeCardGame.ranking1stWinningPlayerId;
                      AwesomeCardGame.ranking1stWinningPlayerId = player_id;
                    }
                  }
                }
              }
            }
          }
        }
      }
      if (AwesomeCardGame.rankingBattleCount >= AwesomeCardGame.rankingPeriod) {
        // Initialize the ranking win count.
        for playerId in AwesomeCardGame.playerList.keys {
          if let score = AwesomeCardGame.playerList[playerId] {
            score.set_period_win_count(new_value: 0)
            score.set_period_loss_count(new_value: 0);
            AwesomeCardGame.playerList[playerId] = score; // Save
          }
        }
        // Initialize the count.
        AwesomeCardGame.rankingBattleCount = 0;
        // Pay ranking reward(20 $FLOW)
        if let rank1stScore = AwesomeCardGame.playerList[AwesomeCardGame.ranking1stWinningPlayerId] {
          rank1stScore.set_ranking_win_count(new_value: rank1stScore.ranking_win_count + 1)
          AwesomeCardGame.playerList[AwesomeCardGame.ranking1stWinningPlayerId] = rank1stScore; // Save
          let reward1st <- AwesomeCardGame.account.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Provider}>(from: /storage/flowTokenVault)!.withdraw(amount: 20.0) as! @FlowToken.Vault
          AwesomeCardGame.PlayerFlowTokenVault[AwesomeCardGame.ranking1stWinningPlayerId]!.borrow()!.deposit(from: <- reward1st)
        }
        // Pay ranking reward(10 $FLOW)
        if let rank2ndScore = AwesomeCardGame.playerList[AwesomeCardGame.ranking2ndWinningPlayerId] {
          rank2ndScore.set_ranking_2nd_win_count(new_value: rank2ndScore.ranking_2nd_win_count + 1)
          AwesomeCardGame.playerList[AwesomeCardGame.ranking2ndWinningPlayerId] = rank2ndScore; // Save
          let reward2nd <- AwesomeCardGame.account.storage.borrow<auth(FungibleToken.Withdraw) &{FungibleToken.Provider}>(from: /storage/flowTokenVault)!.withdraw(amount: 10.0) as! @FlowToken.Vault
          AwesomeCardGame.PlayerFlowTokenVault[AwesomeCardGame.ranking2ndWinningPlayerId]!.borrow()!.deposit(from: <- reward2nd)
        }
      }
    }
  }

  access(all) fun calcPoint(win_count: UInt, loss_count: UInt): UInt {
    if ((win_count + loss_count) > 25) {
      return UInt(UFix64(win_count) / UFix64(win_count + loss_count) * 50.0) + win_count;
    } else if ((win_count + loss_count) > 5) {
      return UInt(UFix64(win_count) / UFix64(win_count + loss_count) * 20.0) + win_count;
    } else {
      return UInt(UFix64(win_count) / UFix64(win_count + loss_count) * 10.0) + win_count;
    }
  }

  init() {
    self.account.storage.save( <- create Admin(), to: /storage/AwesomeCardGameAdmin) // grant admin resource
    self.FlowTokenVault = self.account.capabilities.get<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
    self.PlayerFlowTokenVault = {}
    self.starterDeck = [1, 1, 2, 2, 3, 3, 4, 4, 5, 6, 7, 8, 9, 9, 10, 11, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26]
    self.totalPlayers = 0
    self.playerList = {}
    self.playerDeck = {}
    self.battleInfo = {}
    self.playerMatchingInfo = {}
    self.matchingLimits = []
    self.matchingPlayers = []
    self.rankingPeriod = 1000
    self.rankingBattleCount = 0
    self.ranking1stWinningPlayerId = 0
    self.ranking2ndWinningPlayerId = 0
  }
}
