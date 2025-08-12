const fs = require('fs');
const path = require('path');
const axios = require('axios');

const steamApiKey = '0D163381E89303C6F85DA8E895D43F92';
const friendsPath = path.join(__dirname, 'steam_cache', 'friends.json');
const outputPath = path.join(__dirname, 'steam_cache', 'cached_profiles.json');

async function fetchProfiles(steamIds) {
  const chunks = [];
  for (let i = 0; i < steamIds.length; i += 100) {
    chunks.push(steamIds.slice(i, i + 100));
  }

  const profileMap = {};

  for (const chunk of chunks) {
    try {
      const res = await axios.get(
        'https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/',
        {
          params: {
            key: steamApiKey,
            steamids: chunk.join(',')
          }
        }
      );

      const players = res.data.response.players;
      for (const player of players) {
        profileMap[player.steamid] = {
          name: player.personaname,
          avatar: player.avatarfull
        };
        console.log(`✅ Cached profile: ${player.personaname}`);
      }
    } catch (err) {
      console.warn('⚠️ Failed to fetch chunk:', err.message);
    }

    // Optional delay to be super cautious
    await new Promise(r => setTimeout(r, 1500));
  }

  return profileMap;
}

(async () => {
  if (!fs.existsSync(friendsPath)) {
    console.error('❌ Cannot find friends.json');
    return;
  }

  const friendList = JSON.parse(fs.readFileSync(friendsPath));
  const steamIds = friendList.map(f => f.steamid);

  const profiles = await fetchProfiles(steamIds);
  fs.writeFileSync(outputPath, JSON.stringify(profiles, null, 2));
  console.log(`🎉 Saved ${Object.keys(profiles).length} profiles to cached_profiles.json`);
})();
