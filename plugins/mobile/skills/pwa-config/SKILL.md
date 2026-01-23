# pwa-config

Progressive Web App configuration for Next.js applications.

## Contents

- Web App Manifest structure
- Service worker with Workbox
- Caching strategies
- Install prompt handling
- Offline page patterns

## Usage

Reference this skill when converting web apps to PWAs.

## Key Patterns

### Manifest
- name, short_name, description
- icons (192x192, 512x512)
- display: standalone
- theme_color, background_color

### Caching Strategies
- CacheFirst: images, fonts
- NetworkFirst: API calls
- StaleWhileRevalidate: CSS, JS

### next-pwa Configuration
- runtimeCaching array
- workbox options
- Development disable

### Install Prompt
- beforeinstallprompt event
- userChoice handling
- Install banner component

## Requirements

- HTTPS required
- Valid manifest
- Service worker registered
