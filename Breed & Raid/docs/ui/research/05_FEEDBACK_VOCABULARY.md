# 05 — Feedback Vocabulary

Action → visual → motion → SFX. One vocabulary for HUD and world.

| Action | Visual | Motion | SFX | Notes |
|--------|--------|--------|-----|-------|
| Button press | scale face | spring press 0.94–0.96, ≤100ms to feel | `click` | Optimistic before net |
| Button hover (desktop) | scale ~1.04 | snappy spring | — | Skip on touch |
| Collect success | jade flash near dock; float `+$N` | JuiceLayer shockwave + float 400–600ms | `collect` | Pulse Cash chip |
| Buy success | gold flash | FlashTween ~200ms | `buy` | Disable Buy until next roll |
| Buy / action fail | toast error | fade 2.2s | `fail` | Keep button enabled after |
| Roll preview land | pad + SUMMON update odds | no full-panel remount flicker | `click` optional | Throttle HUD sync |
| Hatch reveal | veil + slam title + odds | ~1.55s then clear | `hatch` | Suppress duplicate toast |
| Breed start | modal → incubating row | gentle | `click` | Billboard timer starts |
| Breed ready | billboard “Ready” | — | soft `hatch` or none | Open Breed prompt |
| Soft speed | CTA press | press spring | `buy` if paid | **Show cost on label** |
| Steal hold | progress on prompt | fill bar over HoldDuration | — | danger accent |
| Deposit hold | progress | 0.5s | `click` on complete | |
| Lock base | toast + prompt ObjectText | — | — | Optional HUD timer later |
| Number tick (cash) | digit spring | SPRING_NUMBER | — | ≤3 live springs |

## Timing budget
| Class | Target |
|-------|--------|
| Press acknowledge | ≤100ms |
| Success juice | 200–600ms peak |
| Hatch delight | ≤1.6s blocking |
| Toast | 2.2–2.5s |
| Idle chrome | no looping pulse (except optional Lock) |

## Sound bus
`BreedRaidUiBus` volume 0.55. Missing assets must no-op (already).

## Anti-patterns
- Every chip pulsing always  
- Hatch + error toast same second with same copy  
- Linear tweens for press (use spring)  
- SFX on hover
