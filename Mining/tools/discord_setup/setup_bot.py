#!/usr/bin/env python3
"""One-shot Discord server setup for Zeon Studio (Zeon Network theme).

Usage:
  1. Copy .env.example → .env and fill DISCORD_BOT_TOKEN + DISCORD_GUILD_ID
  2. pip install -r requirements.txt
  3. Invite bot: Administrator + Manage Roles + Manage Channels
  4. python setup_bot.py
"""

from __future__ import annotations

import asyncio
import os
import sys
from pathlib import Path

import discord
from dotenv import load_dotenv

from permissions import (
    apply_category_permissions,
    apply_channel_permissions,
    create_channel,
)
from zeon_config import (
    CARL_BOT_HINT,
    CATEGORIES,
    MARKER_ROLE,
    ROLE_SPECS,
    RULES_TEXT,
    WELCOME_TEXT,
)

load_dotenv(Path(__file__).resolve().parent / ".env")

TOKEN = os.getenv("DISCORD_BOT_TOKEN", "").strip()
GUILD_ID_RAW = os.getenv("DISCORD_GUILD_ID", "").strip()
FORCE = os.getenv("FORCE_SETUP", "0").strip() in ("1", "true", "True", "yes")


def _build_permissions(flags: tuple[str, ...]) -> discord.Permissions:
    if not flags:
        return discord.Permissions.none()
    return discord.Permissions(**{name: True for name in flags})


async def find_marker_role(guild: discord.Guild) -> discord.Role | None:
    return discord.utils.get(guild.roles, name=MARKER_ROLE)


async def create_roles(guild: discord.Guild) -> dict[str, discord.Role]:
    existing = {r.name: r for r in guild.roles}
    created: dict[str, discord.Role] = {}

    for spec in ROLE_SPECS:
        if spec.name in existing:
            created[spec.key] = existing[spec.name]
            print(f"  role exists: {spec.name}")
            continue
        perms = _build_permissions(spec.perm_flags)
        role = await guild.create_role(
            name=spec.name,
            colour=discord.Colour(spec.color) if spec.color else discord.Colour.default(),
            hoist=spec.hoist,
            mentionable=spec.mentionable,
            permissions=perms,
            reason="Zeon setup bot",
        )
        created[spec.key] = role
        print(f"  created role: {spec.name}")

    # fill any that existed before loop
    for spec in ROLE_SPECS:
        if spec.key not in created:
            created[spec.key] = existing[spec.name]

    return created


async def reorder_roles(guild: discord.Guild, roles: dict[str, discord.Role]) -> None:
    """Stack custom roles: Player (low) → Founder (high)."""
    ordered = [roles[spec.key] for spec in ROLE_SPECS if spec.key in roles]
    if not ordered:
        return
    try:
        await guild.edit_role_positions(positions=ordered, reason="Zeon setup bot")
        print("  role order updated")
    except discord.Forbidden:
        print("  WARN: could not reorder roles — move Zeon Founder to top manually")
    except discord.HTTPException as exc:
        print(f"  WARN: role reorder failed: {exc}")


async def setup_guild(guild: discord.Guild, owner: discord.Member | discord.User) -> None:
    print(f"Setting up guild: {guild.name} ({guild.id})")

    if await find_marker_role(guild) and not FORCE:
        print(
            f"\nERROR: '{MARKER_ROLE}' role already exists. "
            "Server may already be configured.\n"
            "Set FORCE_SETUP=1 in .env to run anyway (may duplicate channels).\n"
        )
        return

    print("\n[1/5] Creating roles...")
    roles = await create_roles(guild)
    await reorder_roles(guild, roles)

    print("\n[2/5] Creating categories & channels...")
    channel_map: dict[str, discord.abc.GuildChannel] = {}

    for cat_spec in CATEGORIES:
        category = await guild.create_category(name=cat_spec.name, reason="Zeon setup bot")
        await apply_category_permissions(category, cat_spec.preset, roles)
        print(f"  category: {cat_spec.name}")

        for ch_spec in cat_spec.channels:
            channel = await create_channel(guild, category, ch_spec)
            await apply_channel_permissions(channel, ch_spec.preset, roles)
            channel_map[ch_spec.name] = channel
            print(f"    channel: {ch_spec.name} ({ch_spec.kind})")

    print("\n[3/5] Posting rules & welcome...")
    rules_ch = channel_map.get("rules")
    welcome_ch = channel_map.get("welcome")
    alerts_ch = channel_map.get("network-alerts")

    if isinstance(rules_ch, discord.TextChannel):
        rules_msg = await rules_ch.send(RULES_TEXT)
        try:
            await rules_msg.pin()
        except discord.HTTPException:
            pass

    if isinstance(welcome_ch, discord.TextChannel):
        await welcome_ch.send(WELCOME_TEXT)
        await welcome_ch.send(CARL_BOT_HINT)

    # Try announcement channel type (requires Community enabled on server).
    if isinstance(alerts_ch, discord.TextChannel):
        try:
            await alerts_ch.edit(type=discord.ChannelType.news)
            print("  network-alerts set as announcement channel")
        except discord.HTTPException:
            print("  WARN: enable Community first, then convert #network-alerts to announcement")

    print("\n[4/5] Assigning roles to server owner...")
    founder_role = roles.get("founder")
    player_role = roles.get("player")
    signal_role = roles.get("signal")

    if isinstance(owner, discord.Member):
        if founder_role:
            await owner.add_roles(founder_role, reason="Zeon setup bot")
        if player_role:
            await owner.add_roles(player_role, reason="Zeon setup bot")
        if signal_role:
            await owner.add_roles(signal_role, reason="Zeon setup bot")
        print(f"  assigned Founder + Player + Signal → {owner.display_name}")

    print("\n[5/5] Community onboarding hint...")
    print(
        "  Enable Server Settings → Community → Onboarding:\n"
        "    • Default channel: #welcome\n"
        "    • Grant role on join: Player\n"
        "    • Optional questions: World Alerts, Code Drops\n"
    )

    print("\n✅ Zeon Network setup complete!")
    print("   Next: Server Settings → enable Community, set icon/banner,")
    print("   add Carl-bot reaction roles on #welcome, invite players.\n")


class SetupClient(discord.Client):
    def __init__(self, guild_id: int) -> None:
        intents = discord.Intents.default()
        intents.guilds = True
        intents.members = True
        super().__init__(intents=intents)
        self.guild_id = guild_id

    async def on_ready(self) -> None:
        guild = self.get_guild(self.guild_id)
        if guild is None:
            print(f"ERROR: bot is not in guild {self.guild_id}")
            await self.close()
            return

        owner = guild.owner
        if owner is None:
            owner = await guild.fetch_member(guild.owner_id)

        await setup_guild(guild, owner)
        await self.close()


def main() -> int:
    if not TOKEN or TOKEN == "your_bot_token_here":
        print("Set DISCORD_BOT_TOKEN in tools/discord_setup/.env")
        return 1
    if not GUILD_ID_RAW:
        print("Set DISCORD_GUILD_ID in tools/discord_setup/.env")
        return 1

    try:
        guild_id = int(GUILD_ID_RAW)
    except ValueError:
        print("DISCORD_GUILD_ID must be a numeric snowflake")
        return 1

    print("Zeon Studio — Discord Setup Bot")
    print("================================\n")

    client = SetupClient(guild_id)
    try:
        asyncio.run(client.start(TOKEN))
    except discord.LoginFailure:
        print("ERROR: invalid bot token")
        return 1
    except KeyboardInterrupt:
        print("\nCancelled.")
        return 130
    return 0


if __name__ == "__main__":
    sys.exit(main())
