##
## Build Flutter web
##
FROM ghcr.io/cirruslabs/flutter:stable AS flutter-build

WORKDIR /workspace

# Copy only what's needed first (better layer caching)
COPY Client/steam-mobile-client/pubspec.yaml Client/steam-mobile-client/pubspec.lock* ./Client/steam-mobile-client/
WORKDIR /workspace/Client/steam-mobile-client
RUN flutter pub get

# Copy the full Flutter project and build
WORKDIR /workspace
COPY Client/steam-mobile-client ./Client/steam-mobile-client
WORKDIR /workspace/Client/steam-mobile-client
RUN flutter build web --release

##
## Runtime: Node + static Flutter web assets
##
FROM node:20-bookworm-slim AS runtime

WORKDIR /app

# Install Node dependencies
COPY API/steam-auth-api/package.json API/steam-auth-api/package-lock.json* ./API/steam-auth-api/
WORKDIR /app/API/steam-auth-api
RUN npm install --omit=dev

# Copy API source
COPY API/steam-auth-api ./ 

# Replace the served web bundle with the fresh Flutter build
COPY --from=flutter-build /workspace/Client/steam-mobile-client/build/web ./web

ENV NODE_ENV=production
ENV PORT=10000
EXPOSE 10000

CMD ["node", "index.js"]

