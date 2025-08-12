// cacheMyGames.js
const axios = require('axios');
const fs = require('fs');

const steamApiKey = '0D163381E89303C6F85DA8E895D43F92';
const yourSteamId = '76561198082041280'; // 👈 your own Steam ID
const filePath = `./cached_games_${yourSteamId}.json`;

(async () => {
  try {
    const res = await axios.get('https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/', {
      params: {
        key: steamApiKey,
        steamid: yourSteamId,
        include_appinfo: true,
        include_played_free_games: true
      }
    });

    const games = res.data.response.games || [];
    fs.writeFileSync(filePath, JSON.stringify(games, null, 2));
    console.log(`✅ Saved your own games to ${filePath} (${games.length} total)`);
  } catch (err) {
    if (err.response?.status === 429) {
      console.warn('🚫 Rate limited again (429)');
    } else {
      console.error('❌ Error fetching your games:', err.message);
    }
  }
})();
