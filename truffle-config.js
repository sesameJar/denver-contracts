require('dotenv').config();

const HDWalletProvider = require('@truffle/hdwallet-provider');
// const getMnemonic = require('./migrations/utils/getMnemonic');

function getMnemonic(network) {
    // For live deployments use a specific Ephimera key
    if (network === 'mainnet') {
        return process.env.MAINNET_PK || '';
    }
    return process.env.PROTOTYPE_PK || '';
};

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
                return new HDWalletProvider(getMnemonic('rinkeby'), `https://rinkeby.infura.io/v3/059566edea104176bafe6d5a99d92d1a`);
                // console.log(walletProvider);
                // return walletProvider;
            },
            // provider: new LedgerWalletProvider(ledgerOptions,  `https://rinkeby.infura.io/v3/${INFURA_KEY}`),
            network_id: 4,
            gas: 6000000,
            gasPrice: 25000000000, // 25 Gwei. default = 100 gwei = 100000000000
            skipDryRun: true
        },
    }
  
};
