require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');
const INFURA = `https://rinkeby.infura.io/v3/${process.env.INFURA_PROJECT_ID}`;
const MNEUMONICS = process.env.MNEUMONICS;
module.exports = {
  // Uncommenting the defaults below 
  // provides for an easier quick-start with Ganache.
  // You can also follow this format for other networks;
  // see <http://truffleframework.com/docs/advanced/configuration>
  // for more details on how to specify configuration options!
  //
  compilers: {
        solc: {
            version: '0.6.12',
            settings: {
                optimizer: {
                    enabled: true, // Default: false
                    runs: 1000      // Default: 200
                },
            }
        }
    },
    networks: {
        development: {
            host: "127.0.0.1",
            port: 8545,
            network_id: "*"
        },
        rinkeby: {
            provider: function () {
                return new HDWalletProvider(MNEUMONICS, INFURA);
            },
            // provider: new LedgerWalletProvider(ledgerOptions, INFURA),
            network_id: 4,
            gas: 6000000,
            gasPrice: 25000000000, // 25 Gwei. default = 100 gwei = 100000000000
            skipDryRun: true
        },
    }
  
};
