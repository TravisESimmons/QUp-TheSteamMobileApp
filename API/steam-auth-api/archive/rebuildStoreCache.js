const fs = require('fs');
const path = require('path');
const axios = require('axios');

const steamCacheDir = path.join(__dirname, 'steam_cache');
const outputPath = path.join(__dirname, 'storeCache.json');

const allAppIds = new Set();

// 🧠 Step 1: Gather all app IDs from cached game files
fs.readdirSync(steamCacheDir).forEach(file => {
  if (file.startsWith('cached_games_') && file.endsWith('.json')) {
    const games = JSON.parse(fs.readFileSync(path.join(steamCacheDir, file)));
    for (const game of games) {
      allAppIds.add(game.appid);
    }
  }
});

// 🧠 Step 2: Fetch metadata for each app
async function fetchGameMeta(appid) {
  try {
    const { data } = await axios.get(`https://store.steampowered.com/api/appdetails?appids=${appid}`);
    const appData = data[appid.toString()];
    if (!appData.success || !appData.data) return null;

    const info = appData.data;

    const categories = info.categories?.map(c => c.description) || [];
    const genres = info.genres?.map(g => g.description) || [];
    const userTags = info.tags ? Object.keys(info.tags) : [];

    return {
      appid,
      name: info.name,
      header_image: info.header_image,
      release_date: info.release_date?.date || null,
      categories,
      genres,
      userTags,
      maxPlayers: info?.required_age === 0 ? null : undefined, // Placeholder (can update this if you use another API)
    };
  } catch (err) {
    console.warn(`⚠️ Failed to fetch ${appid}: ${err.message}`);
    return null;
  }
}

// 🧠 Step 3: Rebuild cache
(async () => {
  console.log(`🔍 Fetching metadata for ${allAppIds.size} apps...`);
  const storeCache = {};

  for (const appid of allAppIds) {
    const meta = await fetchGameMeta(appid);
    if (meta) {
      storeCache[appid.toString()] = meta;
      console.log(`✅ Cached: ${meta.name}`);
    }
    await new Promise(res => setTimeout(res, 1500)); // Respect rate limits
  }

  fs.writeFileSync(outputPath, JSON.stringify(storeCache, null, 2));
  console.log(`📦 Done! Wrote metadata for ${Object.keys(storeCache).length} games to storeCache.json`);
})();
