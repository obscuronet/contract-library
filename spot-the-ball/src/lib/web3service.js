import { ethers } from 'ethers'
import { useMessageStore } from '@/stores/messageStore'
import ImageGuessGameJson from '@/assets/contract/artifacts/contracts/ImageGuessGame.sol/ImageGuessGame.json'
import ContractAddress from '@/assets/contract/address.json'
import Common from './common'
import { trackEvent } from './utils'
import { useGameStore } from '@/stores/gameStore'

export default class Web3Service {
  constructor(signer) {
    this.contract = new ethers.Contract(ContractAddress.address, ImageGuessGameJson.abi, signer)
    this.signer = signer

    // this.preload()
  }

  // async preload() {
  //   try {
  //     console.log('Preloading ship properties...')
  //     const gameStore = useGameStore()
  //     await gameStore.getImage()
  //   } catch (error) {
  //     console.error('Failed to preload ship properties - ', error)
  //   }
  // }

  async submitGuess(guessValue) {
    const messageStore = useMessageStore()

    messageStore.addMessage('Issuing Guess...')

    try {
      const submitTx = await this.contract.guess(guessValue, { value: guessFee })
      const receipt = await submitTx.wait()
      messageStore.addMessage('Issued Guess tx: ' + receipt.transactionHash)
      if (receipt.events[0].args.success) {
        trackEvent('guess_success', { value: guessValue })
        messageStore.addMessage(
          `[ImageGuessGame Contract] ${guessValue} was the right answer ! You won!`
        )
      } else {
        messageStore.addMessage(
          `[ImageGuessGame Contract] ${guessValue} was not the right answer. Try again...`
        )
      }
    } catch (e) {
      if (e.reason) {
        messageStore.addMessage('Failed to issue Guess - ' + e.reason + ' ...')
        return
      }
      messageStore.addMessage(
        'Failed to issue Guess - unexpected error occurred, check the console logs...'
      )
      console.log(e)
    }
  }

  async createChallenge(payload) {
    const messageStore = useMessageStore()
    const entryFee = ethers.utils.parseEther(Common.ENTRY_COST)
    try {
      // Check balance
      const balance = await this.signer.getBalance()
      if (balance.lt(entryFee)) {
        messageStore.addMessage(
          `Insufficient balance. You need at least ${Common.GUESS_COST} ETH to submit a guess.`
        )
        return
      }
      const joinTx = await this.contract.createChallenge(entryFee)
      console.log('🚀 ~ Web3Service ~ createChallenge ~ joinTx:', joinTx)
      messageStore.addMessage('Joining game...')
    } catch (error) {
      console.error('Failed to join game - ', error)
      messageStore.addMessage('Failed to join game - ' + error.reason + ' ...')
    }
  }

  async getImage(shipType) {
    const messageStore = useMessageStore()
    try {
      const ship = await this.contract.ships(shipType)
      return ship
    } catch (error) {
      console.error('Failed to get ship properties - ', error)
      messageStore.addMessage('Failed to get ship properties - ' + error.reason + ' ...')
    }
  }
}
