const fs = require('fs');
const axios = require('axios');
const cheerio = require('cheerio');

// Load updated list of games missing multiplayer sizes
const games = require('./multiplayer_missing_sizes_final.json');

// Load the full cache
const originalCache = require('./storeCache_updated.json');

// Add age gate bypass cookies
const headers = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
  'Cookie': 'birthtime=568022401; lastagecheckage=1-January-1988; mature_content=1'
};

const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Extract size logic
const extractSize = (html, gameName) => {
  const $ = cheerio.load(html);
  let maxSize = 0;

  const tryRegex = (text) => {
    const sizeRegex = /([\d.,]+)\s*(gb|mb)/gi;
    let match;
    while ((match = sizeRegex.exec(text)) !== null) {
      const value = parseFloat(match[1].replace(',', '.'));
      const unit = match[2].toUpperCase();
      const normalized = unit === 'MB' ? value / 1024 : value;
      if (normalized > maxSize) maxSize = normalized;
    }
  };

  $('.game_area_sys_req').each((_, elem) => {
    tryRegex($(elem).text().toLowerCase());
  });

  if (maxSize === 0) {
    $('p, li').each((_, el) => {
      tryRegex($(el).text().toLowerCase());
    });
  }

  if (maxSize === 0) {
    tryRegex($('body').text().toLowerCase());
  }

  if (maxSize > 0) {
    console.log(`📦 Estimated size detected for ${gameName}: ${maxSize.toFixed(1)} GB`);
    return `${maxSize.toFixed(1)} GB`;
  } else {
    console.warn(`🕵️ No size found for ${gameName}`);
    return null;
  }
};

(async () => {
  const appIds = Object.keys(games);
  let count = 0;

  for (const appid of appIds) {
    count++;
    const game = games[appid];

    const existingSize = originalCache[appid]?.estimatedSize;
    if (existingSize && existingSize.includes('GB')) {
      console.log(`⏩ [${count}/${appIds.length}] ${game.name} (${appid}) already has size (${existingSize}), skipping`);
      continue;
    }

    const url = `https://store.steampowered.com/app/${appid}/`;
    console.log(`🔎 [${count}/${appIds.length}] Fetching ${game.name} (${appid})`);

    try {
      const res = await axios.get(url, { headers });
      const size = extractSize(res.data, game.name);

      if (size) {
        console.log(`✅ Found size for ${game.name}: ${size}`);
        if (originalCache[appid]) {
          originalCache[appid].estimatedSize = size;
        } else {
          console.warn(`⚠️ AppID ${appid} (${game.name}) not found in original cache`);
        }
      } else {
        console.log(`❌ No size found for ${game.name}`);
      }
    } catch (err) {
      console.warn(`⚠️ Error fetching ${appid} (${game.name}): ${err.message}`);
    }

    if (count % 25 === 0) {
      fs.writeFileSync('storeCache_updated.json', JSON.stringify(originalCache, null, 2));
      console.log('💾 Auto-saved after batch');
    }

    await delay(Math.random() * 3000 + 3000); // 3–6 sec delay
  }

  fs.writeFileSync('storeCache_updated.json', JSON.stringify(originalCache, null, 2));
  console.log('🎉 All done!');
})();
