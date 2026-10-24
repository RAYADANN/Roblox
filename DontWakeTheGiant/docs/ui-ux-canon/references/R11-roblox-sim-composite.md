# R11 — Roblox Discover sim (composite pattern)

**Study focus:** recurring structure of successful phone-first sims — **composite**, not one title to clone.

## Player task
Earn → spend → prestige in short sessions; understand pads in world.

## Recurring hierarchy
1. Top resource chips (cash/gems)  
2. World stations with prompts  
3. Bottom dock (sell/pets/shop/…)  
4. Popups for hatch/rebirth/FTUE  

## Why “good” ones feel expensive
- HUD and world pads share color language.  
- Numbers (multiplier, pets, depth) are large and formatted consistently.  
- Buy feedback instant; errors clear.  
- Dock limited; overflow in “More”.  
- Soft vs premium currency visually distinct.

## Why many feel cheap
- Default prompts + random UI kit.  
- Neon pads, black billboards.  
- 10+ dock icons.  
- Odds/text hierarchy inverted (name bigger than flex).  
- Shop dark patterns.

## Steal
- Parity ScreenGui ↔ world (`10`, `20`).  
- One primary flex typography rule.  
- Custom prompts + cream/dark cards with stroke.  
- FTUE one verb at a time.

## Do not copy
Specific hit game IP, UI kits, trademarked characters, or pay-to-win tricks that violate your GDD.
