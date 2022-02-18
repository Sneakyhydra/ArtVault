import { ethers } from 'ethers';
import { useState } from 'react';
import Web3Modal from 'web3modal';
import { create as ipfsHttpClient } from 'ipfs-http-client';
import { nftAddress, nftMarketAddress } from '../config';
import NFT from '../artifacts/contracts/NFT.sol/NFT.json';
import KBMarket from '../artifacts/contracts/KBMarket.sol/KBMarket.json';
import { useRouter } from 'next/router';
import Image from 'next/image';

// In this component we set ipfs up to host our nft data
const client = ipfsHttpClient('https://ipfs.infura.io:5001/api/v0');

export default function MintItem() {
	const [fileUrl, setFileUrl] = useState(null);
	const [formInput, setFormInput] = useState({
		price: '',
		name: '',
		description: '',
	});
	const router = useRouter();

	// Set up a function to fire off when we update files in our form
	async function onChange(e) {
		try {
			const file = e.target.files[0];
			const added = await client.add(file, {
				progress: (progress) => {
					console.log(progress);
				},
			});

			const url = `https://ipfs.infura.io/ipfs/${added.path}`;
			setFileUrl(url);
		} catch (err) {
			console.log('Error uploading file to IPFS', err);
		}
	}

	async function createMarket() {
		const { name, description, price } = formInput;
		if (!name || !description || !price || !fileUrl) {
			return;
		}

		// Upload to IPFS
		const data = JSON.stringify({
			name,
			description,
			image: fileUrl,
		});

		try {
			const added = await client.add(data);
			const url = `https://ipfs.infura.io/ipfs/${added.path}`;
			createSale(url);
		} catch (err) {
			console.log('Error uploading file to IPFS', err);
		}
	}

	async function createSale(url) {
		const web3Modal = new Web3Modal();
		const connection = await web3Modal.connect();
		const provider = new ethers.providers.Web3Provider(connection);
		const signer = provider.getSigner();

		// We want to create the token
		let contract = new ethers.Contract(nftAddress, NFT.abi, signer);
		let transaction = await contract.mintToken(url);
		let tx = await transaction.wait();
		let event = tx.events[0];
		let value = event.args[2];
		let tokenId = value.toNumber();
		const price = ethers.utils.parseUnits(formInput.price, 'ether');

		// List the item for sale
		contract = new ethers.Contract(nftMarketAddress, KBMarket.abi, signer);
		let listingPrice = await contract.getListingPrice();
		listingPrice = listingPrice.toString();
		transaction = await contract.mintNft(nftAddress, tokenId, price, {
			value: listingPrice,
		});
		await transaction.wait();
		router.push('/');
	}

	return (
		<div className='flex justify-center'>
			<div className='w-1/2 flex flex-col pb-12'>
				<input
					type='text'
					placeholder='Asset Name'
					className='mt-8 border rounded p-4'
					onChange={(e) => setFormInput({ ...formInput, name: e.target.value })}
				/>
				<textarea
					placeholder='Asset Description'
					className='mt-2 border rounded p-4'
					onChange={(e) =>
						setFormInput({ ...formInput, description: e.target.value })
					}
				/>
				<input
					type='text'
					placeholder='Asset Price in ETH'
					className='mt-2 border rounded p-4'
					onChange={(e) =>
						setFormInput({ ...formInput, price: e.target.value })
					}
				/>
				<input
					type='file'
					placeholder='Asset'
					className='mt-4'
					onChange={onChange}
				/>
				{fileUrl && (
					<Image
						loader={() => fileUrl}
						alt='image'
						src={fileUrl}
						className='rounded mt-4'
						width='150px'
						height='350px'
					/>
				)}

				<button
					onClick={createMarket}
					className='font-bold mt-4 bg-purple-500 text-white rounded p-4 shadow-lg'
				>
					Mint Nft
				</button>
			</div>
		</div>
	);
}
