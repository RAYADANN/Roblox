# 18 — Checklists & Definition of Done

Сначала отметь ступень: **[00-priority-ladder.md](./00-priority-ladder.md)**.  
Не требуй L7 items для L2-задачи.

---

## A. Foundations

- [ ] Verbs + failures записаны (screen brief)  
- [ ] Always / contextual / on-demand  
- [ ] Hierarchy ≤4  

## B. Visual system

- [ ] Semantic tokens only (theme sheet)  
- [ ] Contrast body ≥4.5:1; critical стремись ≥7:1  
- [ ] Не color-only  
- [ ] Type roles + scale  
- [ ] Spacing 8/4 · radius/stroke из tokens  

## C. Components

- [ ] States полный набор  
- [ ] Hit ≥44 (sim phone ≥48)  
- [ ] Instant press feedback  
- [ ] Empty/loading/error  

## D. Motion & audio

- [ ] Modal in/out  
- [ ] Reduce motion path  
- [ ] SFX vocabulary если звук есть  

## E. World UI

- [ ] Custom prompts + copy  
- [ ] Billboards = theme language  
- [ ] Edge cases 22 учтены  

## F. Genre

- [ ] Recipe 19 / playbook 20 применён  
- [ ] Flex typography верный  

## G. Platforms & code

- [ ] Phone + desktop  
- [ ] `useLayout` / нет magic sizes  
- [ ] `--!strict`, cleanup, ≤300 строк  
- [ ] `professional-ui.mdc`  

## H. Playtest (21)

- [ ] Scorecard заполнен  
- [ ] Top-3 fixes only записаны  
- [ ] Explicit non-goals на неделю  

---

## Вердикт

**Ship**, если для текущей ступени лестницы релевантные секции зелёные.  
Не блокируй loop орнаментом.
