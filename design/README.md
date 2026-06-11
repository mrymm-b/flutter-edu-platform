# Handoff: Arab BH — Visual Redesign + Light/Dark Theme

> ملاحظة سريعة (للمستخدم): هذي الحزمة تعطيها لـ **Claude Code** داخل مشروع تطبيق Flutter حقّك.
> قل له: "نفّذ الثيم والتصميم الموجود في هذا المجلد على التطبيق الحالي، التزم بالـ tokens والمواصفات، ولا تغيّر الوظائف أو التنقّل."
> ملفات الـ HTML هنا **مراجع تصميم فقط** — المطلوب إعادة بناء نفس الشكل داخل Flutter، مو نسخ كود الـ HTML.

---

## Overview
A visual-only redesign of the **Arab BH** student platform (Arabic, RTL). It keeps all existing
functionality, navigation, content, and information architecture — only the **visual experience**
changes. The deliverable is a **dual theme**:

- **Light** — clean, calm, white surfaces; purple used sparingly as a brand accent.
- **Dark** — a premium **atmospheric midnight-indigo** environment (ambient violet lighting,
  layered glass surfaces, soft glows, gradients). Inspired by the *Syntra* / *Aura* reference mood —
  **not** a flat Material dark theme.

8 screens are covered: Welcome, Login, Sign-up, Home, Online Courses, My Content, Schedule, Profile.

## About the Design Files
The files in this bundle are **design references created in HTML/CSS/React (Babel)** — prototypes that
demonstrate the intended look, theming, and component styling. They are **not** production code to copy.
The task is to **recreate these designs in the existing Flutter app**, using its established widgets,
navigation, state, and data — applying the tokens and component specs below. Where the app already has a
screen/route, restyle it; do not rebuild flows or change routes.

## Fidelity
**High-fidelity.** Final colors, typography, spacing, radii, shadows, gradients, and theming are
specified. Recreate pixel-faithfully using Flutter's theming system (`ThemeData` light/dark + a shared
token file). Keep RTL (`Directionality.rtl`) and the Arabic copy exactly as written.

---

## Design Tokens

### Typography
- **Family:** `IBM Plex Sans Arabic` (weights 300/400/500/600/700). Add to `pubspec.yaml` (or
  `google_fonts: GoogleFonts.ibmPlexSansArabic`). Apply app-wide; RTL.
- **Scale (px → logical):**
  | Role | Size | Weight | Notes |
  |---|---|---|---|
  | Screen title (H1) | 22–26 | 700 | letter-spacing ≈ -0.3 |
  | App-bar title | 18 | 700 | |
  | Card title | 14.5 | 600 | |
  | Section label | 13 | 600 | |
  | Section label (muted) | 11.5 | 600 | color = muted, letter-spacing .4 |
  | Body / subtitle | 13–13.5 | 400 | color = muted |
  | Meta / caption | 11–12 | 500 | color = muted/faint |
  | Button | 14.5 | 600 | |
  | Price numeral | 19 | 700 | color = accent |

### Radii
`sm 12 · md 16 · lg 20 · pill 999`. Inputs 14, buttons 14 (small 12), cards 16, chips/pills 999.

### Spacing
Base rhythm 4px. Screen horizontal padding **18** (light "Quiet") / 16 (denser screens).
Section gaps ~24–26. Card inner padding 14–16. Gaps between cards 11–12.

### Colors — LIGHT  (`:root`)
| Token | Hex | Use |
|---|---|---|
| accent | `#5B54C2` | primary buttons, active states |
| accent-press | `#4A44A6` | pressed |
| accent-fg | `#564FB8` | purple text/icon on light |
| accent-tint | `#ECEBFA` | selected/active soft bg, badges |
| accent-line | `#D8D5F2` | focus ring / accent borders |
| ink | `#16151D` | primary text |
| ink-2 | `#3C3B47` | secondary text |
| muted | `#79767F` | tertiary text |
| faint | `#AAA8B3` | placeholders, hints |
| line | `#ECEBF0` | hairlines / borders |
| line-2 | `#F4F3F7` | dividers |
| bg | `#FFFFFF` | page background |
| bg-2 | `#F7F7FB` | input fill, inset surfaces |
| card | `#FFFFFF` | cards (separated by border + shadow) |
| shadow-card | `0 1px 2px rgba(24,22,45,.04)` | resting card |

**Light rule:** purple appears ONLY on primary buttons, active chips/segmented tabs, progress, active
nav, and key actions. No large purple surfaces, no gradients on backgrounds.

### Colors — DARK  (`.theme-dark`)  — *atmospheric*
| Token | Value | Use |
|---|---|---|
| accent | `#7E5BF0` | primary / active (same violet family, richer) |
| accent-press | `#6B49E0` | pressed |
| accent-fg | `#BBA9FF` | violet text/icon on dark |
| accent-tint | `rgba(126,91,240,.22)` | active soft bg / badges |
| accent-line | `rgba(150,120,255,.42)` | accent borders |
| ink | `#F3F1FB` | primary text |
| ink-2 | `#CFC9E2` | secondary text |
| muted | `#9A93B5` | tertiary (violet-gray) |
| faint | `#6E6890` | placeholders |
| line | `rgba(255,255,255,.09)` | hairlines |
| line-2 | `rgba(255,255,255,.05)` | dividers |
| bg (base) | `#16122A` | deepest indigo (fallback) |
| bg-2 | `#221C39` | input fallback |
| card (token) | `#241E3C` | card fallback color |

#### Ambient background (the "environment") — apply behind EVERY dark screen
A deep indigo gradient with three soft violet light blooms (radial). In Flutter, render as a full-screen
`Stack` background: a base `LinearGradient` + 2–3 `RadialGradient` glow layers (or `Container`s with
radial gradients / large blurred circles), content layered on top.

```
/* CSS recipe (translate to Flutter gradients) */
background:
  radial-gradient(135% 55% at 50% -8%,  rgba(139,92,246,.32), transparent 62%),  /* top center bloom */
  radial-gradient( 90% 45% at 110% 4%,  rgba(99,80,224,.22),  transparent 55%),  /* top-right bloom  */
  radial-gradient( 80% 52% at -12% 24%, rgba(168,96,236,.14), transparent 55%),  /* left bloom       */
  linear-gradient(180deg, #1C1737 0%, #16122A 46%, #110D20 100%);                /* deep indigo base */
```
Flutter mapping: one `Container(decoration: BoxDecoration(gradient: LinearGradient(...)))` for the base,
plus stacked `Positioned` `Container`s using `RadialGradient(colors:[violet.withOpacity(...), transparent])`
with a generous `radius`. The blooms are fixed to the screen (do not scroll); content scrolls above them.

#### Glass cards (dark) — depth + glow
Cards are translucent glass floating over the bloom, with a soft inner top-corner violet glow and soft
shadow. In Flutter: `BackdropFilter(ImageFilter.blur(16,16))` clipped to a rounded rect, fill with the
translucent gradient, add the border, the glow (a `Stack` child `RadialGradient` at top-corner), and the
shadow via `BoxShadow`.

```
/* dark .card */
background: linear-gradient(180deg, rgba(58,49,92,.80), rgba(40,33,66,.84));
border: 1px solid rgba(255,255,255,.085);
box-shadow: 0 16px 38px -14px rgba(0,0,0,.7), inset 0 1px 0 rgba(255,255,255,.09);
backdrop-filter: blur(16px) saturate(135%);
/* + inner glow overlay: radial-gradient(95% 130% at 100% -12%, rgba(150,116,250,.20), transparent 52%) */
```

#### Primary button (dark) — violet gradient + ambient glow
```
background: linear-gradient(180deg, #9168F5 0%, #7E5BF0 52%, #6A47E2 100%);
box-shadow: 0 12px 28px -8px rgba(126,91,240,.60), inset 0 1px 0 rgba(255,255,255,.28);
```
(Light primary = flat `#5B54C2`, no glow.)

#### Other dark treatments
- **Avatar** = glowing orb: `radial-gradient(120% 120% at 32% 22%, #9A78F6, #5B3FD0 72%)` +
  `box-shadow 0 10px 26px -6px rgba(126,91,240,.6)`.
- **Bottom nav** = frosted shelf: `rgba(20,15,38,.74)` + `blur(22px)`, top border `rgba(255,255,255,.08)`;
  active icon gets `drop-shadow(0 0 9px rgba(140,100,240,.7))`.
- **Chips / segmented active**, **FAB** = violet gradient `#8B62F2→#6E4BE6` + soft glow.
- **Inputs / search** = subtle glass `rgba(255,255,255,.045)` + `1px rgba(255,255,255,.10)`.
- **Badges** = `accent-tint` fill + `1px rgba(150,120,255,.25)` glowing edge.
- **Row icon tiles** = `rgba(255,255,255,.05)` glass, icon `#C7BAF4`.
- **Course/lesson thumbnails** = placeholder; in app use real cover images, rounded 14, with a subtle
  dark overlay so text stays legible.

**Dark rules:** no pure/OLED black, no neon, no large glowing halos. Glows are soft and low-alpha; depth
comes from layering (bloom → glass card → content) + soft shadows + hairline light borders.

---

## Components (shared across screens)
- **Button** — h50 (sm h42), radius 14/12, weight 600. `primary` (accent fill; dark = gradient+glow),
  `ghost` (card bg + line border, accent-fg text), `tonal` (accent-tint bg + accent-fg).
- **Input** — h52, radius 14, `bg-2` fill (dark = glass), `line` border; focus = accent-line border +
  3px accent-tint ring. Phone row = field + fixed 78px country-code box (`+973`, LTR).
- **Card** — `card` bg, 1px `line`, radius 16, `shadow-card` (dark = glass + glow, see above).
- **Row item** (list card) — 42px rounded icon tile + title/subtitle + leading chevron (RTL points left).
- **Chip** — pill, h34; active = accent fill (dark gradient+glow).
- **Segmented control** — track (card bg + line), 4px padding; active option = accent fill, radius 10.
- **Badge** — h22, radius 7; `blue` = accent-tint/accent-fg, `soft` = neutral.
- **Avatar** — circle, accent-tint bg + accent-fg initials (dark = glowing orb).
- **Bottom nav** — 5 items (right→left RTL order: حسابي · جدولي · دوراتي · الرسائل · الرئيسية), h66, icon
  22, label 10.5; active = accent-fg + filled icon (dark = glow). Icons: person, calendar, bookmark,
  chat, home.
- **Status bar** — h34, time (LTR) + wifi/signal/battery, color follows theme `ink`.
- **FAB** (Schedule) — pill, "إضافة مواد" + plus icon, accent (dark gradient+glow), floats bottom-start.
- **Progress bar** — h6, radius 99, track = line, fill = accent.

---

## Screens
RTL throughout. Exact Arabic copy below.

### 1. Welcome  (`WelcomeA`)
- **Purpose:** entry / brand splash.
- **Layout:** centered logo lockup "عرب BH" + tagline "منصة التعليم الشاملة" (thin rule on each side);
  bottom CTA group.
- **Components:** primary button "تسجيل الدخول"; ghost button "إنشاء حساب"; tiny legal line
  "بالمتابعة فإنك توافق على الشروط وسياسة الخصوصية".

### 2. Login  (`LoginA`)
- **Purpose:** phone sign-in.
- **Layout:** title block top → phone field → CTA → link.
- **Copy:** title "تسجيل الدخول"; subtitle "أهلاً بعودتك — تابع من حيث توقفت"; field label "رقم الهاتف";
  placeholder "3312 3456"; country code "+973"; button "دخول"; link "ليس لديك حساب؟ سجّل الآن".

### 3. Sign-up  (`SignupA`)  — scrollable
- **Copy:** title "إنشاء حساب"; subtitle "سجّل الآن وابدأ رحلتك التعليمية".
- **Fields:** "الاسم الكامل" (placeholder "أحمد محمد"); "رقم الهاتف" (+973 / "3312 3456");
  "المرحلة الدراسية" = select showing "الصف الحادي عشر" (chevron). Button "إنشاء الحساب";
  link "لديك حساب؟ سجّل دخولك".

### 4. Home  (`HomeA`)  — scrollable; bottom nav active = الرئيسية
- **Greeting row:** avatar "س" + "مرحباً،" / "سارة الطالبة"; trailing bell + cart (badge "4").
  *(No full-bleed colored header.)*
- **Search:** field "ابحث عن دورة أو ملزمة…".
- **Today (جدول اليوم):** label + "الأحد"; empty card "لا توجد حصص مدرسية اليوم" (dashed/quiet).
- **Continue (أكمل تعلّمك):** ONE card (merged) — thumbnail "رياضيات" + "رياضيات الصف الحادي عشر" /
  "أ. محمد المعلم"; progress bar; "دورة واحدة غير مكتملة" + "6% مكتمل"; primary small button "متابعة" (play).
- **Explore (استكشف):** quiet list card, monochrome row icons: "دورات أونلاين / شروحات مباشرة وتسجيلات";
  "الملازم / ملازم PDF للتحميل"; "دروس خصوصية / أونلاين · حضوري"; "مراجعات" + badge "قريباً".
  *(In dark, this is where ambient bloom + glass really show.)*

### 5. Online Courses  (`CoursesA`)  — scrollable; app-bar with back (chevron-right RTL) + cart
- **Header:** title "الدورات الأونلاين" / "شروحات مباشرة + تسجيلات".
- **Filter chips:** "الكل" (active) · "الفيزياء" · "الرياضيات".
- **Course card** (×2): thumbnail + title + subject + students meta (`users` icon) + price numeral
  (accent) "15"/"20" "د.ب"; actions row: add state — `tonal` "في السلة" (check) when added, else
  `primary` "أضف للسلة"; plus `ghost` "التفاصيل". Card 2 = "فيزياء متقدمة / موجات وكهرباء" + badge "جديد".

### 6. My Content  (`ContentA`)  — bottom nav active = دوراتي
- **Header:** "محتواي" / "دوراتك وملازمك في مكان واحد".
- **Segmented control:** "دوراتي" (active) · "ملازمي".
- **Course card:** badge "دورة أونلاين" + status "متابعة" (dot) + "رياضيات الصف الحادي عشر" /
  "أ. محمد المعلم"; actions: primary "التسجيلات" (play) + ghost "بث مباشر" (live icon).

### 7. Schedule  (`ScheduleA`)  — bottom nav active = جدولي
- **Header:** "جدولي الدراسي" + trailing trash/clear icon.
- **Day selector:** 5 equal-width pills (الأحد active · الاثنين · الثلاثاء · الأربعاء · الخميس).
  *(Must fit one row — use Expanded/Flexible, not a scrolling overflow.)*
- **Time grid:** hours 07:00–16:00 (LTR numerals on the start/right edge), hairline rows; events as
  accent-tinted blocks with a leading accent bar — sample: "رياضيات / أ. محمد المعلم" 09:00,
  "فيزياء / موجات وكهرباء" 13:00 (1.5h). Grid scrolls vertically.
- **FAB:** "إضافة مواد".

### 8. Profile  (`ProfileA`)  — scrollable; bottom nav active = حسابي
- **Identity:** large avatar "سا" (dark = glowing orb), name "سارة الطالبة", badge "الصف الحادي عشر",
  phone "+973 3310 0001".
- **Group "الحساب":** rows "تعديل الملف الشخصي" (pencil), "دوراتي ومشترياتي" (bag), "مظهر التطبيق" (palette).
- **Group "الدعم":** row "المساعدة والدعم" (help).
- **Footer:** ghost button "تسجيل الخروج".

---

## Theme behavior / implementation notes (Flutter)
- Build a **token file** (e.g. `app_theme.dart`) exposing the Light + Dark token sets above, and a
  `ThemeMode` toggle (the "مظهر التطبيق" profile row is the natural entry point).
- Dark mode is **not** just `Brightness.dark`: wrap each screen's `Scaffold` body in a reusable
  `AtmosphereBackground` widget (the gradient + bloom `Stack`) so every dark screen sits in the same
  environment. Make `Scaffold.backgroundColor` transparent over it.
- Implement a reusable `GlassCard` widget (BackdropFilter + translucent gradient + border + inner glow +
  shadow) used everywhere `.card` appears. In light mode it degrades to a plain white card + border.
- Keep all **navigation, routes, data, and business logic** from the current app. This is restyling only.
- Respect RTL and tabular/LTR numerals for phone numbers, prices, and clock times.

## Assets
- **Font:** IBM Plex Sans Arabic (Google Fonts).
- **Icons:** simple line icons (search, bell, cart, play, chevrons, doc, person, calendar, bookmark,
  chat, home, pencil, bag, palette, help, plus, trash, live, users, check). Use the app's existing icon
  set (e.g. `lucide`/`material`) — match these shapes.
- **Imagery:** course/lesson thumbnails are placeholders in the mocks → use real cover images in-app.
- No external brand assets beyond the "عرب BH" wordmark (text lockup).

## Files (design references in this bundle)
- `Arab BH - Light & Dark.html` — main canvas: every screen in **Light** + **Dark** side by side, plus a
  theme-system board. Open in a browser to inspect look/behavior.
- `arabbh.css` — **the source of truth for tokens, themes, and the dark atmosphere** (light `:root`,
  `.theme-dark` overrides, and the dark-atmosphere rules: glass cards, glows, ambient background).
- `shared.jsx` — icons, status bar, bottom nav.
- `screens-onboarding.jsx` — Welcome / Login / Sign-up.
- `screens-home.jsx` — Home (+ Thumb, Progress, Avatar, Greeting, SearchField).
- `screens-courses-content.jsx` — Online Courses + My Content.
- `screens-schedule-profile.jsx` — Schedule + Profile.
- `design-canvas.jsx` — presentation scaffold only (not part of the app design).

> Start from `arabbh.css` to extract exact values, and use `Arab BH - Light & Dark.html` to see them
> composed per screen in both themes.
