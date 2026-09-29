# 22 — Roblox Edge Cases (глубоко)

Дополнение к `15-platforms-roblox.md`. То, на чём ломается «почти проф.» UI в Studio.

---

## ScreenGui & layering

| Issue | Professional fix |
|-------|------------------|
| Modal under HUD | Separate ScreenGui + DisplayOrder profiles (`hud < modal < toast < fx`) |
| ResetOnSpawn wipes UI | `ResetOnSpawn = false` on persistent guis |
| IgnoreGuiInset fights safe area | Either respect inset **or** Ignore + manual `safeTop` — не оба хаотично |
| Multiple roots React | One hud root; fx/toast imperative OK |
| CoreGui conflict | Don’t fight Roblox menu; leave escape paths |

---

## Text & fonts

| Issue | Fix |
|-------|-----|
| TextScaled everywhere | Kills hierarchy; use layout.text roles |
| GothamBlack missing expectation | Fallback weight; test on device |
| RichText injection | Sanitize; prefer plain for numbers |
| AutomaticSize surprise | Cap MaxSize; test locale strings |
| UIStroke on text as contrast | Prefer panel; stroke OK as support |

---

## Input

| Issue | Fix |
|-------|-----|
| Hover on phone | No hover-only state meaning |
| AutoButtonColor | Always false; own states |
| ProximityPrompt default skin | Custom Style + client chrome |
| Two prompts same part | Exclusivity / enable swap (roll vs buy) |
| Gamepad Selectable | Explicit; visible focus |
| Modal steals world prompts | Disable prompts or raise modal Active correctly |
| Drag vs click | Threshold; cancel press scale on drag-off |

---

## BillboardGui

| Issue | Fix |
|-------|-----|
| AlwaysOnTop smog | false for pets; true sparingly for stations |
| LightInfluence washes colors | 0 for UI cards |
| Clipping / MaxDistance pop | Fade by distance; hysteresis |
| Scale with camera | Size in offset; test FOV |
| Parent to moving part | Attach to stable adornee; update text not recreate |

---

## Performance & low-end

| Issue | Fix |
|-------|-----|
| Recreating list rows every HUD sync | Diff by id; spring numbers only |
| UIGradient + blur stacks | Limit; solid fills cheaper |
| Heartbeat UI | Event-driven; throttle |
| Huge PNG shadows | 9-slice small asset or no shadow |
| Particle on every click | Cap + reduce motion |

---

## Networking & authority

| Issue | Fix |
|-------|-----|
| Client shows buy success early | Pending → confirm from server; rollback on fail |
| Currency desync flicker | Authoritative value; spring toward it |
| Rapid click double buy | Debounce + server rate limit + disabled pending |

---

## Live Ops / soft launch

| Issue | Fix |
|-------|-----|
| A/B theme mid-session | Token swap + remount or controlled refresh |
| Translation late | String tables from day 1 keys |
| Portrait lock | Test both if unlocked; dock safe |

---

## Studio vs live

| Issue | Fix |
|-------|-----|
| Perfect monitor contrast | Test phone outdoor brightness |
| Play Solo only | Multiplayer billboards + steal prompts |
| Perfect 60fps desktop | Android mid-tier check |

---

## Quick quarantine list

Если видишь в PR:

1. `TextScaled = true` on HUD numeric  
2. Hardcoded `UDim2.new(0, 13, …)`  
3. `Color3.fromRGB` in component  
4. Default ProximityPrompt Style  
5. Modal in same ScreenGui as HUD without order plan  

→ reject до DoD.
