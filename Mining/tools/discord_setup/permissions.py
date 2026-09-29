# Permission overwrite helpers for Zeon Discord setup.

from __future__ import annotations

import discord

from zeon_config import ChannelSpec


def _perm(**kwargs: bool | None) -> discord.PermissionOverwrite:
    return discord.PermissionOverwrite(**kwargs)


async def apply_category_permissions(
    category: discord.CategoryChannel,
    preset: str,
    roles: dict[str, discord.Role],
) -> None:
    everyone = category.guild.default_role
    player = roles["player"]
    founder = roles["founder"]
    guard = roles["network_guard"]
    ops = roles["signal_ops"]

    if preset == "staff_private":
        pairs = [
            (everyone, _perm(view_channel=False)),
            (player, _perm(view_channel=False)),
            (ops, _perm(view_channel=True, send_messages=True)),
            (guard, _perm(view_channel=True, send_messages=True)),
            (founder, _perm(view_channel=True, send_messages=True)),
        ]
    elif preset == "bot_private":
        pairs = [
            (everyone, _perm(view_channel=False)),
            (player, _perm(view_channel=False)),
            (ops, _perm(view_channel=False)),
            (guard, _perm(view_channel=False)),
            (founder, _perm(view_channel=True, send_messages=True)),
        ]
    else:
        pairs = [
            (everyone, _perm(view_channel=False)),
            (player, _perm(view_channel=True)),
            (ops, _perm(view_channel=True)),
            (guard, _perm(view_channel=True)),
            (founder, _perm(view_channel=True)),
        ]

    for target, ow in pairs:
        await category.set_permissions(target, overwrite=ow)


async def apply_channel_permissions(
    channel: discord.abc.GuildChannel,
    preset: str,
    roles: dict[str, discord.Role],
) -> None:
    everyone = channel.guild.default_role
    player = roles["player"]
    founder = roles["founder"]
    guard = roles["network_guard"]
    ops = roles["signal_ops"]

    readonly_staff = _perm(
        view_channel=True,
        send_messages=True,
        manage_messages=True,
    )
    readonly_founder = _perm(view_channel=True, send_messages=True)

    if preset == "readonly_all":
        pairs = [
            (everyone, _perm(view_channel=True, send_messages=False, add_reactions=True)),
            (player, _perm(view_channel=True, send_messages=False, add_reactions=True)),
            (founder, readonly_founder),
            (guard, readonly_staff),
        ]
    elif preset == "announce":
        pairs = [
            (everyone, _perm(view_channel=False)),
            (player, _perm(view_channel=True, send_messages=False, add_reactions=True)),
            (ops, _perm(view_channel=True, send_messages=True)),
            (guard, readonly_staff),
            (founder, readonly_founder),
        ]
    elif preset == "chat_player":
        pairs = [
            (everyone, _perm(view_channel=False)),
            (player, _perm(view_channel=True, send_messages=True, attach_files=True, embed_links=True)),
            (guard, readonly_staff),
            (founder, readonly_founder),
        ]
    elif preset == "forum_player":
        pairs = [
            (everyone, _perm(view_channel=False)),
            (
                player,
                _perm(
                    view_channel=True,
                    send_messages=True,
                    create_public_threads=True,
                    send_messages_in_threads=True,
                    attach_files=True,
                    embed_links=True,
                ),
            ),
            (guard, readonly_staff),
            (founder, readonly_founder),
        ]
    elif preset == "staff_only":
        pairs = [
            (everyone, _perm(view_channel=False)),
            (player, _perm(view_channel=False)),
            (ops, _perm(view_channel=True, send_messages=True)),
            (guard, _perm(view_channel=True, send_messages=True)),
            (founder, readonly_founder),
        ]
    elif preset == "bot_log":
        pairs = [
            (everyone, _perm(view_channel=False)),
            (player, _perm(view_channel=False)),
            (founder, _perm(view_channel=True, send_messages=True)),
        ]
    elif preset == "voice_player":
        pairs = [
            (everyone, _perm(view_channel=False)),
            (player, _perm(view_channel=True, connect=True, speak=True)),
            (founder, _perm(view_channel=True, connect=True, speak=True, move_members=True)),
            (guard, _perm(view_channel=True, connect=True, speak=True, move_members=True)),
        ]
    else:
        return

    for target, ow in pairs:
        await channel.set_permissions(target, overwrite=ow)


async def create_channel(
    guild: discord.Guild,
    category: discord.CategoryChannel,
    spec: ChannelSpec,
) -> discord.abc.GuildChannel:
    if spec.kind == "forum":
        tags = []
        if spec.forum_tags:
            tags = [
                discord.ForumTag(name=name, moderated=False) for name in spec.forum_tags
            ]
        return await guild.create_forum(
            name=spec.name,
            category=category,
            topic=spec.topic or None,
            available_tags=tags,
            reason="Zeon setup bot",
        )
    if spec.kind == "voice":
        return await guild.create_voice_channel(
            name=spec.name,
            category=category,
            reason="Zeon setup bot",
        )
    return await guild.create_text_channel(
        name=spec.name,
        category=category,
        topic=spec.topic or None,
        reason="Zeon setup bot",
    )
