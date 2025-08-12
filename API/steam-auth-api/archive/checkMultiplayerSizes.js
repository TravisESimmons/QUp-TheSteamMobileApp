const fs = require('fs');

// Load your JSON cache
const cache = JSON.parse(fs.readFileSync('storeCache_updated.json', 'utf8'));

let totalGames = 0;
let multiplayerGames = 0;
let singlePlayerOnly = 0;
let missingSize = 0;

const singlePlayerExamples = [];
const missingSizeGames = [];

for (const appid in cache) {
  const game = cache[appid];
  totalGames++;

  const categories = game.categories || [];
  const hasSingle = categories.includes('Single-player');
  const hasMulti = categories.includes('Multi-player');

  // Count multiplayer games and find missing sizes
  if (hasMulti) {
    multiplayerGames++;

    if (!game.estimatedSize || typeof game.estimatedSize !== 'string' || game.estimatedSize.trim() === '') {
      missingSize++;
      missingSizeGames.push({ appid, name: game.name });
    }
  }

  // Count strictly single-player only games
  if (hasSingle && !hasMulti) {
    singlePlayerOnly++;
    if (singlePlayerExamples.length < 5) {
      singlePlayerExamples.push(`${game.name} (AppID: ${appid})`);
    }
  }
}

// Output stats
console.log(`🎮 Total Games: ${totalGames}`);
console.log(`🤝 Multiplayer Games: ${multiplayerGames}`);
console.log(`📦 Multiplayer Games Missing Size: ${missingSize}`);
console.log(`📉 Percentage Missing: ${((missingSize / multiplayerGames) * 100).toFixed(2)}%`);
console.log(`🧍‍♂️ Single-Player Only Games: ${singlePlayerOnly}`);
console.log(`🔍 Examples of Single-Player Only Games:`);
singlePlayerExamples.forEach(name => console.log(`   - ${name}`));

// Output list of missing-size multiplayer games
console.log(`\n🛑 Multiplayer Games Missing Estimated Size:\n`);
missingSizeGames.forEach(game =>
  console.log(`   - ${game.name} (AppID: ${game.appid})`)
);
