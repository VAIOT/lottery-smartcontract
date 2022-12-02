import './App.css';
import {useState, useRef} from "react"
import { ethers } from "ethers";
import raffleAbi from "./raffleAbi.json";
import tokenAbi from "./tokenAbi.json"
import winnerPickerAbi from "./winnerPickerAbi.json"
import axios from 'axios';


function App() {

  const formRef = useRef();  

  const [error, setError] = useState();

  const [nftAbi, setNftAbi] = useState()
  const [checkedType, setCheckedType] = useState("")
  const [maticInput, setMaticInput] = useState("")
  const [erc20Input, setErc20Input] = useState("")
  const [authorWallet, setAuthorWallet] = useState("")
  const [numOfWinners, setNumOfWinners] = useState()
  const [divArray, setDivArray] = useState([])
  const [rewardsNormal, setRewardsNormal] = useState()
  const [rewardsNormalBigNumber, setRewardsNormalBigNumber] = useState()
  const [rewardsPercentage, setRewardsPercentage] = useState()
  const [lotteryTime, setLotteryTime] = useState()
  const [nftCollectionAddress, setNftCollectionAddress] = useState([])
  const [maticValue, setMaticValue] = useState()
  const [participants, setParticipants] = useState()
  const [randomNumber, setRandomNumber] = useState()
  const [winners, setWinners] = useState()

  const [wallet, setWallet] = useState("");
  const [provider, setProvider] = useState();

  const requestAccount = async () => {
    if (window.ethereum) {
      try {
        const accounts = await window.ethereum.request({
          method: "eth_requestAccounts",
        });
        setWallet(accounts[0]);
      } catch (error) {
        console.log(error);
      }
    } else {
      console.log("Metamask not detected!");
    }
  };

  const connectWallet = async () => {
    await requestAccount();
    const prov = new ethers.providers.Web3Provider(window.ethereum);
    setProvider(prov);
  };

  const setChecked = (name) => {
    if (name === "MATIC") {
      checkedType === "MATIC" ? setCheckedType("") : setCheckedType(name)
    }
    if (name === "ERC20") {
      checkedType === "ERC20" ? setCheckedType("") : setCheckedType(name)
    }
    if (name === "NFT") {
      checkedType === "NFT" ? setCheckedType("") : setCheckedType(name)
    }
  }

  const setMaticCheck = (input) => {
    if (input === "normal") {
      maticInput === "normal" ? setMaticInput("") : setMaticInput(input)
    }
    if (input === "percentage") {
      maticInput === "percentage" ? setMaticInput("") : setMaticInput(input)
    }
  }

  const setERC20 = (input) => {
    if (input === "ETH") {
      erc20Input === "ETH" ? setErc20Input("") : setErc20Input(input)
    }
    if (input === "USDT") {
      erc20Input === "USDT" ? setErc20Input("") : setErc20Input(input)
    }
    if (input === "USDC") {
      erc20Input === "USDC" ? setErc20Input("") : setErc20Input(input)
    }
  }

  const handleNumOfWinners = (input) => {
    setNumOfWinners(input)
    let arr = []
    for (let i=0; i<input; i++){
      arr.push(i);
    }
    setDivArray(arr)
    setNftCollectionAddress(Array(input))
    if (numOfWinners != undefined) {
      formRef.current.reset();

    }
  }


  const updateNftAddresses = (input, i) => {
    let myArr = [...nftCollectionAddress];
    myArr[i] = input;
    setNftCollectionAddress(myArr);
  }

  const networks = {
    polygon: {
      chainId: `0x${Number(80001).toString(16)}`,
      chainName: "Polygon Mumbai",
      nativeCurrency: {
        name: "MATIC",
        symbol: "MATIC",
        decimals: 18
      },
      rpcUrls: ["https://rpc-mumbai.maticvigil.com"],
      blockExplorerUrls: ["https://polygonscan.com/"]
    },
    goerli: {
      chainId: `0x${Number(5).toString(16)}`,
      chainName: "Ethereum Goerli",
      nativeCurrency: {
        name: "Goerli ETH",
        symbol: "GoerliETH",
        decimals: 18
      },
      rpcUrls: [
        "https://goerli.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161"
      ],
      blockExplorerUrls: ["https://goerli.etherscan.io"]
    }
  };

  const switchChain = async (networkName) => {
    try {
      await window.ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: networks[networkName].chainId }],
      });
    } catch (err) {
      if (err.code == 4902) {
        try {
          await window.ethereum.request({
            method: 'wallet_addEthereumChain',
            params: [
              {
                chainId: networks[networkName].chainId,
                chainName: networks[networkName].chainName,
                rpcUrls: networks[networkName].rpcUrls
              }
            ]
          })
        } catch (error) {
          setError(error.message)
        }
      }
    }
  }

  const handleMaticLottery = async () => {
    if (provider == undefined) {
      alert('Please connect your wallet first')
    }
    if (provider != undefined) {
      const chainId = await provider.send("eth_chainId");
      if (chainId != '0x13881') {
        alert('Connect your wallet to Mumbai testnet')
      } else {
        const signer = provider.getSigner();
        const contract = new ethers.Contract(
          "0x118d86aF537768bba4248b106179379d95E874f4",
          raffleAbi,
          signer
        )
        if (maticInput == 'normal') {
          const valueCheck = await inputCheck()
          valueCheck ? await contract.openLotterySplit(authorWallet, numOfWinners, rewardsNormalBigNumber, {value: ethers.utils.parseEther(maticValue.toString())}) : alert("Rewards dont match")
        } else if (maticInput == 'percentage') {
          await contract.openLotteryPercentage(authorWallet, numOfWinners, rewardsPercentage, {value: ethers.utils.parseEther(maticValue.toString())})
        }
      }
    }
  }

  const handleRequestRandomNumber = async () => {
    if (provider == undefined) {
      alert('Please connect your wallet first')
    } else {
      const chainId = await provider.send("eth_chainId")
      if (chainId !== "0x13881") {
        alert("Connect your wallet to Mumbai testnet")
      } else {
        const signer = provider.getSigner()
        const contract = new ethers.Contract(
          "0x118d86aF537768bba4248b106179379d95E874f4",
          raffleAbi,
          signer
        )
        let tx = await contract.pickRandomNumberForLottery(5)
        await tx.wait(6)
        let receipt = await contract.payoutWinners(5)
        await receipt.wait(3)
        const winners = await contract.getWinnersOfLottery(5)
        setWinners(winners)
      }
    }
  }


  const handleAddParticipants = async () => {
    if (provider == undefined) {
      alert('Please connect your wallet first')
    } else {
      const chainId = await provider.send("eth_chainId")
      if (chainId !== "0x13881") {
        alert("Connect your wallet to Mumbai testnet")
      } else {
        const signer = provider.getSigner()
        const contract = new ethers.Contract(
          "0x118d86aF537768bba4248b106179379d95E874f4",
          raffleAbi,
          signer
        )
        await contract.addLotteryParticipants(5, participants)
      }
    }
  }

  const handleERC20Transfer = async () => {
    if (provider == undefined) {
      alert('Please connect your wallet first')
    } else {
      const chainId = await provider.send("eth_chainId")
      if (chainId !== "0x5") {
        alert("Connect your wallet to Goerli testnet")
      } else {
        const signer = await provider.getSigner()
        const contract = new ethers.Contract(
          "0x5642B78C7167788Dbd63cf3E7A8148c62082E0d0",
          tokenAbi,
          signer
        )
        await contract.transfer("0xD2509e56a44B60D72eb4904AA24925043c0Eaf18", ethers.utils.parseEther(maticValue.toString()))
        await handleOpenLottery()
      }
    }
  }

  const inputCheck = async () => {
    if (maticInput == "normal") {
      let rewardsSum = 0;
      let rewardsSplit = rewardsNormal.split(',')
      for (let i=0; i<rewardsSplit.length; i++) {
        rewardsSum = rewardsSum + parseFloat(rewardsSplit[i])
      }
      if (rewardsSum == parseFloat(maticValue)) {
        return true
      }
    } else if (maticInput == "percentage") {
      
    }
  }

  const handleRewardsPercentage = (value) => {
    const splitted = value.split(',')
    const arr = []
    for (let i=0; i<splitted.length; i++) {
      arr.push(splitted[i])
    }
    setRewardsPercentage(arr)
  }

  const handleRewardsNormal = (value) => {
    setRewardsNormal(value)
    const splitted = value.split(',')
    const arr = []
    for (let i=0; i<splitted.length; i++) {
      let value = ethers.utils.parseEther(parseFloat(splitted[i]).toString())
      arr.push(value)
    }
    setRewardsNormalBigNumber(arr)
  }

  const handleSetParticipants = async (value) => {
    const addressArray = value.split(',')
    setParticipants(addressArray)
  }

  const handleOpenLottery = async () => {
    let provider = new ethers.getDefaultProvider(process.env.REACT_APP_MUMBAI_PROVIDER);
    let walletWithProvider = new ethers.Wallet(process.env.REACT_APP_PRIVATE_KEY, provider);
    const contract = new ethers.Contract(
      "0x813Bb43cB47Fbe50C8519B9539e1732Cb22527F6",
      winnerPickerAbi,
      walletWithProvider
    )
    await contract.openLottery(authorWallet, numOfWinners)
  }


const getNftAbi = (contractAddress) => {
  axios
  .get(`https://api-goerli.etherscan.io/api?module=contract&action=getabi&address=${contractAddress}&apikey=${process.env.REACT_APP_ETHERSCAN_API_KEY}`)
  .then(data => setNftAbi(data.data.result))
  .catch(error => console.log(error));
  };

const handleNftSubmit = async (contractAddress) => {
  getNftAbi(contractAddress)

  if (provider == undefined) {
    alert('Please connect your wallet first')
  } else {
    const chainId = await provider.send("eth_chainId")
    if (chainId !== "0x5") {
      alert("Connect your wallet to Goerli testnet")
    } else {
      const signer = provider.getSigner()
      const contract = new ethers.Contract(
        contractAddress,
        nftAbi,
        signer
      )
      await contract.transferFrom(authorWallet,"0x438BA8BD834b6053B82C269c2D30d566FFC32baE", 1)
      await handleOpenLottery()
    }
  }

}


  return (
    <div>
      <div className="connect-button-container">
      <button
            onClick={() => switchChain("polygon")}
            className=""
          >
            Switch to Mumbai
      </button>
      <button
            onClick={() => switchChain('goerli')}
            className=""
          >
            Switch to Goerli
      </button>
      {wallet == "" && (
          <button className="connect-button" onClick={() => connectWallet()}>
            Connect Wallet{" "}
          </button>
        )}
        {wallet != "" && (
          <button className="connect-button" onClick={() => connectWallet()}>
            {wallet.slice(0, 8) + "..."}
          </button>
        )}
      </div>
    <div className="main-container">
      <div className="title">
        What are you giving away?
      </div>
      <form className="title-form">
        <input type="checkbox" checked={checkedType === "MATIC"} id="matic" name="matic" onChange = {() => setChecked("MATIC")}/>
        <label for="matic">MATIC</label>
        <input type="checkbox" checked={checkedType === "ERC20"} id="ERC20" name="ERC20" onChange = {() => setChecked("ERC20")}/>
        <label for="ERC20">ERC20 Token</label>
        <input type="checkbox" checked={checkedType === "NFT"} id="NFT" name="NFT" onChange = {() => setChecked("NFT")}/>
        <label for="NFT">NFT</label>
      </form>

      {checkedType === "MATIC" &&<div><form className="container">
        <div className="rewards-type">
          <input type="checkbox" name="percentageInput" id="percentageInput" checked={maticInput === "normal"} onChange = {() => setMaticCheck("normal")}/>
          <label for="percentageInput">Exact token rewards</label>
          <input type="checkbox" name="normalInput" id="normalInput" checked={maticInput === "percentage"} onChange = {() => setMaticCheck("percentage")}/>
          <label for="percentageInput">Percentage token rewards</label>
        </div>
        <label>
          Total Reward:
          <input type="number" name="maticValue" id="maticValue" className="input" onChange={(e) => setMaticValue(e.target.value)}/>
        </label>
        <label>
        Your wallet address: 
          <input type="text" name="walletAddress" className="input" onChange={(e) => setAuthorWallet(e.target.value)}></input>
        </label>
        <label>
        Number of winners:
          <input type="number" className="input" onChange={(e) => setNumOfWinners(e.target.value)}></input>
        </label>
        {maticInput === "normal" && <label>
          Rewards for each winner:
          <input className="input" onChange={(e) => handleRewardsNormal(e.target.value)}></input>
        </label>}
        {maticInput === "percentage" && <label>
          Percentage rewards for each winner:
          <input className="input" onChange={(e) => handleRewardsPercentage(e.target.value)}></input>
        </label>}
        <label>
        How long should the lottery last? (in hours)
        <input type="number" id="time" name="time" className="input" onChange={(e) => setLotteryTime(e.target.value)}/>
        </label>
      </form>
      <button onClick={() => handleMaticLottery()}>Submit</button>
      <br></br>
      <br></br>
      <br></br>
        <input type="text" id="participants" name="participants" className="input" onChange={(e) => handleSetParticipants(e.target.value)} />
      <button className="extra-button" onClick={() => handleAddParticipants()}>Add Participants</button>
      <br></br>
      <br></br>
      <button onClick={() => handleRequestRandomNumber()}>Pick random number and finish lottery</button>
      <br></br>
      <br></br>
      <div>Winners are {winners == undefined ? <p></p> : winners.map(el => (<p>{el}</p>))}</div>
      </div>
      }
      {checkedType === "ERC20" && <div><form className="container">
        <div className="erc20-form">
          <input type="checkbox" checked={erc20Input === "ETH"} id="ETH" name="ETH" onChange = {() => setERC20("ETH")}/>
          <label for="NFT">ETH</label>
          <input type="checkbox" checked={erc20Input === "USDT"} id="USDT" name="USDT" onChange = {() => setERC20("USDT")}/>
          <label for="NFT">USDT</label>
          <input type="checkbox" checked={erc20Input === "USDC"} id="USDC" name="USDC" onChange = {() => setERC20("USDC")}/>
          <label for="NFT">USDC</label>
        </div>
        <div className="rewards-type">
          <input type="checkbox" name="percentageInput" id="percentageInput" checked={maticInput === "normal"} onChange = {() => setMaticCheck("normal")}/>
          <label for="percentageInput">Exact token rewards</label>
          <input type="checkbox" name="normalInput" id="normalInput" checked={maticInput === "percentage"} onChange = {() => setMaticCheck("percentage")}/>
          <label for="percentageInput">Percentage token rewards</label>
        </div>
        <label>
          Total Reward:
          <input type="number" name="maticValue" id="maticValue" className="input" onChange={(e) => setMaticValue(e.target.value)}/>
        </label>
        <label>
        Your wallet address: 
          <input type="text" name="walletAddress" className="input" onChange={(e) => setAuthorWallet(e.target.value)}></input>
        </label>
        <label>
        Number of winners:
          <input type="number" className="input" onChange={(e) => setNumOfWinners(e.target.value)}></input>
        </label>
        {maticInput === "normal" && <label>
          Rewards for each winner:
          <input className="input" onChange={(e) => handleRewardsNormal(e.target.value)}></input>
        </label>}
        {maticInput === "percentage" && <label>
          Percentage rewards for each winner:
          <input className="input" onChange={(e) => handleRewardsPercentage(e.target.value)}></input>
        </label>}
        <label>
        How long should the lottery last? (in hours)
        <input type="number" id="time" name="time" className="input" onChange={(e) => setLotteryTime(e.target.value)}/>

        </label>
      </form>
      <button onClick={() => handleERC20Transfer()}>Submit</button>
      </div>
      }
      {checkedType === "NFT" && <div><form className="container">
        <label>
        Your wallet address: 
          <input type="text" name="walletAddress" className="input" onChange={(e) => setAuthorWallet(e.target.value)}></input>
        </label>
        <label>
        Number of winners:
          <input type="number" className="input" onChange={(e) => handleNumOfWinners(e.target.value)}></input>
        </label>
        <label>
        How long should the lottery last? (in hours)
        <input type="number" id="time" name="time" className="input" onChange={(e) => setLotteryTime(e.target.value)}/>

        </label>
        <form ref={formRef}>
        {
        divArray.map((el, i) => (
          <div className="winner-container">
            <div>Winner number {i+1}</div>
            <div className="winner-info">
              <label for="nftCollection">NFT Collection Address</label>
              <input type="text" id="nftCollection" name="nftCollection" onChange={(e) => updateNftAddresses(e.target.value, i)}/>
              <label for="nftId">NFT ID</label>
              <input type="text" id="nftId" name="nftId" />
            </div>
          </div>
        ))}
        </form>
      </form>
      <button onClick={() => handleNftSubmit('0x48d9dE329dCb49533F1C9013cC3aABc5E82a0c28')}>Submit</button>
      </div>}
    </div>
    </div>
  );
}

export default App;
