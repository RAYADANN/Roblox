# Zeon Network — Discord Setup Bot

One-shot bot that configures your Zeon Studio Discord server:
roles, categories, channels, permissions, rules & welcome messages.

## Prerequisites

- Python 3.10+
- Empty (or fresh) Discord server where you are **Owner**
- Discord Developer account

## 1. Create the bot

1. Open https://discord.com/developers/applications → **New Application** → name it `Zeon Setup`
2. **Bot** → **Reset Token** → copy token
3. **Bot** → enable **Server Members Intent** (for owner assignment)
4. **OAuth2 → URL Generator**:
   - Scopes: `bot`
   - Permissions: **Administrator** (needed once for setup)
5. Open the invite URL → add bot to your server

## 2. Configure

```bash
cd tools/discord_setup
copy .env.example .env    # Windows
# or: cp .env.example .env
```

Edit `.env`:

```env
DISCORD_BOT_TOKEN=paste_token_here
DISCORD_GUILD_ID=paste_server_id_here
FORCE_SETUP=0
```

**Server ID:** Discord Settings → Advanced → Developer Mode ON → right-click server → Copy Server ID.

## 3. Run

```bash
pip install -r requirements.txt
python setup_bot.py
```

The bot connects, sets up the server, prints progress, and exits.

If `Zeon Founder` role already exists, setup aborts (unless `FORCE_SETUP=1`).

## 4. After setup (manual, ~10 min)

### Community & onboarding

1. **Server Settings → Community** → Enable
2. **Onboarding**:
   - Default channels: `#rules`, `#welcome`, `#wanderer-lounge`
   - Question: grant role **Player** on accept
   - Optional: let users pick **World Alerts**, **Code Drops**

### Announcement channel

If `#network-alerts` is not an announcement channel:
**Edit Channel → Channel Type → Announcement** (after Community is on).

### Carl-bot (reaction roles)

1. Invite https://carl.gg with **Manage Roles**
2. Ensure Carl-bot's role is **below** colored roles but **above** Player
3. In `#welcome`, post reaction roles mapping:

| Emoji | Role |
|-------|------|
| 🧭 | Explorer |
| 💎 | Collector |
| ⚡ | Grinder |
| 💬 | Social |
| 🎨 | Creator |
| ⛏️ | World: Deep Digger |
| 🌐 | Multiverse |
| 📡 | World Alerts |
| 🎁 | Code Drops |
| 🛠️ | Dev Signals |
| 🎉 | Event Ping |
| 🔇 | No Pings |

4. **Automod** → spam filter, block foreign invite links
5. **Logging** → `#bot-mod-log`

### Wick (optional, 100+ members)

https://wickbot.com → anti-raid → log to `#bot-mod-log`

### Server profile

- Icon: `assets/zeon_studio_group_cover_universal.png`
- Banner: `assets/zeon_studio_cover_photo_1440x456.png`
- Description: *Different worlds. One network. Official Zeon Studio hub.*

## What gets created

### Roles (28)

Staff: Zeon Founder, Network Guard, Signal Ops  
Progression: Signal → Linked → Synced → Resonant → Core  
Archetypes: Explorer, Collector, Grinder, Social, Creator  
Worlds: World: Deep Digger, Multiverse  
Pings: World Alerts, Code Drops, Dev Signals, Event Ping, No Pings  
Rare: Void Walker, Nexus Guide, Dimension Artist, Founding Wanderer, Launch Crew  
Base: Player

### Channels

| Category | Channels |
|----------|----------|
| 📢 INFO | rules, welcome, network-alerts, code-drops, links |
| 🌌 ZEON NETWORK | wanderer-lounge, help, glitch-reports, signal-ideas, dimension-gallery |
| 🔧 STUDIO | dev-signals, polls |
| 🛡️ STAFF (private) | staff-chat, staff-triage, mod-actions |
| 🤖 BOT LOGS (private) | bot-mod-log |
| 🔊 VOICE | Wanderer Lounge, Grind Together |

## Security

- **Never commit `.env`** or share your bot token
- After setup, you can **kick the setup bot** or remove its Administrator permission
- Regenerate the token in Developer Portal if leaked

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `invalid bot token` | Reset token in Developer Portal, update `.env` |
| `bot is not in guild` | Re-invite bot with correct URL |
| `could not reorder roles` | Drag **Zeon Founder** above other roles manually |
| Channels duplicated | You ran with `FORCE_SETUP=1` on configured server — delete duplicates |
| Members see no channels | Grant **Player** role (onboarding or manually) |

## Files

| File | Purpose |
|------|---------|
| `setup_bot.py` | Entry point |
| `zeon_config.py` | Roles, channels, welcome text |
| `permissions.py` | Permission presets |
| `.env` | Your secrets (local only) |
