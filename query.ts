import Web3 from "web3";
import dotenv from "dotenv";
import fs from "fs";
dotenv.config();

const rpcURL = String(process.env.RPC_URL);
const account = String(process.env.MY_ACCOUNT);
const web3 = new Web3(rpcURL);
const outputPath = __dirname + "\\output\\my-transactions.txt";

async function queryMyTransactions(account: string, startFromBlock: number) {
  let limitBlock = await web3.eth.getBlockNumber();
  fs.writeFileSync(outputPath, "");

  let found = 0;
  let allTxn = await web3.eth.getTransactionCount(account);

  for (let i = startFromBlock; i <= limitBlock; i++) {
    if (found == allTxn) break;
    // console.log(i);
    let block = await web3.eth.getBlock(i);
    if (block !== null && block.transactions != null) {
      block.transactions.forEach(async (txnHash) => {
        let txn = await web3.eth.getTransaction(txnHash);
        if (txn.to === account || txn.from === account) {
          found++;
          fs.appendFileSync(
            outputPath,
            "tx hash          : " +
            txn.hash +
            "\n" +
            " blockNumber     : " +
            txn.blockNumber +
            "\n" +
            " from            : " +
            txn.from +
            "\n" +
            " to              : " +
            txn.to +
            "\n" +
            " value           : " +
            txn.value +
            "\n" +
            " time            : " +
            block.timestamp +
            " " +
            new Date(Number(block.timestamp) * 1000).toUTCString() +
            "\n" +
            " gasPrice        : " +
            txn.gasPrice +
            "\n" +
            " gas             : " +
            txn.gas +
            "\n" +
            " input           : " +
            txn.input +
            "\n\n"
          );
        }
      });
    }
  }
}

queryMyTransactions(account, 103616);
