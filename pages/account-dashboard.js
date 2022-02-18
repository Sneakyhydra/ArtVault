import { ethers } from 'ethers';
import { useEffect, useState } from 'react';
import axios from 'axios';
import Web3Modal from 'web3modal';

import { nftAddress, nftMarketAddress } from '../config';
import NFT from '../artifacts/contracts/NFT.sol/NFT.json';
import KBMarket from '../artifacts/contracts/KBMarket.sol/KBMarket.json';

import Image from 'next/image';

export default function AccountDashboard() {
	const [nfts, setNfts] = useState([]);
	const [loading, setLoading] = useState(true);

	useEffect(() => {
		loadNFTs();
		//eslint-disable-next-line
	}, []);

	// Function to load NFTs from the blockchain
	const loadNFTs = async () => {
		const web3modal = new Web3Modal();
		const connection = await web3modal.connect();
		const provider = new ethers.providers.Web3Provider(connection);
		const signer = provider.getSigner();

		const nftContract = new ethers.Contract(nftAddress, NFT.abi, provider);
		const marketContract = new ethers.Contract(
			nftMarketAddress,
			KBMarket.abi,
			signer
		);

		// Fetch owner nfts
		const data = await marketContract.fetchMintedNfts();

		// Make data readable
		const items = await Promise.all(
			data.map(async (i) => {
				const tokenURI = await nftContract.tokenURI(i.tokenId);
				const meta = await axios.get(tokenURI);
				let price = ethers.utils.formatUnits(i.price.toString(), 'ether');

				let item = {
					tokenId: i.tokenId.toNumber(),
					owner: i.owner,
					seller: i.seller,
					name: meta.data.name,
					description: meta.data.description,
					image: meta.data.image,
					price,
				};

				return item;
			})
		);

		setNfts(items);
		setLoading(false);
	};

	if (!loading && !nfts.length) {
		return (
			<h1 className='px-20 text-4x1 py-7'>You have not minted any nfts</h1>
		);
	}

	return (
		<div className='flex'>
			<div className='px-4' style={{ maxWidth: '1600px' }}></div>
			<div className='grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 pt-4'>
				{nfts.map((nft, i) => (
					<div key={i} className='border shadow rounded-x1 overflow-hidden'>
						<Image
							loader={() => nft.image}
							src={nft.image}
							alt={nft.name}
							height='250px'
							width='250px'
						/>
						<div className='p-4'>
							<p style={{ height: '64px' }} className='text-3xl font-semibold'>
								{nft.name}
							</p>
							<div style={{ height: '72px', overflow: 'hidden' }}>
								<p className='text-black'>{nft.description}</p>
							</div>
						</div>
						<div className='p-4 bg-black'>
							<p className='text-3x-1 mb-4 font-bold text-white'>
								{nft.price} ETH
							</p>
						</div>
					</div>
				))}
			</div>
		</div>
	);
}
