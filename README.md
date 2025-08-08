# QUp! The Steam Mobile App 🎮

A full-stack mobile application that helps Steam users discover the best multiplayer games to play together based on shared game libraries, playtime, download size, and more.

This project consists of:

- 🟦 **Client/** — A Flutter-based mobile app with a modern Steam-style UI
- 🟨 **API/** — A Node.js backend that handles Steam OpenID login and game/friend data retrieval

---

## Features

✅ Steam OpenID login  
✅ View your friends and their owned games  
✅ Recommend multiplayer games based on:
- Playtime
- Shared ownership
- Download size (WIP)
- Install time (WIP)

✅ Deep linking integration (mobile)  
✅ Steam-style visuals for immersive UI

---

## Tech Stack

| Layer    | Technology                     |
|----------|--------------------------------|
| Client   | Flutter (Dart), WebView, REST  |
| Backend  | Node.js, Express, Steam Web API |
| Auth     | Steam OpenID via WebView       |
| Hosting  | Localhost or tunnel (Ngrok / LocalTunnel) |

---

## Setup Instructions

### 🔸 API (Node.js Backend)

```bash
cd API
npm install
node index.js
