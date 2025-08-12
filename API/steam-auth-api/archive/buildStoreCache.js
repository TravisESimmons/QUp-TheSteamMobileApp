// buildStoreCache.js
const fs = require('fs');
const path = require('path');
const axios = require('axios');

const storeMetaPath = path.join(__dirname, 'storeCache.json');
const steamCacheDir = path.join(__dirname, 'steam_cache');
const friendGamesDir = path.join(steamCacheDir, 'friendGames');

const existingCache = fs.existsSync(storeMetaPath)
  ? JSON.parse(fs.readFileSync(storeMetaPath))
  : {};

function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function fetchAppDetails(appid) {
  try {
    const res = await axios.get(`https://store.steampowered.com/api/appdetails`, {
      params: { appids: appid }
    });

    if (res.data[appid] && res.data[appid].success) {
      const data = res.data[appid].data;
      return {
        name: data.name,
        header_image: data.header_image,
        estimatedSizeGB: null // optional
      };
    }
  } catch (err) {
    console.warn(`⚠️ Failed to fetch appid ${appid}: ${err.message}`);
  }
  return null;
}

(async () => {
  const seenAppIds = new Set(Object.keys(existingCache));
  const appIdsToFetch = new Set();

  const friendFiles = fs.readdirSync(friendGamesDir).filter(f => f.endsWith('.json'));

  for (const file of friendFiles) {
    const games = JSON.parse(fs.readFileSync(path.join(friendGamesDir, file)));
    for (const game of games) {
      if (!seenAppIds.has(game.appid.toString())) {
        appIdsToFetch.add(game.appid.toString());
      }
    }
  }

  console.log(`🔎 Need to fetch ${appIdsToFetch.size} app details...`);

  for (const appid of appIdsToFetch) {
    const details = await fetchAppDetails(appid);
    if (details) {
        existingCache[appid] = details;
        fs.writeFileSync(storeMetaPath, JSON.stringify(existingCache, null, 2)); // 💾 Save immediately
        console.log(`✅ Cached ${details.name}`);
    } else {
      console.log(`❌ No data for ${appid}, skipping.`);
    }
    await delay(1500); // 👈 Be nice to Steam servers
  }

  fs.writeFileSync(storeMetaPath, JSON.stringify(existingCache, null, 2));
  console.log(`💾 Saved updated store metadata cache (${Object.keys(existingCache).length} total entries)`);
})();
