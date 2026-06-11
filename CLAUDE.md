# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

# Mandatory Flutter Skills

For every task in this repository, automatically apply these skills before analysis, implementation, testing, or reporting.

## Required Skills

* Flutter App Architecture
* Flutter Testing
* Accessibility & Semantics
* Forms & Validation
* State Management (Riverpod)
* Supabase Integration
* Responsive UI
* Mobile App Design Review

## Rules

* Apply these skills by default.
* Do not wait for user instruction to use them.
* Use them during planning, implementation, debugging, refactoring, code review, and QA.
* Every code change must be evaluated through these skills.
* Every bug investigation must consider architecture, testing, validation, semantics, and backend integration.
* Every new feature must include validation, user feedback, loading states, and error handling.
* Every UI change must consider accessibility and responsive behavior.
* Every Supabase-related issue must include Auth, Storage, Database, and RLS verification.
* Every completed task must include testing and verification.
* Every UI screen must pass iOS HIG + Material 3 + accessibility audit before being reported complete.

These skills are mandatory project-wide standards.

---

## Required Skills — Detail

### 1. Flutter App Architecture
- Follow existing Riverpod architecture. Do not bypass providers.
- Preserve repository pattern. All Supabase calls go through providers, never directly from UI.

### 2. Flutter Testing
- Write or update Maestro flows for every behavior change.
- Verify fixes using real user flows, not just code inspection.
- Prefer E2E verification over unit tests for UI changes.

### 3. Accessibility & Semantics
- Add `Semantics(identifier: '...')` for all interactive widgets.
- Use stable IDs in Maestro flows (`tapOn: id:`), not visible text selectors.
- Naming convention: `screen_widget_purpose` (e.g. `booking_btn_confirm`).
- Icon-only buttons (no visible text) must also include `label: 'Arabic text'` so TalkBack/VoiceOver reads something meaningful. Buttons with text children don't need explicit labels — Flutter uses the child text automatically.
- Example: `Semantics(label: 'رجوع', identifier: 'booking_btn_back', child: GestureDetector(...))`

### 4. Forms & Validation
- Every form submission must provide user feedback (snackbar / toast).
- No silent failures — always show Arabic error messages on catch.
- All validation errors must have clear Arabic messages.

### 5. State Management (Riverpod)
- Use `ref.watch()` in build, `ref.read()` in callbacks.
- Always handle loading / error / data states in UI.
- Invalidate affected providers after any mutation.

### 6. Supabase Integration
- Verify Auth, Storage, and RLS policies before changing UI.
- Trace 403/RLS errors to backend config before touching Flutter code.
- Run duplicate-check queries before any INSERT on booking/purchase tables.

### 7. Responsive UI
- Use `MediaQuery.of(context).padding.top` for status bar spacing (SafeArea inside Scaffold body is a no-op for top padding).
- Test layout on different screen heights — avoid hardcoded heights where possible.
- RTL layout via `Directionality.rtl` — never assume LTR coordinates.

### 8. Mobile App Design Review

Apply both Apple HIG and Material 3 standards to every UI screen. Before implementing any UI change, audit the current screen across all five dimensions below and list issues before writing code.

#### iOS Review (Apple HIG)
- Safe areas respected (no content clipped by notch/status bar/home indicator)
- Dynamic Type supported — no hardcoded font sizes that break at large text settings
- Dark mode considered — colors use semantic values, not hardcoded hex
- Native navigation patterns — back gestures, modal presentation, tab bars
- Minimum 44×44pt touch targets on all interactive elements
- Accessibility compliance — VoiceOver labels, traits, ordering

#### Android Review (Material 3)
- Material 3 components used — FilledButton, OutlinedButton, InputChip, NavigationBar, etc.
- Material spacing system — 4dp grid, standard padding (16dp horizontal, 8/12/16/24dp vertical)
- Material navigation patterns — NavigationBar (bottom), NavigationDrawer, TopAppBar
- Android accessibility — TalkBack labels, content descriptions, focus order
- Adaptive layouts — handles different screen densities and sizes

#### Visual Design Review
- Visual hierarchy — clear primary/secondary/tertiary information levels
- Alignment — elements align to a consistent grid; no orphaned or misaligned widgets
- Consistency — same component used for same purpose across all screens
- Typography — one type scale; no random font sizes; weight used purposefully
- Color contrast — minimum 4.5:1 for body text, 3:1 for large text and UI components
- Empty states — every list/feed has a meaningful empty state with icon + message + CTA
- Error states — inline errors below fields; full-page errors with retry action
- Loading states — skeleton screens or progress indicators; never a blank screen
- Success states — confirmation feedback after every user action (snackbar / toast / animation)

#### UX Review
- User flow clarity — can a new user complete the flow without instruction?
- Validation feedback — errors shown immediately on blur, not only on submit
- Error prevention — destructive actions have confirmation dialogs
- User feedback after actions — every tap/submit produces visible feedback within 300ms
- Confirmation dialogs — used for delete, logout, cancel-with-unsaved-changes
- Form usability — correct keyboard type per field, autofocus on first field, submit on done

#### Accessibility Audit
- Screen reader support — all interactive elements have meaningful labels
- Semantics identifiers — `Semantics(identifier: 'screen_widget_purpose')` on all interactive widgets
- Keyboard/switch navigation — logical focus order, no focus traps
- Color contrast — verified for all text/background combinations
- Touch target sizing — minimum 48×48dp (Material) / 44×44pt (HIG) enforced

#### Design Review Protocol
Before implementing any UI change:
1. **Audit** — list every issue found across the 5 review areas above
2. **Prioritize** — P0 (crash/broken), P1 (accessibility), P2 (usability), P3 (polish)
3. **Implement** — fix P0 and P1 issues; propose P2/P3 to user
4. **Verify** — screenshot or Maestro flow confirms fix

Never approve a screen only because it works. Evaluate usability, accessibility, consistency, and visual quality.

### Before Reporting Completion
1. Run relevant Maestro flows (or full suite if behavior is broad).
2. Verify UI behavior visually (screenshot or Maestro assertion).
3. State the root cause of any bug fixed.
4. List all files changed.
5. Provide proof of successful execution (Maestro output / ADB file check).

---

## Project Overview

This is a Flutter-based educational platform connecting students with teachers.

### Key Features:

- **Student App**: Browse/purchase courses, attend live sessions, download books
- **Teacher Interface**: Upload content, conduct live sessions, manage students
- **Admin Dashboard**: User/content management (planned)
- **Live Streaming**: Agora SDK — integrated ✅
- **Payments**: Tap Payments — integrated ✅ (checkout UI + payment flow wired)
- **Real-time**: Chat and notifications via Supabase

### Tech Stack:

- Frontend: Flutter 3.x
- State Management: Riverpod
- Backend: Supabase (PostgreSQL + Storage + Auth)
- Live Streaming: Agora RTC SDK v6 (agora_rtc_engine ^6.3.2)
- Payments: Tap Payments API (Bahrain) — integrated in `checkout_screen.dart`

---

## Commands

All commands should be run from `my_app/`:

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Analyze/lint code
flutter analyze

# Format code
dart format .

# Build Android APK
flutter build apk

# Build Android App Bundle
flutter build appbundle
```

---

## E2E Testing (Maestro)

### Setup

Tests live in `.maestro/`. Maestro v2.6.0+ required.

```bash
# Run the full suite (from repo root, with Android emulator running)
maestro test .maestro/flows

# Run a single flow
maestro test .maestro/flows/05_student_schedule.yaml
```

### Coverage

**13 flows · 27 screens · 114 `Semantics.identifier` nodes**

| # | Flow | Scope |
|---|------|-------|
| 01 | Student — Login & Logout | WelcomePage → LoginPage → HomePage → logout |
| 02 | Student — Register page UI | RegisterPage form + back-to-welcome navigation |
| 03 | Student — Browse & cart | CategoryOnlinePage + CategoryBooksPage + add-to-cart |
| 04 | Student — My Courses & Books | MyCourses tabs, enrolled courses, purchased books |
| 05 | Student — Schedule | ScheduleScreen, add-sheet identifiers, delete-mode toggle |
| 06 | Student — Profile | Profile page actions, edit dialog, theme picker |
| 07 | Student — Chat | Chat list + StudentConversationDetail send |
| 08 | Student — Private lessons | PrivateLessonsPage + BookingCalendar |
| 09 | Teacher — Login | Login → TeacherHomePage assertion |
| 10 | Teacher — Home nav | Bottom nav tabs, live button visible |
| 11 | Teacher — Courses | Courses tab, Books tab, CourseMaterialsPage |
| 12 | Teacher — Chat | TeacherChatPage + ConversationDetail send |
| 13 | Teacher — Profile | Edit name dialog, cancel + confirm logout |

### How identifiers are added

Use `Semantics(identifier: 'screen_element_name')` wrapping the **interactive** widget:

```dart
// ✅ Correct — wraps GestureDetector or ElevatedButton
Semantics(
  identifier: 'home_btn_open_cart',
  child: GestureDetector(onTap: ..., child: ...),
)

// ✅ Correct — inside DecoratedBox, wrapping ElevatedButton
DecoratedBox(
  decoration: ...,
  child: Semantics(
    identifier: 'schedule_btn_save_all',
    child: ElevatedButton(onPressed: _save, ...),
  ),
)

// ❌ Wrong — wraps non-interactive DecoratedBox; ACTION_CLICK never fires
Semantics(
  identifier: 'foo',
  child: DecoratedBox(child: ElevatedButton(...)),
)
```

Naming convention: `screen_widget_purpose` (e.g. `teacher_profile_btn_logout`, `schedule_chip_day_7`).

### Known Maestro limitations

| Issue | Workaround |
|-------|-----------|
| `inputText:` on `textDirection: rtl` TextField → "Unknown error" | Skip text input in flows; use `tapOn: id:` only to verify identifier exists |
| `tapOn: id:` on buttons inside `DecoratedBox` sends `ACTION_CLICK` to Semantics node with no `onTap` — `onPressed` never fires | Use `tapOn: text:` (coordinate-based) **or** `pressKey: back` to dismiss sheets |
| `waitForAnimationToEnd` without timeout hangs forever on pages with continuous animations (teacher home pulsing live button) | Always add `timeout: 5000` to every `waitForAnimationToEnd` call |
| Arabic button text changes dynamically (e.g. "حفظ الكل · N حصة") — `tapOn: text:` may fail to match | Use `pressKey: back` to dismiss modal sheets instead of tapping save |

### Not covered by automation

- **OTP verification** — dev bypass (`loginWithPhone`) skips SMS entirely; real OTP needs a live Bahraini SIM
- **Agora live streaming** — requires physical camera; emulator has none
- **Tap Payments checkout** — opens external URL; outside Maestro's reach
- **Book download / recording playback** — requires real files in Supabase Storage

---

## Architecture

The app follows **Clean Architecture** with three layers:

### Layer 1: Domain (`lib/domain/models/`)

Plain Dart data classes with no business logic. Each model includes:

- `fromJson()` factory constructor
- `toJson()` method
- Helper getters where appropriate

**15 Models:**

- `user.dart` - User profiles (students, teachers, admin)
- `subject.dart` - Academic subjects (Arabic, Math, etc.)
- `course.dart` - Online courses
- `book.dart` - PDF materials
- `enrollment.dart` - Student course enrollments
- `book_purchase.dart` - Student book purchases
- `live_session.dart` - Live streaming sessions
- `message.dart` - Chat messages
- `conversation.dart` - Chat threads
- `payment.dart` - Payment transactions
- `cart_item.dart` - Shopping cart items
- `notification.dart` - User notifications
- `teacher_availability.dart` - Teacher schedule
- `private_lesson_booking.dart` - Private lesson bookings
- `schedule_item.dart` - Local school timetable entry (stored in SharedPreferences, not Supabase)

#### Model Parsing Notes:

- `User.fromJson` — `phone_verified` and `must_change_password` are nullable (`?? false`); `role` is `.toLowerCase().trim()` to guard against DB casing
- `Course.fromJson` — `is_active` and `students_count` are nullable (`?? true` / `?? 0`)
- Never use strict `as bool` or `as int` casts on Supabase fields — always use `as bool?` with a fallback
- `ScheduleItem` — local only; fields: `id`, `dayOfWeek` (1=Mon…7=Sun, matching `DateTime.weekday`), `time` ("HH:MM"), `endTime` ("HH:MM", optional `''`), `subject`; no Supabase table, persisted in SharedPreferences key `'student_schedule_v1'`

### Layer 2: Data (`lib/data/`)

Repository layer (currently empty; direct Supabase access in providers).

### Layer 3: Presentation (`lib/presentation/`)

#### **`providers/`** - Riverpod State Management

**14 Providers:**

1. **`auth_provider.dart`** - Authentication (real Supabase Phone OTP flow)
   - State: `user`, `isLoading`, `error`, `isAuthenticated`, `otpSent`, `pendingPhone`, `pendingName`, `pendingGrade`
   - **Login (2-step)**: `sendLoginOtp(phone)` → `signInWithOtp` → sets `otpSent: true`; `verifyLoginOtp(token)` → `verifyOTP` → queries `users` by phone → `isAuthenticated: true`
   - **Register (2-step)**: `sendRegisterOtp({phone, fullName, gradeLevel})` → duplicate check → `signInWithOtp` → sets `otpSent: true`; `verifyRegisterOtp(token)` → `verifyOTP` → inserts into `public.users` → `isAuthenticated: true`
   - `resendOtp()` — re-calls `signInWithOtp(pendingPhone)` silently
   - `_mapOtpError(message)` — maps Supabase `AuthException.message` to Arabic strings
   - Navigation driven by `ref.listen` on `otpSent` (false→true) in login/register pages; `isAuthenticated` transition in OTP page

2. **`subjects_provider.dart`** - FutureProvider — all active subjects

3. **`courses_provider.dart`**
   - `coursesProvider`, `coursesBySubjectProvider(id)`, `courseProvider(id)`

4. **`enrollments_provider.dart`**
   - `myEnrollmentsProvider`, `myCoursesProvider`, `isEnrolledProvider(id)`

5. **`books_provider.dart`**
   - `booksProvider`, `booksBySubjectProvider(id)`, `bookProvider(id)`

6. **`cart_provider.dart`** - StateNotifier
   - `loadCart()`, `addToCart()`, `removeFromCart()`, `clearCart()`
   - **`addToCart()` returns `Future<bool>`** — `true` on success, `false` on null user or Supabase exception
   - UI callers must read the return value to decide whether to show a success or error snackbar
   - `CartState.itemCount` is exposed so home page can show a badge

7. **`live_sessions_provider.dart`**
   - `liveSessionsProvider`, `liveSessionsByCourseProvider(id)`, `currentLiveSessionsProvider`, `upcomingLiveSessionsProvider`

8. **`messages_provider.dart`**
   - `myConversationsProvider`, `messagesProvider(id)`, `messagesStreamProvider(id)`, `messagesNotifierProvider`
   - `sendMessage` increments `unread_count_student` when teacher sends, `unread_count_teacher` when student sends

9. **`notifications_provider.dart`**
   - `myNotificationsProvider`, `unreadNotificationsCountProvider`, `notificationsStreamProvider`

10. **`book_purchases_provider.dart`**
    - `myBookPurchasesProvider`, `myPurchasedBooksProvider`, `isBookPurchasedProvider(id)`

11. **`private_lessons_provider.dart`**
    - `teacherAvailabilityProvider(subjectId)`, `myPrivateLessonBookingsProvider`, `teacherBookingsProvider`

12. **`teacher_provider.dart`**
    - `teacherCoursesProvider` - Teacher's own courses (filtered by `teacher_id`)
    - `teacherTotalStudentsProvider` - Sum of `students_count` across teacher's courses
    - `teacherCourseBooksProvider(courseId)` - Books filtered by `course_id`
    - `teacherCourseRecordingsProvider(courseId)` - Ended live sessions for a course
    - `teacherRecentSessionsProvider` - Last 3 ended sessions across all teacher courses (home feed)
    - `teacherUnreadCountProvider` - Total unread message count across all conversations
    - `studentNameProvider(userId)` - FutureProvider.family: resolves a user's full name from `users` table
    - `liveSessionNotifierProvider` (StateNotifier) - Start/end live sessions in Supabase
      - `LiveSessionState` fields: `isLive`, `sessionId`, `courseId`, `channelName`, `startSessionFailed`
      - `startSession()` — inserts `live_sessions` row; on failure sets `startSessionFailed: true` (does NOT throw)
      - `retryStartSession()` — clears `startSessionFailed` flag then calls `startSession()` again
      - `endSession()` — updates `status='ended'`, resets state to `const LiveSessionState()`
    - `liveSessionControllerProvider` (autoDispose.family, key = `LiveSessionKey`) - Agora engine lifecycle + phase state
      - `LiveSessionState` (controller's own class, separate from teacher provider's) — `phase`, `sessionId`, `micMuted`, `cameraOff`, `viewerCount`, `networkQuality`, `elapsedSeconds`, `isScreenSharing`, etc.
      - `setSessionId(String id)` — public method; called from UI retry banner after a manual DB re-insert succeeds

13. **`payment_provider.dart`**
    - `verifyAndFulfill(tapId, cartItems)` — writes `payments` row, upserts `enrollments` + `book_purchases`, clears cart, invalidates `myEnrollmentsProvider` / `myCoursesProvider` / `myPurchasedBooksProvider` / `myBookPurchasesProvider`

14. **`schedule_provider.dart`** - Local school timetable (SharedPreferences)
    - `ScheduleNotifier extends StateNotifier<List<ScheduleItem>>`
    - `add(ScheduleItem)` — single item; calls `_normalized()` (dedup by subject|day|time|endTime, sort by day then time); saves
    - `addMany(List<ScheduleItem>)` — multi-day add; same normalize + save
    - `remove(String id)` — removes by id; saves
    - `scheduleProvider = StateNotifierProvider<ScheduleNotifier, List<ScheduleItem>>`
    - `todayScheduleProvider = Provider<List<ScheduleItem>>` — **sync derived**, filters by `DateTime.now().weekday`, sorted by time; **⚠️ caching limitation**: Riverpod caches the result and only recomputes when `scheduleProvider` changes — `DateTime.now().weekday` is frozen from the last computation. `home_page.dart` bypasses this by filtering `scheduleProvider` inline in `build()` instead

#### **`screens/`** - UI Screens

**Shared (Auth):**

- ✅ `shared/welcome_page.dart` - Landing page — white background, Teams-purple gradient login button, outlined purple register button
- ✅ `shared/login_page.dart` - Phone login; clean centered layout on `_kBg` background; title "تسجيل الدخول" + subtitle "أهلاً بعودتك 👋"; calls `sendLoginOtp`; `ref.listen` on `otpSent` false→true pushes `OtpVerificationPage(isLogin: true)`
- ✅ `shared/otp_verification_page.dart` - Teams-purple OTP screen; 6-digit centered input with `letterSpacing: 12`; 60s countdown timer with "إعادة إرسال الرمز" button when expired; gradient "تحقق" button; `ref.listen` on `isAuthenticated` routes to `TeacherHomePage` or `HomePage`; accepts `isLogin` flag to call `verifyLoginOtp` vs `verifyRegisterOtp`
- ✅ `student/register_page.dart` - Student self-registration; calls `sendRegisterOtp`; `ref.listen` on `otpSent` false→true pushes `OtpVerificationPage(isLogin: false)`; clean centered layout matching login

**Student:**

- ✅ `student/home_page.dart` - Dashboard; `AtmosphereBackground` + `GlassCard` design system; `initState` calls `loadCart()` so cart badge is live; cart icon navigates to `CartScreen` with red count badge; `_TodayScheduleCard` — vertical list with 7-color pastel left borders; empty state: 🎉 + "لا توجد حصص اليوم" + "استمتع بوقتك أو أكمل الدورات المسجلة" in a `#F5F4FF` container; `_ContinueLearningCard` — **Half Accent** layout: 58px `accentFg` strip on the right (play icon + progress %) + white content area (course title, teacher name, progress bar, full-width "متابعة" button, `SizedBox(height: 122)`); `_BentoGrid` (2-row Bento): Row 1 (144px) = دورات أونلاين hero (`Color(0xFF4E4CA6)→0xFF7577BC` gradient, flex 2) + ملازم PDF (GlassCard, flex 1); Row 2 (115px) = دروس خصوصية + حاسبة المعدل ("قريباً" badge, shows toast); مراجعات removed entirely
- ✅ `student/my_courses.dart` - Enrolled courses + purchased books
- ✅ `student/category_online_page.dart` - Browse courses + add to cart; "التفاصيل" button navigates to `CourseDetailPage`; `addToCart()` return value checked — red snackbar on failure
- ✅ `student/category_books_page.dart` - Browse books + add to cart; new design system (Tok + GlassCard + AtmosphereBackground); `_BookCard` matches `_CourseCard` pattern: 48×48 `accentTint` icon tile, "ملزمة PDF" badge, "معاينة" secondary button + "أضف للسلة" / "إزالة من السلة" (red `0xFFEF4444`) toggle based on cart state, `PdfDownloadButton` when purchased; `addToCart()` bool-checked snackbar
- ✅ `student/course_detail.dart` - Course info + enrollment check
- ✅ `student/profile.dart` - User info, edit, logout; gradient header top padding uses `MediaQuery.of(context).padding.top` (not SafeArea) to fix status bar clipping; "الإعدادات" renamed to "مظهر التطبيق" (`Icons.palette_rounded`) → calls `_showThemePicker()` bottom sheet with 4 `kThemePresets` cards via `Consumer` for reactive updates
- ✅ `student/schedule_screen.dart` - **Personal school timetable** — now a **bottom-nav tab** (active index 3); no back button; weekly grid (Sun→Thu right-to-left in RTL, rendered LTR internally via `Directionality`); time axis 7:00–16:00 (64px/hour); subject cards absolutely positioned by `_topOf(time)` / `_heightOf(start,end)`; today column highlighted; red current-time indicator (`Timer.periodic` every minute); colorful 7-color pastel cards (`_kCardBg`/`_kCardFg`/`_kCardBorder`); delete mode: hint subtitle in header gradient (no separate pill banner), light × badge (11×11 white circle with red border) on each card; add sheet: `barrierColor: Colors.black.withValues(alpha: 0.32)`, multi-day `Set<int>` chip selection (`_kChipDays = [7,1,2,3,4]` = Sun→Thu) → `addMany()` creates one item per selected day; all stored in SharedPreferences via `scheduleProvider`; `_BottomNav` class included with `active: 3`
- ✅ `student/chat.dart` - Conversations list
- ✅ `student/private_lessons_page.dart` - Teacher list by subject; `AtmosphereBackground` + `GlassCard` design; flat `SafeArea` header (44×44 back button + title column); animated filter chips (`accentFg` selected, `bg2`/`line` unselected); `_TeacherCard`: 48×48 `accentTint` initial-letter avatar, "معلم" + subject badge, teacher name `w800`, price `accentFg w800`, days `faint`; divider + full-width `accentFg` "احجز الآن" button; loads ALL teachers on `initState` via multi-subject fetch; empty state: 80px `accentTint` circle + `event_busy` icon
- ✅ `student/booking_calendar_page.dart` - Private lesson booking; flat merged header (40×40 back + 36×36 avatar circle + title column + price badge); sections wrapped in `AnimatedSize(duration: 280ms)` for progressive disclosure; mode segmented row (حضوري=`accentTint`/`accentFg`, أونلاين=`accentFg`/white); day strip with unique Arabic abbreviations `['أحد','اثن','ثلا','أرب','خمي','جمع','سبت']`; `GridView(crossAxisCount:3, childAspectRatio:2.4, shrinkWrap:true, padding:zero)` for time slots; `_hoursLabel(h)` Arabic grammar (ساعة/ساعتان/3 ساعات); `_buildInlineSummary` label/value rows under "ملخص الحجز" header; sticky `Column` footer: `AnimatedSize` price row (30sp w900 `accentFg`) + full-width confirm button; Supabase duplicate-slot check before insert
- ✅ `student/online_course_view.dart` - Sessions list; tapping a live session launches `StudentLiveView`; tapping an ended session with `recording_url` generates a signed URL from the private `recordings` Supabase Storage bucket (1h TTL) and opens it via `launchUrl`; spinner shown in icon during URL fetch; errors shown as snackbar
- ✅ `student/student_live_view.dart` - **Agora audience viewer** — joins channel, shows teacher video, mute/leave controls
- ✅ `student/cart.dart` - Connected to `cartProvider`; Teams-purple theme; plain title header "سلة المشتريات" + dynamic item count (no gradient header); purple gradient footer pay button
- ✅ `student/checkout_screen.dart` - Tap Payments flow; Teams-purple theme; success screen with purple gradient; `_TapBadge` uses purple gradient
- ✅ `student/notifications_page.dart` - Notifications center; real-time stream via `notificationsStreamProvider`; tap-to-mark-read; swipe-to-delete via `Dismissible`; `markAllAsRead` header button; type-based icons (live/payment/message/announcement/course); relative Arabic timestamps; empty/error/loading states; bell icon in home header with unread badge (`unreadNotificationsCountProvider`)

**Teacher:**

- ✅ `teacher/teacher_home_page.dart` - Dashboard + bottom nav (IndexedStack host); real stats + activity feed
- ✅ `teacher/teacher_courses_page.dart` - Course list with Live/Content actions
- ✅ `teacher/live_session_page.dart` - **Agora broadcaster** — camera preview, mute/flip/end controls, viewer count; amber `_SessionInitFailedBanner` shown when Agora joins but Supabase insert fails (`startSessionFailed=true && sid==null`) — tap "إعادة المحاولة" to retry DB insert without restarting Agora; `_setupBroadcaster()` auto-retries `startSession()` once after 3 s on failure
- ✅ `teacher/course_materials_page.dart` - Books list (by course) + recordings; each ended session shows "رفع تسجيل" button if `recording_url == null`; teacher picks a video file → uploads binary to `recordings` bucket → updates `live_sessions.recording_url` → invalidates provider; "مسجّل" badge shown when `recording_url != null`
- ✅ `teacher/upload_material_page.dart` - Real PDF picker + Supabase Storage upload
- ✅ `teacher/teacher_chat_page.dart` - Conversations list with student names from DB
- ✅ `teacher/teacher_conversation_detail_page.dart` - Real-time message thread with student name in AppBar
- ✅ `teacher/teacher_profile_page.dart` - Profile, stats, edit name (saves to Supabase), logout

#### **`widgets/`** - Reusable Components

- **`atmosphere_background.dart`** — `AtmosphereBackground` widget. Light mode: `ColoredBox(AppTokens.lBg)` wrapper. Dark mode: deep indigo gradient + colour bloom overlays. Used as root background of all redesigned student screens.
- **`glass_card.dart`** — `GlassCard({padding, radius, lightColor?})`. Light mode: white card with `t.line` border (or `lightColor` if provided). Dark mode: translucent glass surface with border. Main card widget throughout the new UI.
- **`pdf_download_button.dart`** — `PdfDownloadButton({bookId, storagePath, t?})`. 4-state: idle → downloading (progress%) → downloaded (فتح PDF) → error. Signed URL from `books` bucket; saves to `getApplicationDocumentsDirectory()/books/{id}.pdf`; opens with `open_filex`.

### Core (`lib/core/config/`)

- **`supabase_config.dart`** - Supabase URL + anon key
- **`app_theme.dart`** - Colors, text styles, shadows (Cairo font, RTL)
- **`app_themes.dart`** - `AppThemePreset` class + `kThemePresets` list (4 presets: Teams-purple default, Ocean, Forest, Sunset)
- **`agora_config.dart`** - Agora App ID + `channelId(courseId)` helper + token constant
- **`tap_config.dart`** - Tap Payments API key + endpoint constants

### Theme System (`lib/presentation/providers/`)

- **`theme_provider.dart`** — `StateNotifierProvider<ThemeNotifier, int>` persisted in SharedPreferences key `'app_theme_index'`; `setTheme(int)` saves index and updates state; `themeProvider` consumed in `main.dart` (root `MaterialApp`) and in `_showThemePicker()` in `profile.dart`

---

## Agora Live Streaming

### Config (`lib/core/config/agora_config.dart`)

```dart
class AgoraConfig {
  static const String appId = 'YOUR_AGORA_APP_ID';
  static String channelId(String courseId) => courseId; // channel = course_id
  static const String token = ''; // no-token project (dev); add server token in prod
}
```

### Teacher (Broadcaster) — `live_session_page.dart`

1. Request camera + microphone permissions via `permission_handler`
2. `createAgoraRtcEngine()` → `initialize(appId, channelProfileLiveBroadcasting)`
3. `setClientRole(clientRoleBroadcaster)` → `enableVideo()` → `enableAudio()` → `startPreview()`
4. `joinChannel(token: '', channelId: courseId, uid: 0, options: ChannelMediaOptions(publishCamera + Mic = true))`
5. After join: calls `liveSessionNotifierProvider.startSession()` to insert `live_sessions` row and obtain `sessionId`
   - If insert fails: auto-retries once after 3 s; if retry also fails: `startSessionFailed=true` → amber banner shown
   - `sessionId` from both `liveSessionControllerProvider.state` and `liveSessionNotifierProvider` are OR'd together (`sid = ctrl.sid ?? teacher.sid`) so either source unblocks the secondary buttons
6. `onUserJoined/Offline` callbacks update viewer count
7. End: `stopPreview()` → `leaveChannel()` → `release()` → `liveSessionNotifierProvider.endSession()`

### Student (Audience) — `student_live_view.dart`

1. Request microphone permission (for audio routing)
2. Same init, but `setClientRole(clientRoleAudience)`
3. `joinChannel(options: ChannelMediaOptions(publishCamera + Mic = false, autoSubscribeAudio/Video = true))`
4. `onUserJoined` → set `_remoteUid` → render `AgoraVideoView.remote(uid: _remoteUid)`
5. Shows "waiting for teacher" until broadcaster joins
6. Controls: mute remote audio, leave channel

### Android Permissions (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
```

### iOS Permissions (`ios/Runner/Info.plist`)

`NSCameraUsageDescription` and `NSMicrophoneUsageDescription` already added.

> **iOS note:** When running `pod install` on macOS, ensure `platform :ios, '12.0'` is set in the Podfile (required by agora_rtc_engine v6).

### Token

Currently using no-token mode (empty string). Before production:

- Enable token authentication in the Agora Console
- Generate tokens server-side (Supabase Edge Function) and fetch before joining

---

## Database Schema (Supabase)

### Tables (15):

1. **users** - `id, phone, full_name, role, avatar_url, grade_level`
2. **subjects** - `id, name, name_ar, description, is_active`
3. **courses** - `id, subject_id, teacher_id, title, description, price, thumbnail_url, students_count, is_active`
4. **books** - `id, subject_id, teacher_id, course_id, title, price, pdf_url, pages_count, file_size, is_active, downloads_count`
5. **enrollments** - `id, student_id, course_id, enrolled_at, progress`
6. **book_purchases** - `id, student_id, book_id, purchased_at`
7. **live_sessions** - `id, course_id, teacher_id, title, status, scheduled_at, started_at, ended_at, agora_channel_name, viewers_count, duration_minutes`
8. **messages** - `id, conversation_id, sender_id, message, sent_at, is_read`
9. **conversations** - `id, student_id, teacher_id, last_message, last_message_at, unread_count_student, unread_count_teacher`
10. **payments** - `id, user_id, amount, status, tap_id, created_at`
11. **cart** - `id, user_id, item_type, course_id, book_id`
12. **announcements** - `id, course_id, title, content, created_at`
13. **notifications** - `id, user_id, title, message, type, is_read, sent_at`
14. **teacher_availability** - `id, teacher_id, subject_id, day_of_week, start_time, end_time`
15. **private_lesson_bookings** - `id, student_id, teacher_id, subject_id, booking_date, start_time, status, price`

### Storage Buckets (4):

- **avatars** (public), **course-thumbnails** (public), **books** (private), **recordings** (private)

### Row Level Security (RLS):

All tables have RLS enabled. **Required policies** (run in Supabase SQL Editor):

```sql
-- Allows unauthenticated clients to look up a user by phone (needed for login)
CREATE POLICY "anon_phone_lookup"
  ON public.users
  FOR SELECT
  TO anon
  USING (true);

-- Allows cart operations for all users (needed because auth.uid() from anonymous
-- session does NOT match user_id in the custom users table)
CREATE POLICY "allow_cart_all"
  ON public.cart
  FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- Allows teachers to create, update, and read their own live sessions.
-- users.id == supabaseUser.id == auth.uid() so this check is correct.
CREATE POLICY "teachers_can_manage_sessions"
  ON public.live_sessions
  FOR ALL
  TO authenticated
  USING (teacher_id = auth.uid())
  WITH CHECK (teacher_id = auth.uid());
```

Without `anon_phone_lookup`, `verifyLoginOtp` cannot query `users` by phone and returns "not found" even for existing users.
Without `allow_cart_all`, all `addToCart()` calls silently fail (insert rejected by RLS).
Without `teachers_can_manage_sessions`, `startSession()` silently fails → `sessionId` stays null → chat, participants, files, and recording buttons remain permanently disabled during live sessions.

---

## Authentication Flow

Real Supabase Phone OTP flow is active in `auth_provider.dart`.

### Login flow:
1. `LoginPage` — user enters digits only (e.g. `XXXXXXXX`); app prepends `+973`
2. `sendLoginOtp('+973XXXXXXXX')` → `_supabase.auth.signInWithOtp(phone:)` → state: `otpSent: true, pendingPhone`
3. `ref.listen` on `otpSent` false→true transition → pushes `OtpVerificationPage(isLogin: true)`
4. User enters 6-digit SMS code → `verifyLoginOtp(token)`
5. `_supabase.auth.verifyOTP(phone, token, OtpType.sms)` → queries `users` by phone → `User.fromJson`
6. State: `isAuthenticated: true, user` → `ref.listen` in OTP page routes: `isTeacher` → `TeacherHomePage`, else → `HomePage`
7. If phone not in `users` table: `auth.signOut()` + error "لم يتم العثور على حساب"

### Register flow:
1. `RegisterPage` — user enters name, digits, grade; app prepends `+973`
2. `sendRegisterOtp({phone, fullName, gradeLevel})` → duplicate check in `users` table → `signInWithOtp` → state: `otpSent: true` + pending data
3. Same `otpSent` transition → pushes `OtpVerificationPage(isLogin: false)`
4. User enters code → `verifyRegisterOtp(token)` → `verifyOTP` → inserts new row into `public.users` → `isAuthenticated: true`

### OTP error handling:
- `_mapOtpError(message)` maps Supabase `AuthException.message` to Arabic: invalid/expired → "رمز التحقق غير صحيح أو انتهت صلاحيته"; rate-limited → "تجاوزت الحد المسموح"
- 60-second resend countdown in `OtpVerificationPage`; `resendOtp()` re-sends silently

**Notes:**
- Phone format in DB: `+973XXXXXXXX` (Bahrain)
- Teachers created by admin only (no self-registration)
- RLS: `users` table needs `anon_phone_lookup` policy so `verifyLoginOtp` can query by phone post-OTP-verification

---

## Code Style & Conventions

- **Language**: Arabic for all UI text
- **Layout**: RTL via `Directionality.rtl`
- **Theme**: Both teacher and student pages use the **unified Teams-purple palette**. Teacher pages use `AppTheme` constants; student pages use inline `_kPurple` / `_kDark` / `_kBg` — both resolve to the same colors.
- **Font**: Cairo (set globally in theme)
- **Widgets**: `ConsumerWidget` / `ConsumerStatefulWidget` when using providers
- **Async**: always handle loading / error / data states
- **Actions**: `ref.watch()` in build, `ref.read()` in callbacks

### Container Color Rule:

**Never use both `color:` and `decoration:` on the same `Container`** — Flutter throws at runtime. Always put the color inside `BoxDecoration`:

```dart
// ✅ Correct
Container(
  decoration: BoxDecoration(color: Colors.white, border: ...),
)
// ❌ Wrong — runtime crash
Container(
  color: Colors.white,
  decoration: BoxDecoration(border: ...),
)
```

### Gradient Button Pattern:

`ElevatedButton` cannot have a gradient background via `backgroundColor`. Wrap it in `DecoratedBox`:

```dart
SizedBox(
  width: double.infinity,
  child: DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [_kDark, _kPurple],
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      onPressed: ...,
      child: ...,
    ),
  ),
),
```

This pattern is used everywhere: home, cart, checkout, login, register, welcome, booking, etc.

### Student Design Language — New Design System (2026-06):

Redesigned student screens use a **token-based design system** (`Tok` + `AppTokens`) with `AtmosphereBackground` and `GlassCard` as the primary layout primitives. This replaced the old Teams-purple gradient header approach.

#### Token Access

```dart
final t = Tok.of(context); // resolves to light or dark tokens from app_tokens.dart

// Key token fields:
t.isDark      // bool
t.bg          // page background
t.bg2         // card/surface background
t.ink         // primary text
t.ink2        // secondary text (lighter)
t.muted       // placeholder / secondary text
t.faint       // very light text / icons
t.line        // border / divider color
t.accentFg    // purple accent — buttons, active states, icons
t.accentTint  // light purple tint — icon backgrounds, chips, badges
t.accentLine  // subtle accent border
```

#### Layout Pattern

```dart
Scaffold(
  backgroundColor: Colors.transparent,
  body: AtmosphereBackground(
    child: Column(children: [
      SafeArea(bottom: false, child: /* flat header */),
      /* filter chips */,
      Expanded(child: /* content */),
    ]),
  ),
)
```

#### Card Pattern

```dart
GlassCard(
  padding: const EdgeInsets.all(14),
  radius: AppTokens.rLg,
  child: /* content using t.ink, t.muted, t.accentFg */,
)
```

#### Screens using the new design system:
`home_page.dart`, `my_courses.dart`, `category_online_page.dart`, `category_books_page.dart`, `chat.dart`, `profile.dart`, `private_lessons_page.dart`, `booking_calendar_page.dart`

#### Screens still using inline `_kPurple`/`_kDark`/`_kBg` constants (old approach):
`welcome_page.dart`, `login_page.dart`, `register_page.dart`, `cart.dart`, `checkout_screen.dart`, `otp_verification_page.dart`, `schedule_screen.dart`

#### Bento Grid Layout (home_page.dart)

```
Row 1 (144px): [دورات أونلاين hero — gradient, flex 2] [ملازم PDF — GlassCard, flex 1]
Row 2 (115px): [دروس خصوصية — GlassCard] [حاسبة المعدل — GlassCard + "قريباً" badge]
```

Hero cell: `gradient [Color(0xFF4E4CA6), Color(0xFF7577BC)]`, white text, play icon.
Secondary cells: `GlassCard`, 38×38 `accentTint` icon tile, `accentFg` icon size 20.

#### Half Accent Card Pattern (continue-learning card)

White `GlassCard(padding: EdgeInsets.zero)` + `SizedBox(height: 122)` + `ClipRRect`:
- **Right strip** (58px, `accentFg`): centered play icon + progress % + "مكتمل"
- **Left content** (`fromLTRB(12, 13, 20, 12)`): title → teacher → spacer → progress bar (`accentTint` bg) → full-width "متابعة" button

The 20px right physical padding prevents text from crowding the purple strip.

#### AppTokens Constants

```dart
AppTokens.screenPad   // 16 — horizontal page padding
AppTokens.rSm         // small border radius
AppTokens.rMd         // medium border radius
AppTokens.rLg         // large border radius
AppTokens.rPill       // pill/chip border radius
AppTokens.cardGap     // gap between cards
AppTokens.sectionGap  // gap between sections
AppTokens.tsCardT     // card title font size
AppTokens.tsAppBar    // app bar title font size
AppTokens.tsSecLbl    // section label font size
```

Bottom nav: white background, `t.accentFg` active with `Opacity(0.1)` pill highlight. **5 tabs**: الرئيسية(0) · الرسائل(1) · دوراتي(2) · جدولي(3) · حسابي(4).

### File Naming:

- Files: `snake_case.dart` | Classes: `PascalCase` | Variables: `camelCase`

---

## Current Progress

### ✅ Completed:

- All 14 domain models + 12 providers
- Full student flow: welcome → login/register → home → browse courses/books → course detail → cart → checkout → my courses → profile → chat
- Private lessons: browse teachers, booking calendar with Supabase save + duplicate-slot check
- **Teacher dashboard**: home (real stats + activity feed), courses list, live session (Agora), course materials, upload book (real Supabase Storage), chat + conversation detail (real-time), profile (edit saves to DB)
- **Live streaming (Agora)**: teacher broadcasts camera (broadcaster role), student watches (audience role), real viewer count, mute/flip/end controls
- **Role-based routing**: login routes teacher → `TeacherHomePage`, student → `HomePage`
- **All `color`+`decoration` Container conflicts resolved** across all files
- **Teacher runtime fixes**: DropdownButton AssertionError guard, null user guard in upload, `TextEditingController` dispose in profile dialog, message bubble corner radii corrected
- **`sendMessage` unread increment**: teacher reply increments `unread_count_student`; student reply increments `unread_count_teacher`
- **Student UX fixes (2026-05-05)**:
  - `profile.dart` — grade level chip now shows Arabic (e.g. "الصف الحادي عشر") via `_translateGrade()`
  - `chat.dart` — empty state replaced with icon + title + subtitle + "تصفح الدورات" CTA button → `CategoryOnlinePage`
  - `my_courses.dart` — cart icon removed from header; empty states for both tabs now have CTA buttons ("تصفح الدورات" / "تصفح الملازم")
  - `category_online_page.dart` — price shown as single widget; `studentsCount == 0` shows green "جديد" label
  - `home_page.dart` — "مراجعات" and "اختبارات" cards wrapped in `IgnorePointer` + `Opacity(0.5)` to disable interaction visually
  - `private_lessons_page.dart` — defaults to showing ALL teachers on load ("الكل" chip selected); "الكل" chip added; all-teacher list loaded in `initState`
- **Teacher UI redesign (2026-05-05)**:
  - `teacher_home_page.dart` — gradient header with embedded stats, animated bottom nav, live button, quick actions
  - `teacher_courses_page.dart` — added "دوراتي / ملازمي" tabs; "ملازمي" filters `booksProvider` by `teacherId`
  - `teacher_profile_page.dart` — gradient header with centered avatar + stats row; colored icon menu items; custom logout dialog
  - `teacher_chat_page.dart` — gradient header; conversation cards with green unread dot + purple badge
  - `course_materials_page.dart` — gradient header with back button; green upload CTA card; colored section headers
  - `upload_material_page.dart` — gradient header; styled form fields; animated file picker zone; gradient submit button
  - `teacher_conversation_detail_page.dart` — gradient header with student avatar; gradient message bubbles; gradient send button
- **Student UI redesign — Teams-purple (2026-05-06)**:
  - `home_page.dart` — Teams-purple gradient header with time-based greeting; colorful category grid cards; purple progress card for active course; Teams-style bottom nav with pill highlight
  - `my_courses.dart` — purple gradient header; purple tab bar; course cards with purple gradient strip; colored action buttons
  - `profile.dart` — full-width purple gradient header with centered avatar + grade badge; colored icon menu; updated dialogs with purple accents
  - `chat.dart` — purple gradient header; conversation cards with purple unread badge + green dot; purple empty-state CTA
  - `category_online_page.dart` — purple gradient header with back button + cart badge; purple filter chips; course cards with purple left border + colored add-to-cart button
- **Full Teams-purple rollout (2026-05-07)**:
  - `private_lessons_page.dart` — complete rewrite: purple gradient header, `AnimatedContainer` filter chips, teacher cards with 4px purple right border, purple gradient avatar initials, "احجز الآن" with `DecoratedBox` gradient button
  - `category_books_page.dart` — complete rewrite: purple gradient header with cart badge, purple filter chips, book cards with 4px purple right border, `addToCart()` bool-checked snackbar
  - `cart.dart` — connected to real `cartProvider` + Teams-purple theme: purple item type badge, course/book icon gradients, purple total price, `DecoratedBox` gradient pay button, purple empty-state circle
  - `checkout_screen.dart` — Teams-purple theme: purple gradient header, course icons purple / book icons green in order summary, `_TapBadge` uses purple gradient, success screen uses full purple gradient background, pending info box uses `_kPurple.withValues(alpha: 0.08)`
  - `welcome_page.dart` — white background preserved; login button changed to purple gradient via `DecoratedBox`; register button outlined purple
  - `login_page.dart` — complete rewrite: `_kBg` background, purple gradient header with `BorderRadius.only(bottomLeft/bottomRight: 32)`, white form fields with `_kPurple` focused border, purple gradient login button via `DecoratedBox`, no `AppTheme` references
  - `register_page.dart` — same structure as login: purple gradient header, white form fields, purple gradient register button, no `AppTheme` references
- **Cart wired to home page (2026-05-07)**:
  - `home_page.dart` `initState` uses `WidgetsBinding.instance.addPostFrameCallback` to call `loadCart()` so cart badge is populated immediately on login
  - Cart icon in header is a `GestureDetector` wrapping a `Stack` with a red `CircleAvatar` badge showing `cartProvider.itemCount`
  - Hero course card uses `dynamic` typing for `course` and `enrollment` params to avoid extra model imports; reads `myEnrollmentsProvider` to show real `progress` value; calls `studentNameProvider(course.teacherId)` for real teacher name
- **`addToCart()` returns `bool` (2026-05-07)**:
  - `cart_provider.dart`: signature changed from `Future<void>` to `Future<bool>`; returns `false` on null user or exception; returns `true` after successful insert + `loadCart()`
  - `category_online_page.dart` and `category_books_page.dart`: `await addToCart()` result stored in `ok`; green snackbar on `ok == true`, red snackbar on `ok == false`
- **Booking save wired (2026-05-07)**:
  - `booking_calendar_page.dart`: on confirm, queries `private_lesson_bookings` with `.neq('status', 'cancelled')` to check for existing booking in same slot; shows orange warning snackbar if duplicate; inserts new booking row on success
- **UX polish (2026-05-07)**:
  - `profile.dart`: "الإعدادات" → SnackBar "الإعدادات — قريباً"; "المساعدة والدعم" → "المساعدة — قريباً"; "عن التطبيق" → "منصة تعليمية — الإصدار 1.0.0"
  - `online_course_view.dart`: `onTap` made `async`; `launchUrl` return stored in `launched`; shows snackbar "تعذّر فتح رابط التسجيل" if `false`
  - `category_online_page.dart`: "التفاصيل" button navigates to `CourseDetailPage(courseId: course.id)`
- **Auth/cart screen header cleanup (2026-05-08)**:
  - `login_page.dart` — gradient header removed; replaced with title "تسجيل الدخول" (26sp bold dark right) + subtitle "أهلاً بعودتك 👋" (14sp muted); `DecoratedBox` gradient button restored (`_kDark` → `_kPurple`)
  - `register_page.dart` — gradient header + back button removed; title "إنشاء حساب" + subtitle "🚀"; body restructured to `SafeArea > Center > SingleChildScrollView > Column(mainAxisAlignment: center)` for vertical centering; `DecoratedBox` gradient button kept
  - `cart.dart` — gradient header removed; replaced with plain `Padding` block: title "سلة المشتريات" + dynamic `${cartState.itemCount} عناصر`; body wrapped in `SafeArea`
- **Status bar clipping fix (2026-05-08)**:
  - `profile.dart` + `private_lessons_page.dart` — `SafeArea(bottom: false)` inside Scaffold body is a no-op (Scaffold removes `padding.top` from body's MediaQuery); replaced with `EdgeInsets.fromLTRB(..., N + MediaQuery.of(context).padding.top, ...)` on the inner Padding directly
- **Personal school timetable (2026-05-19)**:
  - `schedule_item.dart` — new domain model: `id`, `dayOfWeek` (1–7), `time`, `endTime`, `subject`; no Supabase table; stored locally
  - `schedule_provider.dart` — complete rewrite: SharedPreferences JSON persistence (`'student_schedule_v1'`); `addMany()` for multi-day; `_normalized()` deduplicates + sorts; `todayScheduleProvider` is a **sync** `Provider` (not FutureProvider)
  - `schedule_screen.dart` — full weekly timetable grid: days الأحد–الخميس as columns, 7 AM–4 PM time axis, absolute-positioned subject cards, red current-time line, today column highlight, colorful 7-color pastel palette, long-press delete, multi-day add sheet
  - `home_page.dart` — switched to sync `todayScheduleProvider`; `_TodayScheduleCard` shows colorful 100×110px mini-cards; `_ScheduleLoadingCard` removed
- **Theme picker (2026-05-19)**:
  - `app_themes.dart` — `AppThemePreset` + `kThemePresets` (4 color presets)
  - `theme_provider.dart` — `StateNotifierProvider<int>` persisted via SharedPreferences
  - `profile.dart` — "الإعدادات" → "مظهر التطبيق" with palette icon; `_showThemePicker()` reactive bottom sheet with `Consumer` + 2×2 preset grid
- **`_TodayScheduleCard` redesign (2026-05-20)**:
  - Replaced absolute-positioned mini-timeline (`Stack + Positioned`) with a clean vertical list — fixes text overlap, cramping, and RTL misalignment
  - Each row: `[40px time label] | [Expanded card with colored left border]`; card uses `Directionality(rtl)` for subject text + `Directionality(ltr)` for time range
  - Per-subject color: `_kSchedBg[ci]` background + `_kSchedFg[ci]` text/border, `ci = subject.codeUnits.fold % 7` — matches schedule_screen.dart palette
  - Header: day name + "اليوم" badge only (class count removed)
  - `_parseTimeMin()` helper: numeric sort instead of string comparison
- **Bottom nav expanded to 5 tabs (2026-05-20)**:
  - New order: الرئيسية (0) · الرسائل (1) · دوراتي (2) · **جدولي (3)** · حسابي (4)
  - `schedule_screen.dart` — back button removed; `bottomNavigationBar: _BottomNav(active: 3)` added; `_BottomNav` class added to file with `themeProvider`-aware active color
  - Updated active indices: `my_courses.dart` → 2, `chat.dart` → 1, `profile.dart` → 4
  - All `_BottomNav._item()` horizontal padding reduced from 14→10 to fit 5 tabs
- **Today schedule filtering fix (2026-05-20)**:
  - `home_page.dart` — replaced `ref.watch(todayScheduleProvider)` with inline filter on `scheduleProvider`; `DateTime.now().weekday` now evaluated at build time on every widget mount; strict `dayOfWeek == DateTime.now().weekday` equality, numeric time sort via `_parseTimeMin()`
- **Design system unification (2026-06-04)**:
  - `app_theme.dart` — unified Teams-purple palette: `primaryBlue = 0xFF6264A7`, `darkBlue = 0xFF464775`, new `tintBg = 0xFFF0F0FA`, `tintBorder = 0xFFCDCEE8`, `background = 0xFFF3F2F1`, `headerGradient` constant
  - All teacher pages updated to use the unified palette (replacing the old blue `0xFF2563EB` / `0xFF1E3A5F` gradient): `teacher_home_page.dart`, `teacher_chat_page.dart`, `teacher_profile_page.dart`, `course_materials_page.dart`, `upload_material_page.dart`, `teacher_conversation_detail_page.dart`
  - `teacher_courses_page.dart` required no changes (already used `AppTheme` references which auto-updated)
- **E2E test suite — Maestro (2026-06-05)**:
  - 114 `Semantics.identifier` nodes added across 27 screens (all student + teacher screens)
  - 13 Maestro flows in `.maestro/flows/` covering all critical user paths
  - **13/13 flows passing** (15m 41s total) — zero failures
  - Subflows: `_login_student.yaml`, `_login_teacher.yaml`, `_logout.yaml`, `_teacher_course_materials.yaml`, `_teacher_open_conversation.yaml`
  - All `waitForAnimationToEnd` calls use `timeout: 5000` to handle teacher home's continuous pulsing animation
- **Live session secondary button fix (2026-06-04)**:
  - Root cause: `startSession()` Supabase insert was failing silently (RLS policy missing on `live_sessions`) → `sessionId` stayed null → chat, participants, files, recording buttons permanently disabled
  - `teacher_provider.dart` — added `startSessionFailed` field to `LiveSessionState`; set in catch block; added `retryStartSession()` method that clears the flag before retrying
  - `live_session_controller.dart` — `_setupBroadcaster()` now auto-retries `startSession()` once after 3 s if first attempt fails; added public `setSessionId(String id)` method for UI-triggered retry
  - `live_session_page.dart` — added amber `_SessionInitFailedBanner` widget (shown when `startSessionFailed && sid == null`); tap "إعادة المحاولة" to re-run DB insert without restarting Agora; removed all diagnostic code and hardcoded `disabled` values; cleaned up debug prints
- **PDF book download (2026-06-06)**:
  - `book_download_provider.dart` — `BookDownloadNotifier extends StateNotifier<Map<String, BookDownloadState>>`; 4-state enum: idle/downloading/downloaded/error; caches at `getApplicationDocumentsDirectory()/books/{bookId}.pdf`; generates signed URL from private `books` bucket; streams download with progress via `HttpClient`; opens with `open_filex`
  - `pdf_download_button.dart` — `ConsumerStatefulWidget`; green "تحميل PDF" → progress % → purple "فتح PDF" → red "إعادة المحاولة"; `ref.listen` for download/error toasts
  - `my_courses.dart` + `category_books_page.dart` — stub "قريباً" replaced with `PdfDownloadButton(bookId: book.id, storagePath: book.pdfUrl)`; Semantics IDs: `my_courses_btn_download_book`, `category_books_btn_download`
  - `pubspec.yaml` — added `open_filex: ^4.7.0`
  - `AndroidManifest.xml` — added `androidx.core.content.FileProvider`; `res/xml/file_paths.xml` created
  - Storage RLS fix — applied `books_allow_all_authenticated` policy on `storage.objects`; migration at `supabase/migrations/20260605000001_storage_policies.sql`
  - **Verified E2E**: download button visible → tap → `%PDF-1.4` saved to `app_flutter/books/{id}.pdf` → button switches to "فتح PDF"
- **Full UI redesign — new design system (2026-06-08)**:
  - New token system: `Tok.of(context)` from `lib/core/config/app_tokens.dart` — replaces old inline `_kPurple`/`_kDark`/`_kBg` constants on redesigned screens
  - `AtmosphereBackground` + `GlassCard` established as the layout primitives for all new screens
  - `home_page.dart` — `_ExploreSection` (vertical list) replaced with `_BentoGrid` (2-row bento); `_ContinueLearningCard` redesigned as Half Accent (white card + 58px purple right strip); empty schedule state redesigned (🎉 + message container); "مراجعات" removed entirely from home
  - `category_books_page.dart` — `_BookCard` redesigned to match `_CourseCard` pattern; cart toggle (add/remove) + PdfDownloadButton when purchased
  - `private_lessons_page.dart` — complete rewrite to new design system: flat header, animated chips, GlassCard teacher cards, accentFg book button
  - `booking_calendar_page.dart` — complete rewrite: merged flat header, AnimatedSize progressive disclosure, 3-col GridView time slots, Arabic day abbreviations, Arabic grammar duration pills, label/value summary, sticky Column footer

### ⏳ Pending Features (not yet implemented):

#### 🔴 High Priority — backend ready, only UI missing:
- ~~**Notifications screen**~~ — **DONE (2026-06-07)**: `notifications_page.dart` built; bell icon added to home header with unread badge; real-time stream via `notificationsStreamProvider`; tap-to-mark-read; swipe-to-delete; markAllAsRead; empty/error/loading states; Semantics identifiers; P2-03 Maestro flow passing.

#### 🟡 Medium Priority — UI exists but stubbed:
- **Reviews card** (`مراجعات`) — **removed from home page** (not in Bento Grid); no backend table; if re-introduced, needs its own screen
- **GPA calculator** (`حاسبة المعدل`) — in Bento Grid as "قريباً"; shows toast on tap; no screen or backend needed (local computation only)
- **Exams card** (`اختبارات`) — not shown anywhere; no backend table yet
- **Help & Support** — `profile.dart` shows snackbar "قريباً" only

#### 🟢 Low Priority — planned but not started:
- **Admin dashboard** — `role = 'admin'` exists in `user.dart` and test credentials; no screens or routing built yet
- **Announcements** — `announcements` table exists in Supabase (`id, course_id, title, content, created_at`); no provider or UI

### ⚠️ Known Issues:

- `users` table needs `anon_phone_lookup` RLS policy for `verifyLoginOtp` to query by phone (see SQL above)
- `cart` table needs `allow_cart_all` RLS policy for `addToCart()` to work (see SQL above)
- `live_sessions` table needs `teachers_can_manage_sessions` RLS policy — without it, `startSession()` fails silently and secondary live-session buttons (chat, participants, files, recording) stay disabled permanently (see SQL above)
- ~~**All 4 storage buckets** had zero RLS policies~~ — **FIXED (2026-06-06)**: `*_allow_all_authenticated` policies applied via Supabase SQL Editor; migration at `supabase/migrations/20260605000001_storage_policies.sql`. Teacher upload and student PDF download both working.
- Agora token is empty string (no-token dev project) — needs server-side token generation before production

### 🔧 Applying Missing Storage Policies (One-Time Setup)

All 4 storage buckets are locked down by default. Run this in the **Supabase SQL Editor**
(`https://supabase.com/dashboard/project/YOUR_PROJECT_REF/sql/new`):

```sql
CREATE POLICY "books_allow_all_authenticated"
  ON storage.objects FOR ALL TO authenticated
  USING (bucket_id = 'books') WITH CHECK (bucket_id = 'books');

CREATE POLICY "recordings_allow_all_authenticated"
  ON storage.objects FOR ALL TO authenticated
  USING (bucket_id = 'recordings') WITH CHECK (bucket_id = 'recordings');

CREATE POLICY "avatars_allow_all_authenticated"
  ON storage.objects FOR ALL TO authenticated
  USING (bucket_id = 'avatars') WITH CHECK (bucket_id = 'avatars');

CREATE POLICY "thumbnails_allow_all_authenticated"
  ON storage.objects FOR ALL TO authenticated
  USING (bucket_id = 'course-thumbnails') WITH CHECK (bucket_id = 'course-thumbnails');
```

Or via CLI: `supabase db push --linked --project-ref YOUR_PROJECT_REF`
(requires `SUPABASE_ACCESS_TOKEN` env variable set first)

### ✅ MVP Complete:

All four MVP items shipped (2026-05-08):

1. ✅ **Student conversation detail** — `student_conversation_detail_page.dart` — real-time message thread, Teams-purple header, teacher name, unread reset on open
2. ✅ **Post-payment fulfillment** — `payment_provider.dart` `verifyAndFulfill` — writes `payments` row, upserts `enrollments` / `book_purchases`, invalidates `myEnrollmentsProvider` / `myCoursesProvider` / `myPurchasedBooksProvider` / `myBookPurchasesProvider`
3. ✅ **Recording playback** — `online_course_view.dart` (`_SessionCard`) generates signed URL from private `recordings` bucket; teacher upload in `course_materials_page.dart` uploads video binary + writes `recording_url` to `live_sessions`
4. ✅ **OTP authentication** — `auth_provider.dart` full real Supabase Phone OTP flow; `otp_verification_page.dart` new shared screen; `login_page.dart` + `register_page.dart` updated to call `sendLoginOtp` / `sendRegisterOtp`

---

## Test Credentials (Seed Data)

| Role    | Phone        | Note                            |
| ------- | ------------ | ------------------------------- |
| Student | +973XXXXXXXX | Enter your test student number |
| Teacher | +973XXXXXXXX | Enter your test teacher number |
| Admin   | +973XXXXXXXX | Enter your test admin number   |

---

## Key Dependencies

| Package                | Purpose                               | Version  |
| ---------------------- | ------------------------------------- | -------- |
| `supabase_flutter`     | Backend (auth + database + storage)   | ^2.8.0   |
| `flutter_riverpod`     | State management                      | ^2.5.1   |
| `shared_preferences`   | Local storage (schedule + theme)      | ^2.3.5   |
| `agora_rtc_engine`     | Live streaming (broadcaster/audience) | ^6.3.2   |
| `permission_handler`   | Runtime camera/mic permissions        | ^11.3.1  |
| `file_picker`          | Native PDF file picking for uploads   | ^8.1.2   |
| `table_calendar`       | Booking calendar UI                   | ^3.1.2   |
| `cached_network_image` | Network image caching                 | ^3.3.1   |
| `http`                 | HTTP requests (Tap Payments API)      | ^1.2.0   |
| `url_launcher`         | Open external URLs (recordings)       | ^6.3.0   |

---

## Important Notes

### Live Streaming:

- Always test on a **real device** — emulators don't have cameras
- Both teacher and student must be on the same `courseId` channel
- Agora Console project must be in "testing" mode (no token) until server-side token generation is added

### Payments:

- Tap Payments API (Bahrain) — config in `tap_config.dart`
- Flow: Cart → Checkout → Tap API call → `launchUrl` (hosted payment page) → user returns → "تحقق من الدفع" → `verifyAndFulfill` → writes `payments` row + upserts `enrollments` / `book_purchases` → clears cart → refreshes providers → success screen

### Real-time:

- Messages: `messagesStreamProvider` (Supabase real-time)
- Notifications: `notificationsStreamProvider`

### Storage:

- Public buckets: direct URLs
- Private buckets: signed URLs via Supabase (RLS enforced)

---

## Development Workflow

1. **Check existing code** before creating new files
2. **Follow established patterns** in similar screens
3. **Never use `color:` + `decoration:` on the same Container** — always put color inside `BoxDecoration`
4. **Use null-safe casting** for Supabase fields (`as bool?` not `as bool`)
5. **Test live streaming on real device** — emulators have no camera
6. **Use Supabase Dashboard** for database queries/debugging
7. **New student screens**: use `Tok.of(context)` tokens + `AtmosphereBackground` + `GlassCard` — do NOT use inline `_kPurple`/`_kDark`/`_kBg` constants or gradient headers on any newly redesigned screen. **Auth/payment screens** (`welcome_page`, `login_page`, `register_page`, `cart`, `checkout_screen`) still use the old inline constants until they are migrated.
8. **Teacher pages**: use `AppTheme` constants + header gradient `[Color(0xFF464775), Color(0xFF6264A7)]` (Teams purple, same as student)
9. **Gradient buttons**: always use `DecoratedBox` + `ElevatedButton(backgroundColor: transparent)` pattern
10. **`addToCart()` returns `bool`**: always read the return value and show conditional snackbar
11. **Handle all states**: loading → error → empty → success
12. **SafeArea inside Scaffold body is a no-op for top padding**: Flutter's Scaffold removes `padding.top` from the body's MediaQuery when there is no AppBar. Use `MediaQuery.of(context).padding.top` directly in the header's inner `EdgeInsets` instead of relying on `SafeArea(bottom: false)`
13. **Today's schedule: filter inline, not via `todayScheduleProvider`**: `todayScheduleProvider` caches its result and only recomputes when `scheduleProvider` changes — `DateTime.now().weekday` is frozen. In `home_page.dart`, watch `scheduleProvider` directly and filter inline in `build()` so the weekday is re-evaluated on every mount. Use `_parseTimeMin()` for numeric time sorting
14. **Timetable grid uses `Directionality(ltr)` internally**: the day-column ordering (Sun→Thu left-to-right) requires wrapping the Row in `Directionality(textDirection: TextDirection.ltr)` even though the rest of the app is RTL
15. **Schedule storage is local only**: `ScheduleItem` data lives in SharedPreferences, not Supabase. No table needed, no auth required — works for all students including unauthenticated
16. **Student bottom nav has 5 tabs**: الرئيسية(0) · الرسائل(1) · دوراتي(2) · جدولي(3) · حسابي(4). Each student screen defines its own private `_BottomNav` class with the correct `active` index. When adding a new student top-level screen, copy the `_BottomNav` class and set the appropriate active index
17. **Adding Semantics identifiers to new screens**: wrap every interactive element (buttons, text fields, nav items, chips) with `Semantics(identifier: 'screen_widget_purpose')`. Place the Semantics node **inside** any `DecoratedBox`, wrapping the actual interactive widget (`GestureDetector` / `ElevatedButton`). Never add `button: true` or `onTap:` to the Semantics node — only `identifier:` to avoid ghost accessibility nodes
18. **`waitForAnimationToEnd` in Maestro flows**: always add `timeout: 5000` — teacher home has a continuous pulsing animation that never idles, so omitting a timeout causes the test runner to hang indefinitely
19. **Icon-only buttons need `label:` for screen readers**: `Semantics(identifier: '...')` alone is not enough — TalkBack/VoiceOver won't announce anything meaningful. Icon-only buttons (back, cart, search) must also include `label: 'Arabic text'`: `Semantics(label: 'رجوع', identifier: 'category_btn_back', child: GestureDetector(...))`
20. **Back button icon in RTL app**: always use `Icons.arrow_back_ios_new` for navigation-back buttons. Never use `Icons.arrow_forward_ios` (→) as a back button — it creates ambiguity with list-item chevrons and confuses users expecting the universal ← = "back" convention
21. **Minimum touch targets**: all interactive elements must be at least 44×44 (iOS HIG) / 48×48dp (Material 3). Use `width: 44, height: 44` on the inner Container for gradient-header icon buttons. Never use 36×36 or 38×38 for tappable elements
22. **Phone number fields**: always use `keyboardType: TextInputType.number` (not `.phone`) and `textDirection: TextDirection.ltr` (phone numbers are LTR even in RTL apps). Do NOT use `autofocus: true` on login/register phone fields — autofocus keeps the keyboard visible after tapping the submit button, which obscures the error widget and breaks Maestro assertions
23. **OTP field**: always add `autofillHints: const [AutofillHints.oneTimeCode]` and auto-submit on the 6th digit (`if (value.length == 6) _onVerify()`). OTP field DOES use `autofocus: true` because Maestro doesn't `inputText:` into it (skip RTL-input limitation applies)
24. **Grade level DB format**: store `grade_10` / `grade_11` / `grade_12` in the `users.grade_level` column, NOT Arabic display strings. The `_translateGrade()` helper in `profile.dart` maps these to Arabic for display. Register page must map from display → DB value before calling the provider
25. **Form submit handlers must call `FocusScope.of(context).unfocus()` first**: this dismisses the keyboard before validation runs, ensuring inline error widgets are fully visible (not covered by keyboard) and Maestro `assertVisible` checks succeed. Pattern: `void _onSubmit() { FocusScope.of(context).unfocus(); final value = _controller.text.trim(); ... }`
26. **Maestro flows: use `launchApp` instead of `pressKey: back` to get fresh form state**: `pressKey: back` when keyboard is already dismissed can navigate to an ancestor screen, and a second `pressKey: back` from the root screen exits the app entirely. Use `launchApp` + re-navigate forward to reset a form — it keeps cleared auth state from `clearState` at the top of the flow and is more reliable than eraseText or back navigation
27. **Semantics identifiers must be unique across the entire widget tree**: duplicate identifiers cause Maestro `tapOn: id:` to tap an unpredictable element and `assertVisible` to match the wrong node. When the same logical widget type appears multiple times on a screen, append a disambiguator. **For list cards** (`ListView.builder`/`separated`), always pass `index` as a constructor param and append `_$index` to every identifier inside: `my_courses_btn_view_recordings_$index`, `teacher_courses_btn_start_live_$index`, etc. Maestro flows target the first card with `_0`. Affected screens: `my_courses.dart`, `category_online_page.dart`, `category_books_page.dart`, `chat.dart`, `notifications_page.dart`, `teacher_courses_page.dart`, `teacher_chat_page.dart`, `course_materials_page.dart`.
28. **No-op `onPressed: () {}` is always a bug**: a button with an empty callback misleads users and breaks testing. Either implement the real action or disable the button with `onPressed: null` and add a visual disabled state. For "coming soon" features visible in the UI, use `IgnorePointer` + `Opacity(0.38)` at the widget level — never an empty tap handler.
29. **`open_filex` opens in a separate OS task — `clearState` does not close it**: if a flow taps a download/open button that launches `open_filex`, the PDF viewer stays open when the next flow runs. Add `pressKey: back` after the optional download tap in Maestro flows to dismiss the viewer. Make downstream assertions `optional: true` since `pressKey: back` may land on home instead of the originating screen.
30. **`extendedWaitUntil` timeout must be ≥ 20 s in `_login_student.yaml`**: the splash screen delays WelcomePage by ~2.9 s; after many consecutive flows, emulator performance degrades further. 10 s timed out on flows 17+ in a 20-flow suite. Always use `timeout: 20000` (20 s) for the initial `welcome_btn_login` wait.

---

## Remember:

- Always use providers — no direct Supabase calls in UI
- All UI text in Arabic
- RTL layout everywhere
- Handle all async states
- Test on real Bahraini phone numbers
- Keep credentials out of version control (use `.env` in production)
