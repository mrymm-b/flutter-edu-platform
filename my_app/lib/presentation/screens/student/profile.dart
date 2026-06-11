import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_tokens.dart';
import '../../../core/utils/toast.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messages_provider.dart';
import '../../providers/theme_provider.dart';
import '../../../presentation/widgets/atmosphere_background.dart';
import '../../../presentation/widgets/glass_card.dart';
import '../shared/welcome_page.dart';
import 'home_page.dart';
import 'my_courses.dart';
import 'chat.dart';
import 'schedule_screen.dart';

class Profile extends ConsumerWidget {
  const Profile({super.key});

  // ── Initials ──────────────────────────────────────────────────────────────
  static String _initials(String? name) {
    return (name ?? 'ط')
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0])
        .join();
  }

  // ── Grade label ───────────────────────────────────────────────────────────
  static String _translateGrade(String? grade) {
    if (grade == null) return '';
    const grades = {
      'grade_1':  'الصف الأول',
      'grade_2':  'الصف الثاني',
      'grade_3':  'الصف الثالث',
      'grade_4':  'الصف الرابع',
      'grade_5':  'الصف الخامس',
      'grade_6':  'الصف السادس',
      'grade_7':  'الصف السابع',
      'grade_8':  'الصف الثامن',
      'grade_9':  'الصف التاسع',
      'grade_10': 'الصف العاشر',
      'grade_11': 'الصف الحادي عشر',
      'grade_12': 'الصف الثاني عشر',
    };
    return grades[grade] ?? grade;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Tok.of(context);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    String roleLabel = '';
    if (user != null) {
      if (user.isStudent) {
        roleLabel = _translateGrade(user.gradeLevel);
        if (roleLabel.isEmpty) roleLabel = 'طالب';
      } else if (user.isTeacher) {
        roleLabel = 'معلم';
      } else if (user.isAdmin) {
        roleLabel = 'مدير';
      }
    }

    final initials = _initials(user?.fullName);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AtmosphereBackground(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppTokens.screenPad, 20, AppTokens.screenPad, 0),
                  child: Column(
                    children: [
                      // Avatar row
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: t.avatarDecoration(32),
                            child: user?.avatarUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      user!.avatarUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Center(child: _initialsText(initials, t, 22)),
                                    ),
                                  )
                                : Center(child: _initialsText(initials, t, 22)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.fullName ?? 'الطالب',
                                  style: TextStyle(
                                    fontSize: AppTokens.tsH1,
                                    fontWeight: FontWeight.w700,
                                    color: t.ink,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                if (roleLabel.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: t.accentTint,
                                      borderRadius: BorderRadius.circular(AppTokens.rPill),
                                    ),
                                    child: Text(
                                      roleLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: t.accentFg,
                                      ),
                                    ),
                                  ),
                                if (user?.phone != null) ...[
                                  const SizedBox(height: 4),
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      user!.phone,
                                      style: TextStyle(
                                          fontSize: 12, color: t.muted),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Edit button
                          Semantics(
                            label: 'تعديل الملف الشخصي',
                            identifier: 'profile_btn_edit_profile',
                            child: GestureDetector(
                              onTap: () =>
                                  _showEditProfileDialog(context, ref, user),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: t.isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : t.bg2,
                                  borderRadius:
                                      BorderRadius.circular(AppTokens.rSm),
                                  border: Border.all(color: t.line),
                                ),
                                child: Icon(Icons.edit_outlined,
                                    size: 18, color: t.ink2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Scrollable body ──────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                      AppTokens.screenPad, 24, AppTokens.screenPad, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Server error ───────────────────────────────────
                      if (authState.error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppTokens.rSm),
                            border: Border.all(
                                color: const Color(0xFFDC2626)
                                    .withValues(alpha: 0.25)),
                          ),
                          child: Text(authState.error!,
                              style: const TextStyle(
                                  color: Color(0xFFDC2626), fontSize: 13),
                              textAlign: TextAlign.center),
                        ),
                      ],

                      // ── الحساب section ────────────────────────────────
                      _sectionLabel('الحساب', t),
                      const SizedBox(height: 10),
                      _menuItem(
                        context: context,
                        t: t,
                        icon: Icons.shopping_bag_outlined,
                        label: 'دوراتي ومشترياتي',
                        semanticsId: 'profile_btn_my_courses',
                        onTap: () => Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (_) => const MyCourses())),
                      ),
                      const SizedBox(height: AppTokens.cardGap),
                      _menuItem(
                        context: context,
                        t: t,
                        icon: isDarkMode
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        label: isDarkMode ? 'تفعيل الوضع الفاتح' : 'تفعيل الوضع الداكن',
                        semanticsId: 'profile_btn_theme',
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setMode(isDarkMode ? ThemeMode.light : ThemeMode.dark),
                      ),

                      const SizedBox(height: AppTokens.sectionGap),

                      // ── الدعم section ──────────────────────────────────
                      _sectionLabel('الدعم', t),
                      const SizedBox(height: 10),
                      _menuItem(
                        context: context,
                        t: t,
                        icon: Icons.help_outline_rounded,
                        label: 'المساعدة والدعم',
                        semanticsId: 'profile_btn_help',
                        onTap: () => showAppToast(context,
                            message: 'المساعدة — قريباً',
                            type: ToastType.info),
                      ),
                      const SizedBox(height: AppTokens.cardGap),
                      _menuItem(
                        context: context,
                        t: t,
                        icon: Icons.info_outline_rounded,
                        label: 'عن التطبيق',
                        semanticsId: 'profile_btn_about',
                        onTap: () => showAppToast(context,
                            message: 'منصة تعليمية — الإصدار 1.0.0',
                            type: ToastType.info),
                      ),

                      const SizedBox(height: 32),

                      // ── Logout ─────────────────────────────────────────
                      Semantics(
                        identifier: 'profile_btn_logout',
                        child: GestureDetector(
                          onTap: () => _showLogoutDialog(context, ref),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 15),
                            radius: AppTokens.rMd,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.logout_rounded,
                                    color: Color(0xFFEF4444), size: 20),
                                const SizedBox(width: 10),
                                const Text(
                                  'تسجيل الخروج',
                                  style: TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── Bottom Nav ───────────────────────────────────────────────
              _BottomNav(active: 4, context: context),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static Widget _initialsText(String text, Tok t, double size) => Text(
        text,
        style: TextStyle(
          color: t.isDark ? Colors.white : t.accentFg,
          fontSize: size,
          fontWeight: FontWeight.w700,
        ),
      );

  static Widget _sectionLabel(String text, Tok t) => Text(
        text,
        style: TextStyle(
          fontSize: AppTokens.tsEyebrow,
          fontWeight: FontWeight.w600,
          color: t.muted,
          letterSpacing: 0.4,
        ),
      );

  static Widget _menuItem({
    required BuildContext context,
    required Tok t,
    required IconData icon,
    required String label,
    required String semanticsId,
    required VoidCallback onTap,
  }) {
    return Semantics(
      identifier: semanticsId,
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          radius: AppTokens.rMd,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: t.isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : t.bg2,
                  borderRadius: BorderRadius.circular(AppTokens.rSm),
                  border: t.isDark
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.06))
                      : null,
                ),
                child: Icon(icon, color: t.ink2, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                      fontSize: AppTokens.tsCardT,
                      color: t.ink,
                      fontWeight: FontWeight.w500),
                ),
              ),
              Icon(Icons.chevron_left, size: 18, color: t.faint),
            ],
          ),
        ),
      ),
    );
  }

  // ── Logout dialog ──────────────────────────────────────────────────────────
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final t = Tok.of(context);
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(28),
              border: t.isDark ? Border.all(color: t.line) : null,
              boxShadow: t.cardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: Color(0xFFEF4444), size: 34),
                ),
                const SizedBox(height: 20),
                Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: t.ink),
                ),
                const SizedBox(height: 8),
                Text(
                  'هل أنت متأكد من تسجيل الخروج\nمن حسابك؟',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 14, color: t.muted, height: 1.6),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        identifier: 'profile_dialog_btn_cancel_logout',
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: t.line),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16)),
                          ),
                          child: Text('إلغاء',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: t.muted)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Semantics(
                        identifier: 'profile_dialog_btn_confirm_logout',
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await ref
                                .read(authProvider.notifier)
                                .logout();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (_) => const WelcomePage()),
                                (_) => false,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16)),
                          ),
                          child: const Text('خروج',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Edit profile dialog ────────────────────────────────────────────────────
  static const _gradeOptions = [
    ('grade_1',  'الصف الأول'),
    ('grade_2',  'الصف الثاني'),
    ('grade_3',  'الصف الثالث'),
    ('grade_4',  'الصف الرابع'),
    ('grade_5',  'الصف الخامس'),
    ('grade_6',  'الصف السادس'),
    ('grade_7',  'الصف السابع'),
    ('grade_8',  'الصف الثامن'),
    ('grade_9',  'الصف التاسع'),
    ('grade_10', 'الصف العاشر'),
    ('grade_11', 'الصف الحادي عشر'),
    ('grade_12', 'الصف الثاني عشر'),
  ];

  void _showEditProfileDialog(
      BuildContext context, WidgetRef ref, dynamic user) {
    if (user == null) return;
    final t = Tok.of(context);

    final parts = (user.fullName as String? ?? '').trim().split(' ');
    final firstCtrl =
        TextEditingController(text: parts.isNotEmpty ? parts.first : '');
    final lastCtrl = TextEditingController(
        text: parts.length > 1 ? parts.sublist(1).join(' ') : '');

    final rawGrade = user.gradeLevel as String? ?? '';
    final initialGrade = _gradeOptions.any((g) => g.$1 == rawGrade)
        ? rawGrade
        : _gradeOptions.first.$1;

    InputDecoration fieldDeco(String label) => InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: t.muted, fontSize: 13),
          filled: true,
          fillColor: t.bg2,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.rInput),
            borderSide: BorderSide(color: t.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.rInput),
            borderSide: BorderSide(color: t.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.rInput),
            borderSide: BorderSide(color: t.accentLine, width: 1.5),
          ),
        );

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(24),
              border: t.isDark ? Border.all(color: t.line) : null,
              boxShadow: t.cardShadow,
            ),
            child: StatefulBuilder(
              builder: (ctx, setS) {
                String selectedGrade = initialGrade;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تعديل الملف الشخصي',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: t.ink)),
                    const SizedBox(height: 18),
                    Semantics(
                      identifier: 'profile_dialog_field_first_name',
                      child: TextField(
                        controller: firstCtrl,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(fontSize: 14.5, color: t.ink),
                        decoration: fieldDeco('الاسم الأول'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      identifier: 'profile_dialog_field_last_name',
                      child: TextField(
                        controller: lastCtrl,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(fontSize: 14.5, color: t.ink),
                        decoration: fieldDeco('الاسم الأخير'),
                      ),
                    ),
                    if (user.isStudent as bool) ...[
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: t.bg2,
                          borderRadius:
                              BorderRadius.circular(AppTokens.rInput),
                          border: Border.all(color: t.line),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedGrade,
                          isExpanded: true,
                          dropdownColor: t.card,
                          style: TextStyle(fontSize: 14.5, color: t.ink),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                          ),
                          items: _gradeOptions
                              .map((g) => DropdownMenuItem(
                                    value: g.$1,
                                    child: Text(g.$2),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setS(() => selectedGrade = v);
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            identifier: 'profile_dialog_btn_cancel_edit',
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 13),
                                side: BorderSide(color: t.line),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14)),
                              ),
                              child: Text('إلغاء',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: t.muted)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Semantics(
                            identifier: 'profile_dialog_btn_save_edit',
                            child: PrimaryButton(
                              label: 'حفظ',
                              semanticsId: 'profile_dialog_save_inner',
                              onPressed: () async {
                                final first = firstCtrl.text.trim();
                                final last = lastCtrl.text.trim();
                                final fullName = [first, last]
                                    .where((s) => s.isNotEmpty)
                                    .join(' ');
                                await ref
                                    .read(authProvider.notifier)
                                    .updateProfile(
                                      fullName: fullName.isEmpty
                                          ? null
                                          : fullName,
                                      gradeLevel:
                                          user.isStudent as bool
                                              ? selectedGrade
                                              : null,
                                    );
                                if (!context.mounted) return;
                                Navigator.pop(ctx);
                                final err =
                                    ref.read(authProvider).error;
                                showAppToast(context,
                                    message: err ??
                                        'تم تحديث الملف الشخصي',
                                    type: err == null
                                        ? ToastType.success
                                        : ToastType.error);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ).then((_) {
      firstCtrl.dispose();
      lastCtrl.dispose();
    });
  }

}

// ── Bottom Nav ─────────────────────────────────────────────────────────────────
class _BottomNav extends ConsumerWidget {
  final int active;
  final BuildContext context;
  const _BottomNav({required this.active, required this.context});

  @override
  Widget build(BuildContext _, WidgetRef ref) {
    final t = Tok.of(context);
    final unread = ref
            .watch(myConversationsProvider)
            .valueOrNull
            ?.fold<int>(0, (sum, c) => sum + c.unreadCountStudent) ??
        0;

    return ThemedBottomNavShell(
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Semantics(
                  identifier: 'nav_home',
                  child: _item(Icons.home_rounded, 'الرئيسية', 0, t, () {
                    if (active != 0) {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const HomePage()));
                    }
                  })),
              Semantics(
                  identifier: 'nav_messages',
                  child: _chatItem(unread, t)),
              Semantics(
                  identifier: 'nav_my_courses',
                  child: _item(Icons.book_rounded, 'دوراتي', 2, t, () {
                    if (active != 2) {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const MyCourses()));
                    }
                  }, isCenter: true)),
              Semantics(
                  identifier: 'nav_schedule',
                  child: _item(Icons.calendar_month_rounded, 'جدولي', 3, t, () {
                    if (active != 3) {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(
                              builder: (_) => const ScheduleScreen()));
                    }
                  })),
              Semantics(
                  identifier: 'nav_profile',
                  child: _item(Icons.person_rounded, 'حسابي', 4, t, () {
                    if (active != 4) {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (_) => const Profile()));
                    }
                  })),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatItem(int unread, Tok t) {
    final isActive = active == 1;
    return GestureDetector(
      onTap: () {
        if (active != 1) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const Chat()));
        }
      },
      child: _navContent(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.chat_bubble_rounded,
                color: isActive ? t.accentFg : t.faint, size: 21),
            if (unread > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Color(0xFFEF4444), shape: BoxShape.circle),
                ),
              ),
          ],
        ),
        label: 'الرسائل',
        isActive: isActive,
        t: t,
      ),
    );
  }

  Widget _item(
    IconData icon,
    String label,
    int index,
    Tok t,
    VoidCallback onTap, {
    bool isCenter = false,
  }) {
    final isActive = active == index;
    final iconSize = isCenter ? 24.0 : 21.0;
    return GestureDetector(
      onTap: onTap,
      child: _navContent(
        icon: Icon(icon, color: isActive ? t.accentFg : t.faint, size: iconSize),
        label: label,
        isActive: isActive,
        t: t,
      ),
    );
  }

  Widget _navContent({
    required Widget icon,
    required String label,
    required bool isActive,
    required Tok t,
  }) =>
      AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? t.accentFg.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.rSm),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? t.accentFg : t.faint,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      );
}
