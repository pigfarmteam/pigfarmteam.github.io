module.exports = {
  ABI: require('./abi'),
  ABI_REFERRAL: require('./abi_referral'),

  RPC: process.env.NODE_ENV === 'production' ?
    'https://rpc.tomochain.com' :
    'https://rpc.tomochain.com',

  RPC_READ: process.env.NODE_ENV === 'production' ?
    'https://rpc.tomochain.com' :
    'https://rpc.tomochain.com',

  RPC_READ_SOCKET: process.env.NODE_ENV === 'production' ?
    'wss://ws.tomochain.com' :
    'wss://ws.tomochain.com',

  NETWORK_ID: process.env.NODE_ENV === 'production' ? '88' : '88',
  REFERRAL_ADDRESS: process.env.NODE_ENV === 'production' ?
    '0xce8419d22fa23196aeb354c028a231e51729f823' :
    '0xce8419d22fa23196aeb354c028a231e51729f823',
  ADDRESS: process.env.NODE_ENV === 'production' ?
    '0xbf1dcb735e512b731abd3404c15df6431bd03d42' :
    '0xbf1dcb735e512b731abd3404c15df6431bd03d42'
}