# Zeon Network — Discord server layout (universal studio, not single-game).

from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

ChannelKind = Literal["text", "forum", "voice"]

MARKER_ROLE = "Zeon Founder"


def hex_color(value: str) -> int:
    return int(value.lstrip("#"), 16)


@dataclass(frozen=True)
class RoleSpec:
    key: str
    name: str
    color: int | None = None
    hoist: bool = False
    mentionable: bool = False
    # permission flag names for discord.Permissions
    perm_flags: tuple[str, ...] = ()


# Bottom → top in hierarchy (excluding @everyone and managed Bot role).
ROLE_SPECS: tuple[RoleSpec, ...] = (
    RoleSpec("player", "Player", color=hex_color("546E7A")),
    # pings — neutral gray, no hoist
    RoleSpec("no_pings", "No Pings", color=hex_color("607D8B")),
    RoleSpec("event_ping", "Event Ping", color=hex_color("607D8B"), mentionable=True),
    RoleSpec("dev_signals", "Dev Signals", color=hex_color("607D8B"), mentionable=True),
    RoleSpec("code_drops", "Code Drops", color=hex_color("607D8B"), mentionable=True),
    RoleSpec("world_alerts", "World Alerts", color=hex_color("607D8B"), mentionable=True),
    # worlds
    RoleSpec("world_dd", "World: Deep Digger", color=hex_color("8D6E63")),
    RoleSpec("multiverse", "Multiverse", color=hex_color("7E57C2")),
    # archetypes
    RoleSpec("creator", "Creator", color=hex_color("FF7043"), hoist=True),
    RoleSpec("social", "Social", color=hex_color("66BB6A"), hoist=True),
    RoleSpec("grinder", "Grinder", color=hex_color("FFD54F"), hoist=True),
    RoleSpec("collector", "Collector", color=hex_color("AB47BC"), hoist=True),
    RoleSpec("explorer", "Explorer", color=hex_color("4FC3F7"), hoist=True),
    # progression
    RoleSpec("signal", "Signal", color=hex_color("1A237E")),
    RoleSpec("linked", "Linked", color=hex_color("283593")),
    RoleSpec("synced", "Synced", color=hex_color("3949AB")),
    RoleSpec("resonant", "Resonant", color=hex_color("00ACC1")),
    RoleSpec("core", "Core", color=hex_color("00E5FF"), hoist=True),
    # rare / event
    RoleSpec("launch_crew", "Launch Crew", color=hex_color("FF4081")),
    RoleSpec("founding_wanderer", "Founding Wanderer", color=hex_color("E040FB"), hoist=True),
    RoleSpec("dimension_artist", "Dimension Artist", color=hex_color("EC407A")),
    RoleSpec("nexus_guide", "Nexus Guide", color=hex_color("26A69A")),
    RoleSpec("void_walker", "Void Walker", color=hex_color("5C6BC0")),
    # staff
    RoleSpec(
        "signal_ops",
        "Signal Ops",
        color=hex_color("78909C"),
        hoist=True,
        perm_flags=("manage_messages", "moderate_members"),
    ),
    RoleSpec(
        "network_guard",
        "Network Guard",
        color=hex_color("EF5350"),
        hoist=True,
        perm_flags=(
            "manage_messages",
            "moderate_members",
            "kick_members",
            "ban_members",
            "manage_threads",
        ),
    ),
    RoleSpec(
        "founder",
        MARKER_ROLE,
        color=hex_color("FFD700"),
        hoist=True,
        mentionable=True,
        perm_flags=("administrator",),
    ),
)


@dataclass(frozen=True)
class ChannelSpec:
    name: str
    kind: ChannelKind
    topic: str = ""
    forum_tags: tuple[str, ...] = ()
    # permission preset name
    preset: str = "chat_player"


@dataclass(frozen=True)
class CategorySpec:
    name: str
    channels: tuple[ChannelSpec, ...]
    preset: str = "public_player"


CATEGORIES: tuple[CategorySpec, ...] = (
    CategorySpec(
        "📢 INFO",
        (
            ChannelSpec("rules", "text", topic="Server rules. Read before chatting.", preset="readonly_all"),
            ChannelSpec("welcome", "text", topic="Start here — pick your path & pings.", preset="readonly_all"),
            ChannelSpec(
                "network-alerts",
                "text",
                topic="Official Zeon Studio news. Pings: @World Alerts",
                preset="announce",
            ),
            ChannelSpec(
                "code-drops",
                "text",
                topic="Promo codes for all Zeon worlds. Pings: @Code Drops",
                preset="announce",
            ),
            ChannelSpec("links", "text", topic="Games, Roblox group, socials.", preset="announce"),
        ),
        preset="public_player",
    ),
    CategorySpec(
        "🌌 ZEON NETWORK",
        (
            ChannelSpec("wanderer-lounge", "text", topic="General chat for all Wanderers.", preset="chat_player"),
            ChannelSpec("help", "text", topic="Questions about any Zeon game.", preset="chat_player"),
            ChannelSpec(
                "glitch-reports",
                "forum",
                topic="One bug = one post. Platform + steps + screenshot.",
                preset="forum_player",
                forum_tags=("Critical", "Visual", "Mobile", "Fixed"),
            ),
            ChannelSpec(
                "signal-ideas",
                "forum",
                topic="Feature ideas for any Zeon world. Vote with reactions.",
                preset="forum_player",
                forum_tags=("Gameplay", "UI", "Balance", "Accepted"),
            ),
            ChannelSpec(
                "dimension-gallery",
                "text",
                topic="Screenshots, clips, fan art from any Zeon game.",
                preset="chat_player",
            ),
        ),
    ),
    CategorySpec(
        "🔧 STUDIO",
        (
            ChannelSpec(
                "dev-signals",
                "text",
                topic="Behind the scenes — WIP, roadmap. Pings: @Dev Signals",
                preset="announce",
            ),
            ChannelSpec("polls", "text", topic="Community polls. React to vote.", preset="announce"),
        ),
    ),
    CategorySpec(
        "🛡️ STAFF",
        (
            ChannelSpec("staff-chat", "text", topic="Staff discussion only.", preset="staff_only"),
            ChannelSpec("staff-triage", "text", topic="Prioritize bugs & reports.", preset="staff_only"),
            ChannelSpec("mod-actions", "text", topic="Log: mute/ban/kick actions.", preset="staff_only"),
        ),
        preset="staff_private",
    ),
    CategorySpec(
        "🤖 BOT LOGS",
        (ChannelSpec("bot-mod-log", "text", topic="Carl-bot / Wick moderation logs.", preset="bot_log"),),
        preset="bot_private",
    ),
    CategorySpec(
        "🔊 VOICE",
        (
            ChannelSpec("Wanderer Lounge", "voice", preset="voice_player"),
            ChannelSpec("Grind Together", "voice", preset="voice_player"),
        ),
        preset="public_player",
    ),
)


RULES_TEXT = """\
**Zeon Network — Server Rules**

1. Be respectful — no insults, hate speech, or harassment.
2. No spam, ads for other servers/games, or scam links.
3. No cheats, exploits, or selling accounts/currency.
4. Post bugs in **#glitch-reports** (one bug = one post).
5. Only Zeon Studio posts real promo codes — ignore DM "giveaways".
6. English and other languages are welcome — stay civil.
7. Warn → mute → ban for repeat offenses.

*Different worlds. One network.*
"""


WELCOME_TEXT = """\
Welcome to the **Zeon Network** 🌌

You're a **Wanderer** between worlds built by Zeon Studio.
Pick your path, home world, and notification pings below.

**━━ PATH (who you are) ━━**
🧭 `Explorer` — discover new worlds & mechanics
💎 `Collector` — hunt rare finds & completions
⚡ `Grinder` — progress, ranks & leaderboards
💬 `Social` — events, help & community
🎨 `Creator` — ideas, art & feedback

**━━ HOME WORLD ━━**
⛏️ `World: Deep Digger` — current live world
🌐 `Multiverse` — I play everything Zeon makes

**━━ PINGS (optional) ━━**
📡 `World Alerts` — new games & major updates
🎁 `Code Drops` — promo codes
🛠️ `Dev Signals` — behind the scenes
🎉 `Event Ping` — events
🔇 `No Pings` — no notification roles

**Rank progression:** Signal → Linked → Synced → Resonant → Core
(Granted over time — stay active in the network!)

▶ Add **Carl-bot** and set up reaction roles on this message (see `tools/discord_setup/README.md`).
"""


CARL_BOT_HINT = """\
**After setup — add Carl-bot (https://carl.gg):**
1. Invite Carl-bot with Manage Roles.
2. In #welcome, run reaction roles for emojis above.
3. Point logging to **#bot-mod-log**.
4. Optional: Wick (https://wickbot.com) for anti-raid → **#bot-mod-log**.
"""
