const fs = require('fs');
const path = require('path');
const axios = require('axios');

const steamApiKey = process.env.STEAM_API_KEY || '';
const yourSteamId = '76561198082041280';

const FRIENDS_CACHE_PATH = path.join(__dirname, 'steam_cache', 'friends.json');
const FRIEND_GAMES_DIR = path.join(__dirname, 'steam_cache', 'friendGames');

// Ensure cache directories exist
fs.mkdirSync(FRIEND_GAMES_DIR, { recursive: true });

const delay = ms => new Promise(resolve => setTimeout(resolve, ms));

async function fetchFriendsList() {
  try {
    const res = await axios.get('https://api.steampowered.com/ISteamUser/GetFriendList/v1/', {
      params: {
        key: steamApiKey,
        steamid: yourSteamId,
        relationship: 'friend'
      }
    });

    const friends = res.data.friendslist?.friends || [];
    fs.writeFileSync(FRIENDS_CACHE_PATH, JSON.stringify(friends, null, 2));
    console.log(`✅ Saved ${friends.length} friends`);
    return friends.map(f => f.steamid);
  } catch (err) {
    console.error('🔥 Error fetching friends:', err.message);
    return [];
  }
}

async function fetchFriendGames(steamId) {
  const cachePath = path.join(FRIEND_GAMES_DIR, `${steamId}.json`);
  if (fs.existsSync(cachePath)) {
    console.log(`📦 Cached: ${steamId}`);
    return;
  }

  try {
    const res = await axios.get('https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/', {
      params: {
        key: steamApiKey,
        steamid: steamId,
        include_appinfo: true,
        include_played_free_games: true
      },
      timeout: 10000
    });

    fs.writeFileSync(cachePath, JSON.stringify(res.data.response.games || [], null, 2));
    console.log(`✅ Saved games for ${steamId}`);
  } catch (err) {
    if (err.response?.status === 429) {
      console.warn(`⏳ 429 Rate limit hit on ${steamId}, stop now.`);
      process.exit(); // Stop everything if we get rate-limited
    } else {
      console.warn(`⚠️ Failed for ${steamId}: ${err.message}`);
    }
  }
}

(async () => {
  const friends = await fetchFriendsList();

  for (const steamId of friends) {
    await fetchFriendGames(steamId);
    await delay(5500); // ⏱ Wait 5.5 seconds between requests
  }

  console.log('🎉 Done caching all friends + their games safely.');
})();
