# Локальная AI-платформа — материалы

| Файл | Назначение |
|------|------------|
| [PLATFORM_SPECIFICATION.md](./PLATFORM_SPECIFICATION.md) | Полная спецификация (23 раздела) |
| [PLATFORM_PRESENTATION.md](./PLATFORM_PRESENTATION.md) | Презентация для CTO / технической команды |
| [PLATFORM_PRESENTATION.pptx](./PLATFORM_PRESENTATION.pptx) | PowerPoint — техническая версия |
| [PLATFORM_PRESENTATION.pdf](./PLATFORM_PRESENTATION.pdf) | PDF — техническая версия |
| [PLATFORM_PRESENTATION_CEO.md](./PLATFORM_PRESENTATION_CEO.md) | **Презентация для CEO** (бизнес-фокус) |
| [PLATFORM_PRESENTATION_CEO.pptx](./PLATFORM_PRESENTATION_CEO.pptx) | **PowerPoint для руководства** |
| [PLATFORM_PRESENTATION_CEO.pdf](./PLATFORM_PRESENTATION_CEO.pdf) | **PDF для руководства** |

## Какую презентацию использовать

| Аудитория | Файл | Слайдов | Фокус |
|-----------|------|---------|-------|
| **CEO, инвестор** | `PLATFORM_PRESENTATION_CEO.pptx` | 14 | ROI, IP, риски, решение |
| **CTO, platform owner** | `PLATFORM_PRESENTATION.pptx` | ~38 | Архитектура, стек, внедрение |
| **Глубокое изучение** | `PLATFORM_SPECIFICATION.md` | — | Полная спецификация |

## Как открыть презентацию

### Вариант 1 — VS Code / Cursor (рекомендуется)

1. Установите расширение **Marp for VS Code** (`marp-team.marp-vscode`)
2. Откройте `PLATFORM_PRESENTATION.md`
3. Нажмите иконку предпросмотра Marp (или `Ctrl+Shift+P` → `Marp: Open Preview`)
4. Экспорт: `Ctrl+Shift+P` → **Marp: Export Slide Deck** → PDF или PPTX

### Вариант 2 — Marp CLI

```bash
npm install -g @marp-team/marp-cli
marp PLATFORM_PRESENTATION.md --pdf
marp PLATFORM_PRESENTATION.md --pptx
marp PLATFORM_PRESENTATION.md --html
```

### Вариант 3 — Онлайн

Скопируйте содержимое в [Marp Web](https://web.marp.app/) (без отправки на сервер, если открыть локально через расширение — предпочтительнее).

## Оформление

Корпоративный стиль: светлый фон, нейтральная палитра (slate/navy), без декоративных градиентов и badges. Ориентир — инженерный / управленческий доклад.

Предпросмотр: Marp в VS Code/Cursor. PPTX и PDF пересобираются из `PLATFORM_PRESENTATION.md`.

## Структура слайдов

~40 слайдов: резюме → архитектура → железо → слои (inference, модели, RAG, агенты, MCP, security) → люди → экономика → roadmap → go/no-go.
