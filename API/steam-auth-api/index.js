const fs = require('fs');
const express = require('express');
const session = require('express-session');
const openid = require('openid');
const axios = require('axios');
const path = require('path');
const appDetailsCache = new Map(); 

const app = express();
const PORT = process.env.PORT || 3000;
const renderUrl = process.env.APP_BASE_URL || 'https://qup-thesteammobileapp.onrender.com';
const steamApiKey = process.env.STEAM_API_KEY || '';
const steamRelyingParty = new openid.RelyingParty(
  `${renderUrl}/auth/steam/return`,
  `${renderUrl}/`,
  true,
  true,
  []
);

// Serve Flutter web app static files
app.use(express.static(path.join(__dirname, 'web')));

// Add CORS headers to allow requests from localhost (for web development)
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} ${req.method} ${req.originalUrl}`);
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  if (req.method === 'OPTIONS') {
    res.sendStatus(200);
  } else {
    next();
  }
});

// Use only multiplayer games with valid sizes (faster load, tighter filter)
const localGameCache = JSON.parse(fs.readFileSync('./filteredMultiplayerGames.json', 'utf-8'));

// For full testing/debug purposes, you can revert to full cache:
// const localGameCache = JSON.parse(fs.readFileSync('./storeCache_updated.json', 'utf-8'));



app.use(session({ secret: process.env.SESSION_SECRET || 'queueup_secret', resave: false, saveUninitialized: true }));
app.use((req, _res, next) => {
  if (req.session?.steamUser) {
    req.user = req.session.steamUser;
    req.logout = () => {
      delete req.session.steamUser;
      req.user = null;
    };
  }

  next();
});

function isGameActuallyMultiplayer(meta) {
  const name = (meta?.name || "").toLowerCase();

  const rawCategories = meta.categories || [];
  const rawGenres = meta.genres || [];

  const allTags = [
    ...rawCategories.map(c => typeof c === 'string' ? c.toLowerCase() : c.description?.toLowerCase() || ''),
    ...rawGenres.map(g => typeof g === 'string' ? g.toLowerCase() : g.description?.toLowerCase() || ''),
  ];

  const alwaysYes = [
    "call of duty", "lethal company", "deep rock", "left 4 dead", "black ops", "payday",
    "risk of rain", "vermintide", "chivalry", "csgo", "team fortress", "halo"
  ];

  const alwaysNo = [
    "witcher", "skyrim", "bioshock", "cyberpunk", "fallout 3", "fallout: new vegas", "doom (1993)"
  ];

  if (alwaysYes.some(term => name.includes(term))) return true;
  if (alwaysNo.some(term => name.includes(term))) return false;

  const multiplayerKeywords = [
    "multi-player", "multiplayer", "co-op", "online co-op", "pvp", "online pvp",
    "versus", "team-based", "cross-platform multiplayer", "lan"
  ];

  return allTags.some(tag =>
    multiplayerKeywords.some(keyword => tag.includes(keyword))
  );
}




async function getOwnedGames(steamId) {
  const res = await steamApiGet('https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/', {
    key: steamApiKey,
    steamid: steamId,
    include_appinfo: true
  });
  return res.data?.response?.games || [];
}

async function getFriendList(steamId) {
  const res = await steamApiGet('https://api.steampowered.com/ISteamUser/GetFriendList/v1/', {
    key: steamApiKey,
    steamid: steamId,
    relationship: 'friend'
  });
  return res.data?.friendslist?.friends?.map(f => f.steamid) || [];
}

async function getPlayerProfile(steamId) {
  const res = await steamApiGet('https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/', {
    key: steamApiKey,
    steamids: steamId
  });
  const player = res.data?.response?.players?.[0];
  return {
    name: player?.personaname || 'Friend',
    avatar: player?.avatarfull || 'https://avatars.cloudflare.steamstatic.com/placeholder.jpg'
  };
}

async function steamApiGet(url, params) {
  try {
    return await axios.get(url, { params });
  } catch (err) {
    const status = err.response?.status;
    const method = url.split('/').filter(Boolean).pop();
    console.error(`Steam API ${method} failed`, {
      status,
      steamid: params.steamid || params.steamids,
      apiKeyPresent: Boolean(steamApiKey),
      body: err.response?.data
    });
    throw err;
  }
}

function authenticateWithSteam(_req, res, next) {
  steamRelyingParty.authenticate('https://steamcommunity.com/openid', false, (err, authUrl) => {
    if (err) {
      console.error('Steam OpenID authentication failed:', err);
      return next('Authentication failed.');
    }

    if (!authUrl) {
      return next('Authentication failed.');
    }

    res.redirect(authUrl);
  });
}

function verifySteamOpenId(req, _res, next) {
  steamRelyingParty.verifyAssertion(req, (err, result) => {
    if (err) {
      console.error('Steam OpenID verification failed:', err);
      return next('Failed to authenticate user.');
    }

    if (!result?.authenticated) {
      return next('Failed to authenticate user.');
    }

    const match = result.claimedIdentifier?.match(/^https?:\/\/steamcommunity\.com\/openid\/id\/(\d+)$/);
    if (!match) {
      return next('Claimed identity is not valid.');
    }

    req.user = { steamid: match[1] };
    req.session.steamUser = req.user;
    req.logout = () => {
      delete req.session.steamUser;
      req.user = null;
    };

    next();
  });
}

async function getAppDetails(appId) {
  appId = appId.toString();

  if (appDetailsCache.has(appId)) {
    return appDetailsCache.get(appId);
  }

  const meta = localGameCache[appId];
  if (!meta) {
    console.warn(`❌ AppID ${appId} not found in local cache`);
    return null;
  }

  const name = meta.name || 'Unknown';
  const lowerCats = (meta.categories || []).map(c => c.toLowerCase());
  const isCoop = lowerCats.some(c => c.includes('co-op'));
  const isVersus = lowerCats.some(c => c.includes('versus') || c.includes('pvp'));

  const details = {
    appid: appId,
    name,
    header_image: meta.header_image,
    genres: meta.genres || [],
    categories: meta.categories || [],
    releaseYear: parseInt(meta.release_date?.split(',')?.pop()?.trim()) || null,
    maxPlayers: null,
    estimatedSizeGB: (() => {
      const raw = meta.estimatedSize;
      if (!raw) return null;
      const number = parseFloat(raw.toLowerCase().replace('gb', '').trim());
      return isNaN(number) ? null : number;
    })(),
    isFree: false,
    playtime_forever: 0,
    isMultiplayer: isGameActuallyMultiplayer(meta),
    isCoop,
    isVersus
  };

  appDetailsCache.set(appId, details);
  return details;
}


// === Routes ===

app.get('/', (req, res) => res.send('<a href="/auth/steam">Login with Steam</a>'));
app.get('/auth/steam', authenticateWithSteam);
app.get('/auth/steam/return', verifySteamOpenId, (req, res) => {
  const steamId = req.user?.steamid;
  if (!steamId) return res.status(400).send("Steam login failed");
  
  // Check if request is from web (has certain headers or query params)
  const userAgent = req.get('User-Agent') || '';
  const isWeb = userAgent.includes('Mozilla') && !userAgent.includes('Mobile');
  const fromWeb = req.query.web === 'true';
  
  if (isWeb || fromWeb) {
    // For web: Send HTML page that posts message back to parent window
    res.send(`
      <!DOCTYPE html>
      <html>
        <head><title>Login Success</title></head>
        <body>
          <script>
            // Post message back to Flutter web app
            if (window.opener) {
              window.opener.postMessage({
                type: 'STEAM_LOGIN_SUCCESS',
                steamId: '${steamId}'
              }, '*');
              window.close();
            } else {
              // Fallback: redirect to localhost with steamid
              window.location.href = 'http://localhost:8080?steamid=${steamId}';
            }
          </script>
          <p>Login successful! You can close this window.</p>
        </body>
      </html>
    `);
  } else {
    // For mobile apps: use deep link redirect  
    res.redirect(`steamqapp://auth-success?steamid=${steamId}`);
  }
});


app.get('/api/user-info', async (req, res) => {
  const steamId = req.query.steamid;
  console.log(`🔑 Steam API Key present: ${steamApiKey ? 'YES' : 'NO'}`);
  console.log(`👤 Getting profile for Steam ID: ${steamId}`);

  try {
    const profile = await getPlayerProfile(steamId);
    const friendIds = await getFriendList(steamId);
    res.json({ steamId, profile, friendIds: friendIds.slice(0, 50) });
  } catch (err) {
    console.error('Failed to fetch Steam data, returning defaults:', err.message);
    // Return default data to allow app to load
    const defaultProfile = { name: 'Player', avatar: 'https://avatars.cloudflare.steamstatic.com/placeholder.jpg' };
    res.json({ steamId, profile: defaultProfile, friendIds: [] });
  }
});

app.get('/api/friend-profile', async (req, res) => {
  const steamId = req.query.steamid;
  if (!steamId) return res.status(400).json({ error: 'Missing steamid' });
  try {
    const profile = await getPlayerProfile(steamId);
    res.json(profile);
  } catch (err) {
    console.error(`Failed to load profile for ${steamId}: ${err.message}`);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

app.get('/api/friend-games', async (req, res) => {
  const steamId = req.query.steamid;
  const games = await getOwnedGames(steamId);
  res.json({ success: true, games });
});

app.get('/api/player-summaries', async (req, res) => {
  const steamIds = req.query.steamids;
  if (!steamIds) return res.status(400).json({ error: 'Missing steamids' });

  try {
    const result = await axios.get(
      'https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/',
      {
        params: {
          key: steamApiKey,
          steamids: steamIds,
        },
      }
    );

    res.json(result.data.response);
  } catch (err) {
    console.error("❌ Failed to fetch player summaries:", err.message);
    res.status(500).json({ error: 'Failed to fetch player summaries' });
  }
});


app.get('/api/custom-match', async (req, res) => {
  const ids = req.query.steamids?.split(',') || [];
  const genreFilter = (req.query.genres || '').toLowerCase().split(',').filter(g => g.trim());
  const coopOnly = req.query.coop === 'true';
  const versusOnly = req.query.versus === 'true';
  const minYear = parseInt(req.query.minYear) || 2000;
  const maxYear = parseInt(req.query.maxYear) || new Date().getFullYear();
  const matchLimit = parseInt(req.query.limit) || 20;
  const minSize = parseFloat(req.query.minSize) || 0;
  const maxSize = parseFloat(req.query.maxSize) || Infinity;

  const allGamesMap = {};

  console.log(`🔎 Matching for SteamIDs: ${ids.join(', ')}`);
  console.log(`🔍 Filters: genre=${genreFilter.join(', ') || 'any'}, coop=${coopOnly}, versus=${versusOnly}, year=${minYear}–${maxYear}, size=${minSize}–${maxSize} GB`);

  for (const id of ids) {
    const games = await getOwnedGames(id);
    console.log(`🕹️ ${id} owns ${games.length} games`);

    for (const g of games) {
      if (!allGamesMap[g.appid]) allGamesMap[g.appid] = [];
      allGamesMap[g.appid].push({ ...g, owner: id });
    }
    await new Promise(r => setTimeout(r, 1000)); // prevent 429s
  }

  const sharedAppIds = Object.entries(allGamesMap)
    .filter(([_, games]) => games.length === ids.length)
    .map(([appid, games]) => ({ appid, games }));

  console.log(`🎯 Shared games count: ${sharedAppIds.length}`);

  const results = [];

  for (const { appid, games } of sharedAppIds) {
    const meta = await getAppDetails(appid);
    if (!meta) {
      console.warn(`⚠️ Skipping ${appid} — no metadata in cache`);
      continue;
    }

    console.log(`📦 Checking ${meta.name} (${appid})`);

    if (!meta.isMultiplayer) {
      console.log(`❌ Not multiplayer: ${meta.name} | Tags: ${meta.categories?.join(', ') || 'n/a'}`);
      continue;
    }

    const playtime = games.reduce((sum, g) => sum + (g.playtime_forever || 0), 0);
    const enriched = {
      ...meta,
      playtime_forever: playtime,
      estimatedSizeGB: meta.estimatedSizeGB ?? Math.floor(Math.random() * 40) + 5
    };

    const matchesGenres = !genreFilter.length || enriched.genres.some(g => genreFilter.includes(g.toLowerCase()));
    const matchesYear = enriched.releaseYear && enriched.releaseYear >= minYear && enriched.releaseYear <= maxYear;
    const matchesCoop = !coopOnly || enriched.isCoop;
    const matchesVersus = !versusOnly || enriched.isVersus;
    const matchesSize = enriched.estimatedSizeGB >= minSize && enriched.estimatedSizeGB <= maxSize;

    // Log filter results per game
    console.log(`🧪 Filters for ${enriched.name} → genres=${matchesGenres}, year=${matchesYear}, coop=${matchesCoop}, versus=${matchesVersus}, size=${matchesSize}`);

    if (matchesGenres && matchesYear && matchesCoop && matchesVersus && matchesSize) {
      console.log(`✅ MATCHED: ${enriched.name}`);
      results.push(enriched);
    }

    if (results.length >= matchLimit) break;
  }

  function shuffle(arr) {
    for (let i = arr.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [arr[i], arr[j]] = [arr[j], arr[i]];
    }
    return arr;
  }

  res.json({ results: shuffle(results) });
});



app.get('/api/quick-match', async (req, res) => {
  const me = req.query.me;
  const friend = req.query.friend;
  if (!me || !friend) return res.status(400).json({ error: 'Missing user or friend ID' });

  try {
    const [myGames, friendGames] = await Promise.all([
      getOwnedGames(me),
      getOwnedGames(friend)
    ]);

    const myAppIds = new Set(myGames.map(g => g.appid));
    const shared = friendGames.filter(g => myAppIds.has(g.appid));

    const multiplayerGames = [];

    for (const g of shared) {
      const meta = await getAppDetails(g.appid);
      if (meta && isGameActuallyMultiplayer(meta)) {
        multiplayerGames.push({
          name: meta.name,
          header: meta.header_image,
          appid: g.appid,
        });
      }
    }

    if (multiplayerGames.length === 0) {
      return res.json({ result: null });
    }

    const shuffled = multiplayerGames.sort(() => Math.random() - 0.5);
    return res.json({ result: shuffled[0] });
  } catch (err) {
    console.error("❌ Quick match error:", err);
    return res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Serve Flutter web app for root route
app.get('/', (req, res) => {
  const indexPath = path.join(__dirname, 'web', 'index.html');
  if (fs.existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    res.status(404).send('Web app not found - run flutter build web first');
  }
});

// Handle Flutter web app routes (catch-all for non-API routes)
app.use((req, res, next) => {
  // Don't serve index.html for API routes
  if (req.path.startsWith('/api') || req.path.startsWith('/auth')) {
    return next(); // Let it fall through to 404
  }
  
  const indexPath = path.join(__dirname, 'web', 'index.html');
  if (fs.existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    res.status(404).send('Web app not found - run flutter build web first');
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 LIVE API + WEB SERVER at ${renderUrl}`);
});
