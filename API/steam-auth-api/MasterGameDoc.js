const fs = require('fs');

// Load the full master cache
const cache = JSON.parse(fs.readFileSync('storeCache_updated.json', 'utf8'));

const filtered = {};

for (const appid in cache) {
  const game = cache[appid];

  const categories = game.categories || [];
  const hasMulti = categories.includes('Multi-player');
  const hasValidSize = game.estimatedSize && typeof game.estimatedSize === 'string' && game.estimatedSize.trim() !== '';

  if (hasMulti && hasValidSize) {
    filtered[appid] = game;
  }
}

fs.writeFileSync('filteredMultiplayerGames.json', JSON.stringify(filtered, null, 2));
console.log(`✅ Saved filtered data: ${Object.keys(filtered).length} multiplayer games with estimated sizes`);
