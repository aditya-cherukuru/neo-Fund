const fetch = require('node-fetch');

// Test crypto API fixes
async function testCryptoAPIs() {
  console.log('🔍 Testing Crypto API Fixes\n');
  
  const testSymbols = ['BTCUSDT', 'ETHUSDT', 'BNBUSDT', 'ADAUSDT', 'SOLUSDT'];
  
  for (const symbol of testSymbols) {
    console.log(`Testing ${symbol}...`);
    
    try {
      // Test CoinGecko API
      const coinGeckoId = getCoinGeckoId(symbol);
      console.log(`  CoinGecko ID: ${coinGeckoId}`);
      
      const coinGeckoResponse = await fetch(`https://api.coingecko.com/api/v3/coins/${coinGeckoId}/market_chart?vs_currency=usd&days=30&interval=daily`, {
        signal: AbortSignal.timeout(3000)
      });
      
      if (!coinGeckoResponse.ok) {
        console.log(`  ❌ CoinGecko failed: ${coinGeckoResponse.status} ${coinGeckoResponse.statusText}`);
      } else {
        const contentType = coinGeckoResponse.headers.get('content-type');
        if (!contentType || !contentType.includes('application/json')) {
          console.log(`  ❌ CoinGecko returned non-JSON: ${contentType}`);
        } else {
          const data = await coinGeckoResponse.json();
          if (data.prices && data.prices.length > 0) {
            console.log(`  ✅ CoinGecko successful: ${data.prices.length} data points`);
          } else {
            console.log(`  ⚠️  CoinGecko no data`);
          }
        }
      }
      
      // Test Binance API
      const binanceResponse = await fetch(`https://api.binance.com/api/v3/klines?symbol=${symbol}&interval=1d&limit=30`, {
        signal: AbortSignal.timeout(2000)
      });
      
      if (!binanceResponse.ok) {
        console.log(`  ❌ Binance failed: ${binanceResponse.status} ${binanceResponse.statusText}`);
      } else {
        const contentType = binanceResponse.headers.get('content-type');
        if (!contentType || !contentType.includes('application/json')) {
          console.log(`  ❌ Binance returned non-JSON: ${contentType}`);
        } else {
          const data = await binanceResponse.json();
          if (data && data.length > 0) {
            console.log(`  ✅ Binance successful: ${data.length} data points`);
          } else {
            console.log(`  ⚠️  Binance no data`);
          }
        }
      }
      
    } catch (error) {
      console.log(`  ❌ Error testing ${symbol}: ${error.message}`);
    }
    
    console.log('');
  }
  
  console.log('🎉 Crypto API testing completed!');
}

// Helper function to map crypto symbols to CoinGecko IDs
function getCoinGeckoId(symbol) {
  const symbolMap = {
    'BTCUSDT': 'bitcoin',
    'BTC': 'bitcoin',
    'ETHUSDT': 'ethereum',
    'ETH': 'ethereum',
    'BNBUSDT': 'binancecoin',
    'BNB': 'binancecoin',
    'ADAUSDT': 'cardano',
    'ADA': 'cardano',
    'SOLUSDT': 'solana',
    'SOL': 'solana',
    'DOTUSDT': 'polkadot',
    'DOT': 'polkadot',
    'DOGEUSDT': 'dogecoin',
    'DOGE': 'dogecoin',
    'AVAXUSDT': 'avalanche-2',
    'AVAX': 'avalanche-2',
    'MATICUSDT': 'matic-network',
    'MATIC': 'matic-network',
    'LINKUSDT': 'chainlink',
    'LINK': 'chainlink',
    'UNIUSDT': 'uniswap',
    'UNI': 'uniswap',
    'LTCUSDT': 'litecoin',
    'LTC': 'litecoin',
    'BCHUSDT': 'bitcoin-cash',
    'BCH': 'bitcoin-cash',
    'XRPUSDT': 'ripple',
    'XRP': 'ripple',
    'ATOMUSDT': 'cosmos',
    'ATOM': 'cosmos',
    'FTMUSDT': 'fantom',
    'FTM': 'fantom',
    'NEARUSDT': 'near',
    'NEAR': 'near',
    'ALGOUSDT': 'algorand',
    'ALGO': 'algorand',
    'VETUSDT': 'vechain',
    'VET': 'vechain',
    'ICPUSDT': 'internet-computer',
    'ICP': 'internet-computer',
    'FILUSDT': 'filecoin',
    'FIL': 'filecoin',
    'TRXUSDT': 'tron',
    'TRX': 'tron',
    'ETCUSDT': 'ethereum-classic',
    'ETC': 'ethereum-classic',
    'XLMUSDT': 'stellar',
    'XLM': 'stellar',
    'HBARUSDT': 'hedera-hashgraph',
    'HBAR': 'hedera-hashgraph',
    'THETAUSDT': 'theta-token',
    'THETA': 'theta-token',
    'XTZUSDT': 'tezos',
    'XTZ': 'tezos'
  };
  
  return symbolMap[symbol] || symbol.toLowerCase();
}

// Run the test
testCryptoAPIs().catch(console.error); 