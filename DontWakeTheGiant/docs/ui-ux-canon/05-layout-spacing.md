# 05 — Layout, Spacing & Grid

«Кривой UI» чаще всего = **случайные отступы**, не плохой цвет.

---

## 8-point grid (индустриальный стандарт)

Material, Fluent, Carbon, большинство AAA UI kits:

**Между** компонентами: кратно **8** (8, 16, 24, 32, 40, 48, 64…).  
**Внутри** мелких контролов: допускается **4** (4, 8, 12, 16…).

| Token (пример) | px | Использование |
|----------------|----|---------------|
| `space.1` | 4 | Icon–label gap в chip |
| `space.2` | 8 | Плотный padding |
| `space.3` | 12 | Button inner (часто) |
| `space.4` | 16 | Card padding |
| `space.5` | 24 | Между секциями |
| `space.6` | 32 | Modal section break |
| `space.7` | 48 | Крупные блоки |

В starter: `theme.Design.PAD_SM/MD/LG` + `layout.gap()`.

**Запрет:** `UDim2` offset `7`, `13`, `15`, `22` без системной причины.

---

## Alignment & columns

- Выравнивай края колонок (иконки в один x).  
- Value-колонка справа — одинаковый right inset.  
- Optical alignment: иконки иногда сдвигают на 1px — редко и осознанно.

---

## Grouping (Gestalt)

1. **Proximity** — связанные ближе, чем к чужим.  
2. **Similarity** — одинаковые controls выглядят одинаково.  
3. **Common region** — панель/карточка = одна задача.  
4. **Continuity** — списки читаются сверху вниз без зигзага.

Один экран = **одна primary задача**. Вторичное — ниже или в tab.

---

## Safe areas & margins

| Платформа | Правило |
|-----------|---------|
| Phone | Уважай top inset / home bar; `IgnoreGuiInset` только осознанно + свой padding |
| Tablet | Не растягивай модалку на всю ширину — max width |
| Desktop | Не прижимай HUD к самому краю 0px |
| TV / console | ~5% overscan margin |

HUD density: на phone меньше элементов одновременно; структура меняется tier'ом, **размеры** — единым scale (`UI_ADAPTIVITY`).

---

## Touch targets

| | Минимум | Комфорт |
|--|---------|---------|
| Hit area | 44×44 | 48–56 |
| Gap между targets | ≥8 | ≥12 |

Visual control может быть 36px; hit pad — невидимый расширенный.

---

## Density modes (проф. опция)

- **Comfortable** — больше padding, крупнее type.  
- **Compact** — для veterans / landscape phone.

Меняй density токенами, не уникальным layout на каждый экран.

---

## Scrolling

- Lists: стабильная row height из шкалы.  
- Sticky header отделён stroke, не тенью-спамом.  
- Fade edges optional; не прячь CTA под скроллом без sticky footer.

---

## DoD layout

- [ ] Все spacing из шкалы  
- [ ] Группы по задаче  
- [ ] Hit ≥44  
- [ ] Safe area  
- [ ] Phone + desktop без ручных magic numbers
