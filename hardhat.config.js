require('@nomiclabs/hardhat-waffle');
const projectId = 'ddcd2de416ac48b583740b791754b223';

const fs = require('fs');
const keyData = fs.readFileSync('./p-key.txt', {
	encoding: 'utf8',
	flag: 'r',
});

module.exports = {
	defaultNetwork: 'hardhat',
	networks: {
		hardhat: {
			chainId: 1337,
		},
		rinkeby: {
			url: `https://rinkeby.infura.io/v3/${projectId}`,
			accounts: [keyData],
		},
		mainnet: {
			url: `https://mainnet.infura.io/v3/${projectId}`,
			accounts: [keyData],
		},
	},
	solidity: {
		version: '0.8.4',
		settings: {
			optimizer: {
				enabled: true,
				runs: 200,
			},
		},
	},
};
