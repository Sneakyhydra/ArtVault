import '../styles/globals.css';
import './app.css';
import Link from 'next/link';

const KryptoBirdzMarketplace = ({ Component, pageProps }) => {
	return (
		<div>
			<nav className='border-b p-6' style={{ backgroundColor: 'purple' }}>
				<p className='text-4x1 font-bold text-white'>KryptoBirdz Marketplace</p>
				<div className='flex mt-4 justify-center'>
					<Link href='/'>
						<a className='mr-6'>Main Marketplace</a>
					</Link>
					<Link href='/mint-item'>
						<a className='mr-6'>Mint Tokens</a>
					</Link>
					<Link href='/my-nfts'>
						<a className='mr-6'>My NFTs</a>
					</Link>
					<Link href='/account-dashboard'>
						<a className='mr-6'>Dashboard</a>
					</Link>
				</div>
			</nav>
			<Component {...pageProps} />
		</div>
	);
};

export default KryptoBirdzMarketplace;
