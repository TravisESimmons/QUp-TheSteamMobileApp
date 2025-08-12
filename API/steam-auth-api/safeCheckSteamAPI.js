const axios = require('axios');

const steamApiKey = process.env.STEAM_API_KEY || '';
const testSteamId = '76561198082041280';  // 👤 Use your own SteamID64

(async () => {
  try {
    const response = await axios.get(
      'https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/',
      {
        params: {
          key: steamApiKey,
          steamids: testSteamId
        },
        timeout: 5000
      }
    );

    if (response.status === 200) {
      console.log('✅ API is accessible again!');
      console.log(`Name: ${response.data.response.players[0].personaname}`);
    } else {
      console.log(`⚠️ Unexpected response code: ${response.status}`);
    }
  } catch (err) {
    if (err.response?.status === 429) {
      console.warn('🚫 Still rate limited (429 Too Many Requests)');
    } else {
      console.error('❌ Error contacting Steam API:', err.message);
    }
  }
})();
