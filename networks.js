const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  networks: {
    development: {
      protocol: 'http',
      host: 'localhost',
      port: 8545,
      gas: 5000000,
      gasPrice: 5e9,
      networkId: '*',
    },
    rinkeby: {
      provider: () => new HDWalletProvider(
        "0x3C94ED71BA24F492A9DF68190BD58E2F9DA9FAFD69201EFCF59B0353731A6AE6", `https://rinkeby.infura.io/v3/e3c9ab0b78e946b486fa9c7b5f26c3c1`
      ),
      networkId: "*",
      gasPrice: 5e9
    }
  },
};