const fs = require('fs');
const path = require('path');
const axios = require('axios');

const steamCacheDir = path.join(__dirname, 'steam_cache');
const storeCachePath = path.join(__dirname, 'storeCache.json');
const storeMetaCache = fs.existsSync(storeCachePath) ? JSON.parse(fs.readFileSync(storeCachePath)) : {};
const friendListPath = path.join(steamCacheDir, 'friends.json');

const delay = ms => new Promise(res => setTimeout(res, ms));

async function fetchAndCacheMeta(appid) {
  if (storeMetaCache[appid]) return;
  try {
    const { data } = await axios.get(`https://store.steampowered.com/api/appdetails?appids=${appid}`);
    const meta = data[appid.toString()]?.data;
    if (!meta) return;

    storeMetaCache[appid] = {
      name: meta.name,
      header_image: meta.header_image,
      categories: meta.categories?.map(c => c.description) || [],
      genres: meta.genres?.map(g => g.description) || [],
      userTags: meta.tags || [],
      release_date: meta.release_date?.date || null,
      maxPlayers: meta.supported_languages?.includes("Multi-player") ? 4 : 1 // crude fallback
    };

    console.log(`✅ Friend Game Cached: ${meta.name}`);
    await delay(1500);
  } catch (err) {
    console.warn(`⚠️ Friend Cache Fail ${appid}: ${err.message}`);
  }
}

async function run() {
  if (!fs.existsSync(friendListPath)) {
    console.log("❌ No friends.json found.");
    return;
  }

  const friends = JSON.parse(fs.readFileSync(friendListPath));
  const friendIds = friends.map(f => f.steamid);
  const appIdSet = new Set();

  for (const friendId of friendIds) {
    const gamePath = path.join(steamCacheDir, 'friendGames', `${friendId}.json`);
    if (!fs.existsSync(gamePath)) continue;
    const games = JSON.parse(fs.readFileSync(gamePath));
    games.forEach(g => appIdSet.add(g.appid));
  }

  console.log(`🔍 Fetching metadata for ${appIdSet.size} friend-owned games...`);
  for (const appid of appIdSet) {
    await fetchAndCacheMeta(appid.toString());
  }

  fs.writeFileSync(storeCachePath, JSON.stringify(storeMetaCache, null, 2));
  console.log(`📦 Friend metadata done. Total games in cache: ${Object.keys(storeMetaCache).length}`);
}

run();
