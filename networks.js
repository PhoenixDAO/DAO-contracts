const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  networks: {
    development: {
      protocol: 'http',
      host: 'localhost',
      port: 8545,
      gas: 10000000,
      gasPrice: 5e9,
      networkId: '*',
    },
    rinkeby: {
      provider: () => new HDWalletProvider(
        // 0x609a8a9ef6fa45955886ea323a70ab0ded6b5a656214fea4680605557c1d88b8
        //0x5d4af089d553bd1211888e81a41cf421e5e8f3e7d8e685675bdfcc47d79a5ca3
        //0xc569f7f4e2ff5ce8c4c7cee9aa0afdc50d9f590bdb8a0d94686d1d0d97eaed01
        "0x5d4af089d553bd1211888e81a41cf421e5e8f3e7d8e685675bdfcc47d79a5ca3", `https://rinkeby.infura.io/v3/e3c9ab0b78e946b486fa9c7b5f26c3c1`
      ),
      networkId: "*",
      gas: 10000000,
      gasPrice: 200e9
    }
  },
};