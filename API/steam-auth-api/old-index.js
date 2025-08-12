// [TOP IMPORTS SAME AS BEFORE]
const express = require('express');
const session = require('express-session');
const SteamAuth = require('steam-login');
const axios = require('axios');
const cheerio = require('cheerio');
const fetch = require('node-fetch');
const Bottleneck = require('bottleneck');
const fs = require('fs');
const path = require('path');


// const { GraphQLClient } = require('graphql-request');

axios.get('https://api.ipify.org?format=json').then(res => {
  console.log("🌐 Current Public IP (Node.js):", res.data.ip);
}).catch(err => {
  console.error("❌ Could not get public IP:", err.message);
});



const app = express();
const PORT = 3000;
const localNetworkUrl = 'http://192.168.1.93:3000';
const steamApiKey = '0D163381E89303C6F85DA8E895D43F92';

const userGameMap = {};
const storeMetaCache = {};
const cacheFilePath = path.join(__dirname, 'storeCache.json');

if (fs.existsSync(cacheFilePath)) {
  try {
    Object.assign(storeMetaCache, JSON.parse(fs.readFileSync(cacheFilePath)));
    console.log(`📦 Loaded ${Object.keys(storeMetaCache).length} cached entries`);
  } catch (err) {
    console.warn('⚠️ Failed to load cache:', err.message);
  }
}
function saveStoreCache() {
  try {
    fs.writeFileSync(cacheFilePath, JSON.stringify(storeMetaCache, null, 2));
    console.log('💾 storeMetaCache saved');
  } catch (err) {
    console.error('❌ Failed to save store cache:', err.message);
  }
}
process.on('SIGINT', () => { saveStoreCache(); process.exit(); });
process.on('SIGTERM', () => { saveStoreCache(); process.exit(); });

const limiter = new Bottleneck({
  maxConcurrent: 1,
  minTime: 3000 // 3 seconds per request
});


app.use(session({ secret: 'queueup_secret', resave: false, saveUninitialized: true }));
app.use(SteamAuth.middleware({
  realm: `${localNetworkUrl}/`,
  verify: `${localNetworkUrl}/auth/steam/return`,
  apiKey: steamApiKey
}));

const manualSizeEstimates = {
  "550": 13, "730": 30, "271590": 72, "570": 15, "292030": 50,
  "1172470": 45, "252490": 35, "1222670": 70, "359550": 70, "578080": 40
};
const manualMultiplayerGames = new Set([
  "550", "730", "271590", "359550", "578080", "252490", "1172470"
]);

function parseStoreSize(desc) {
  const match = desc?.match(/(\d+\.?\d*)\s*(GB|MB)/i);
  if (!match) return undefined;
  const size = parseFloat(match[1]);
  return match[2].toUpperCase() === 'GB' ? size : size / 1024;
}


async function fetchSteamDBSize(appId) {
  const endpoint = 'https://steamdb.info/api/GraphQL/';
  const query = gql`
    query getDepotSize {
      app(id: ${appId}) {
        depots {
          id
          maxSize
        }
      }
    }
  `;

  const client = new GraphQLClient(endpoint, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:120.0) Gecko/20100101 Firefox/120.0',
      'Accept': '*/*',
      'Referer': `https://steamdb.info/app/${appId}/`,
      'Origin': 'https://steamdb.info',
      'Sec-Fetch-Site': 'same-origin',
    },
  });

  try {
    const response = await client.request(query);
    const depots = response?.app?.depots || [];
    const totalSizeBytes = depots.reduce((sum, depot) => sum + (depot.maxSize || 0), 0);
    const sizeGB = totalSizeBytes / (1024 ** 3); // bytes to GB
    return sizeGB > 0.1 ? parseFloat(sizeGB.toFixed(1)) : undefined;
  } catch (err) {
    console.warn(`⚠️ SteamDB GraphQL failed for ${appId}: ${err.response?.status || ''} - ${err.message}`);
    return undefined;
  }
}



async function fetchUserTags(appId) {
  try {
    const res = await fetch(`https://store.steampowered.com/app/${appId}`);
    const html = await res.text();
    const $ = cheerio.load(html);
    return $('.glance_tags.popular_tags a.app_tag').map((_, el) => $(el).text().trim().toLowerCase()).get();
  } catch (err) {
    console.warn(`⚠️ Tags fetch failed for ${appId}: ${err.message}`);
    return [];
  }
}

async function preloadUserData(steamId) {
  try {
    const res = await axios.get(`https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/`, {
      params: {
        key: steamApiKey,
        steamid: steamId,
        include_appinfo: true,
        include_played_free_games: true
      }
    });

    const allGames = res.data.response.games || [];
    userGameMap[steamId] = allGames;

    const topGames = allGames
      .filter(g => (g.playtime_forever ?? 0) > 0)
      .sort((a, b) => b.playtime_forever - a.playtime_forever)
      .slice(0, 50);

    for (const game of topGames) {
      const appId = game.appid.toString();
      if (storeMetaCache[appId]) continue;

      storeMetaCache[appId] = {
        genres: [],
        categories: [],
        userTags: [],
        header_image: `https://cdn.cloudflare.steamstatic.com/steam/apps/${appId}/header.jpg`,
        estimatedSizeGB: manualSizeEstimates[appId] ?? 10
      };

      try {
        const storeRes = await limiter.schedule(() =>
          axios.get(`https://store.steampowered.com/api/appdetails?appids=${appId}`)
        );

        const data = storeRes.data[appId];
        if (data.success && data.data) {
          const size = parseStoreSize(data.data.pc_requirements?.minimum);
          storeMetaCache[appId].genres = (data.data.genres || []).map(g => g.description.toLowerCase());
          storeMetaCache[appId].categories = (data.data.categories || []).map(c => c.description.toLowerCase());
          storeMetaCache[appId].header_image = data.data.header_image || storeMetaCache[appId].header_image;
          storeMetaCache[appId].estimatedSizeGB = size ?? storeMetaCache[appId].estimatedSizeGB;
        }

        // No userTags for now (preventing rate limit)
        storeMetaCache[appId].userTags = [];

      } catch (err) {
        if (err.response?.status === 429) {
          console.warn(`⏳ Rate limited by Steam for app ${appId}, skipping`);
          continue;
        }
        console.warn(`⚠️ Metadata fetch failed for ${appId}: ${err.message}`);
      }
    }

    console.log(`✅ Cached ${allGames.length} games (${topGames.length} with metadata) for ${steamId}`);
  } catch (err) {
    console.error(`🔥 Failed to preload user games for ${steamId}: ${err.message}`);
  }
}


const metadataLoadInProgress = {};

// async function preloadSingleGame(appId) {
//   try {
//     const [storeRes, userTags] = await Promise.all([
//       limiter.schedule(() => axios.get(`https://store.steampowered.com/api/appdetails?appids=${appId}`)),
//       fetchUserTags(appId)
//     ]);

//     const data = storeRes.data[appId];
//     const manualFallback = manualSizeEstimates[appId] ?? null;


//     let size;
// if (data.success && data.data) {
//   size = parseStoreSize(data.data.pc_requirements?.minimum);
// }

// if (!size) {
//   size = await fetchSteamDBSize(appId) ?? manualFallback;
// }


//     storeMetaCache[appId] = {
//       genres: (data?.data?.genres || []).map(g => g.description.toLowerCase()),
//       categories: (data?.data?.categories || []).map(c => c.description.toLowerCase()),
//       userTags,
//       header_image: data?.data?.header_image || `https://cdn.cloudflare.steamstatic.com/steam/apps/${appId}/header.jpg`,
//       estimatedSizeGB: size
//     };

//     saveStoreCache();
//   } catch (err) {
//     console.warn(`⚠️ Single-game metadata failed for ${appId}: ${err.message}`);
//   } finally {
//     delete metadataLoadInProgress[appId];
//   }
// }



// ===== ROUTES =====
app.get('/', (req, res) => {
  res.send('<a href="/auth/steam">Login with Steam</a>');
});

app.get('/auth/steam', SteamAuth.authenticate());

app.get('/auth/steam/return', SteamAuth.verify(), async (req, res) => {
  if (!req.user || !req.user.steamid) {
    return res.status(400).send("Steam login failed.");
  }

  const steamId = req.user.steamid;
  console.log(`✅ Logged in as ${steamId}`);

  try {
    // Just validate login and cache basic user ID
    userGameMap[steamId] = []; // placeholder
    console.log(`✅ Login successful, skipping preload for now`);
    res.redirect(`steamqapp://auth-success?steamid=${steamId}`);
  } catch (e) {
    console.error("🔥 Login error:", e.message);
    res.status(500).send("Steam login failed.");
  }
  
});

app.get('/api/user-info', async (req, res) => {
  const steamId = req.query.steamid;

  try {
    const [profileRes, friendsRes] = await Promise.allSettled([
      axios.get(`https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/?key=${steamApiKey}&steamids=${steamId}`),
      axios.get(`https://api.steampowered.com/ISteamUser/GetFriendList/v1/?key=${steamApiKey}&steamid=${steamId}&relationship=friend`)
    ]);

    const profile = profileRes.status === "fulfilled" ? profileRes.value.data.response.players[0] : null;
    const friendIds = friendsRes.status === "fulfilled"
      ? friendsRes.value.data.friendslist?.friends?.map(f => f.steamid) || []
      : [];

    const friendProfiles = [];

    for (let i = 0; i < friendIds.length; i += 100) {
      const chunk = friendIds.slice(i, i + 100);
      try {
        const chunkRes = await axios.get(`https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/?key=${steamApiKey}&steamids=${chunk.join(',')}`);
        friendProfiles.push(...chunkRes.data.response.players.map(p => ({
          steamId: p.steamid,
          name: p.personaname,
          avatar: p.avatarfull
        })));
      } catch (e) {
        console.warn(`⚠️ Failed to load friend chunk: ${e.message}`);
      }
    }

    friendProfiles.sort((a, b) => a.name.localeCompare(b.name));
    res.json({
      steamId,
      profile: profile ? { name: profile.personaname, avatar: profile.avatarfull } : null,
      friends: friendProfiles
    });

  } catch (err) {
    console.error("🔥 user-info error:", err.message);
    res.status(500).json({ error: 'Failed to retrieve user info' });
  }
});


app.get('/api/user-games', async (req, res) => {
  const steamId = req.query.steamid;
  try {
    const games = userGameMap[steamId] ?? [];
    res.json({ games });
  } catch (err) {
    console.error("🔥 user-games error:", err.message);
    res.status(500).json({ error: 'Failed to fetch games' });
  }
});



app.get('/api/friend-games', async (req, res) => {
  const steamId = req.query.steamid;
  try {
    const games = userGameMap[steamId] ?? [];
    res.json({ success: true, games });
  } catch (e) {
    console.error("🔥 friend-games error:", e.message);
    res.status(500).json({ error: 'Failed to fetch games' });
  }
});


app.get('/api/custom-match', async (req, res) => {
  const { steamids, genres = '', maxPlay = 600, maxSize = 100 } = req.query;
  if (!steamids) return res.status(400).json({ error: "Missing steamids" });

  const ids = steamids.split(',');
  const genreFilters = genres.split(',').map(g => g.trim().toLowerCase()).filter(Boolean);
  const maxPlayMinutes = parseInt(maxPlay);
  const maxSizeGB = parseFloat(maxSize);
  const gameCounts = {};
  const results = [];

  try {
    // STEP 1: Collect shared games across all users
    for (const id of ids) {
      let games = userGameMap[id];
      if (!games) {
        await preloadUserData(id);
        games = userGameMap[id];
      }

      for (const game of games) {
        const appId = game.appid.toString();
        if (!gameCounts[appId]) gameCounts[appId] = { count: 1, game };
        else gameCounts[appId].count++;
      }
    }

    const sharedGameEntries = Object.entries(gameCounts)
      .filter(([_, entry]) => entry.count === ids.length)
      .slice(0, 60); // Limit to 50 shared games to avoid abuse

    for (const [appId, entry] of sharedGameEntries) {
      const { game } = entry;

      let meta = storeMetaCache[appId];
      let estimatedSizeGB;

      if (!meta) {
        storeMetaCache[appId] = meta = {
          genres: [],
          categories: [],
          userTags: [],
          header_image: `https://cdn.cloudflare.steamstatic.com/steam/apps/${appId}/header.jpg`,
          estimatedSizeGB: null
        };
      }

      // Only hit SteamDB if we have no reliable size estimate
      if (meta.estimatedSizeGB == null && !metadataLoadInProgress[appId]) {
        metadataLoadInProgress[appId] = true;
        await preloadSingleGame(appId); // This updates storeMetaCache
        meta = storeMetaCache[appId]; // Refresh
      }

      estimatedSizeGB = meta.estimatedSizeGB ?? manualSizeEstimates[appId] ?? 50;

      const genres = meta.genres || [];
      const categories = meta.categories || [];
      const userTags = meta.userTags || [];
      const header_image = meta.header_image;

      const playtime = game.playtime_forever ?? 0;
      const multiplayerTags = ['multiplayer', 'online multiplayer', 'pvp', 'co-op', 'cooperative', 'lan multiplayer'];
      const isMultiplayer = multiplayerTags.some(tag =>
        [...categories, ...userTags].some(t => t.includes(tag))
      );
      const isManualMultiplayer = manualMultiplayerGames.has(appId);

      if (!isMultiplayer && !isManualMultiplayer) continue;
      if (genreFilters.length && !genreFilters.some(g => genres.includes(g))) continue;
      if ((playtime / 60) > maxPlayMinutes) continue;
      if (!isNaN(maxSizeGB) && estimatedSizeGB > maxSizeGB) continue;

      results.push({ ...game, header_image, estimatedSizeGB });
    }

    res.json({
      success: true,
      results,
      sharedGames: sharedGameEntries.length
    });
  } catch (err) {
    console.error("🔥 custom-match error:", err.message);
    res.status(500).json({ error: 'Failed to process match' });
  }
});


app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Running on ${localNetworkUrl}`);
});
