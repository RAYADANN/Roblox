# 06 — Reject Gallery (ban list)

What makes B&R (or any sim) feel cheap. Enforce in review.

## Visual rejects
- Default Roblox ProximityPrompt style on shipped pads  
- Black / neon billboards on grass  
- Ink text floating without cream card outdoors  
- White labels on mid jade/sky/gold (fails contrast)  
- Fake multi-layer drop shadows on panels  
- Two filled primary CTAs same view  
- Odds smaller than creature name  
- Mixing arcade neon with parchment in one screen  
- Always-visible Dirt/Spikes chips outside Build  
- UIListLayout fighting accent bars (blank white cards)

## UX rejects
- Dead disabled button with no caption  
- Soft Speed / IAP-like CTA without price on face  
- Flickering full HUD remount every economy tick  
- Hatch celebration + duplicate toast  
- Dock with 6+ equal icons  
- Lock state only in memory (no pad/HUD cue) forever

## Process rejects
- New `Color3` outside ThemeColors  
- Hardcoded TextSize / Offset without `layout.*`  
- L7 ornament PNG spam before L1–L3 readable  
- “Polish” without screen-brief for new surface

## Current known offenders → fix in polish
1. `textMuted` AA fail  
2. OrnateButton white on jade/sky/primary/danger  
3. Soft Speed cost missing on CTA  
4. `cancelBreed` unused (add Cancel or remove dead API from UX expectation)
