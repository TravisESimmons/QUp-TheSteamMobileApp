const fs = require('fs');
const axios = require('axios');
const cheerio = require('cheerio');

// Load original store cache
const cache = require('./storeCache.json');

// Load partial progress if it exists
let updated = fs.existsSync('./storeCache_updated.partial.json')
  ? JSON.parse(fs.readFileSync('./storeCache_updated.partial.json', 'utf-8'))
  : {};

// Headers to avoid being flagged as a bot
const headers = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
};

// Delay between requests to avoid being rate limited
const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Working version of extractSize
const extractSize = (html) => {
  const $ = cheerio.load(html);
  const sysReqBlocks = $('.game_area_sys_req').text().toLowerCase();

  const lines = sysReqBlocks.split('\n').map(line => line.trim()).filter(line =>
    /storage|available space|required space|space required/i.test(line)
  );

  const sizeRegex = /([\d.,]+)\s*(gb|mb)/gi;
  let maxSize = 0;
  let unit = 'GB';

  for (const line of lines) {
    let match;
    while ((match = sizeRegex.exec(line)) !== null) {
      const value = parseFloat(match[1].replace(',', '.'));
      const currentUnit = match[2].toUpperCase();

      if (!isNaN(value)) {
        const normalized = currentUnit === 'MB' ? value / 1024 : value;
        if (normalized > maxSize) {
          maxSize = normalized;
          unit = currentUnit;
        }
      }
    }
  }

  return maxSize > 0 ? `${maxSize} GB` : null;
};

(async () => {
  const appIds = Object.keys(cache);
  let count = 0;

  for (let i = 0; i < appIds.length; i++) {
    const appid = appIds[i];
    const game = cache[appid];
    count++;

    if (updated[appid]) {
      console.log(`🔁 [${count}/${appIds.length}] ${game.name} (${appid}) already processed`);
      continue;
    }

    const isProbablyMultiplayer = (game.categories || []).some(cat =>
      ["Multiplayer", "Online", "Co-op", "PvP"].some(keyword =>
        cat.toLowerCase().includes(keyword.toLowerCase())
      )
    ) || (game.genres || []).some(genre =>
      ["Multiplayer", "Online", "Co-op"].some(keyword =>
        genre.toLowerCase().includes(keyword.toLowerCase())
      )
    );

    if (!isProbablyMultiplayer) {
      console.log(`⏩ [${count}/${appIds.length}] ${game.name} (${appid}) skipped: not detected multiplayer`);
      updated[appid] = game;
      continue;
    }

    if (game.estimatedSize || game.estimatedSizeGB) {
      console.log(`✅ [${count}/${appIds.length}] ${game.name} (${appid}) already has size: ${game.estimatedSize || game.estimatedSizeGB}`);
      updated[appid] = game;
      continue;
    }

    const url = `https://store.steampowered.com/app/${appid}/`;
    console.log(`🔎 [${count}/${appIds.length}] Fetching ${game.name} (${appid})...`);

    try {
      const res = await axios.get(url, { headers });
      const sizeInfo = extractSize(res.data);

      if (sizeInfo) {
        game.estimatedSize = sizeInfo;
        console.log(`✅ ${game.name}: ${sizeInfo}`);
      } else {
        console.log(`❌ ${game.name}: No size info`);
      }

      updated[appid] = game;
    } catch (err) {
      console.warn(`⚠️ Error fetching ${appid}: ${err.message}`);
    }

    if (count % 25 === 0) {
      fs.writeFileSync('storeCache_updated.partial.json', JSON.stringify(updated, null, 2));
      console.log('💾 Auto-saved checkpoint');
    }

    await delay(Math.random() * 3000 + 3000); // 3–6 seconds
  }

  fs.writeFileSync('storeCache_updated.json', JSON.stringify(updated, null, 2));
  fs.rmSync('storeCache_updated.partial.json', { force: true });

  console.log('🎉 Done. Saved to storeCache_updated.json');
})();
