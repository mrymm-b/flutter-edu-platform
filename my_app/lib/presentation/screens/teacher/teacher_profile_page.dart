import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_tokens.dart';
import '../../../core/utils/toast.dart';
import '../../providers/auth_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/glass_card.dart';
import '../shared/login_page.dart';

class TeacherProfilePage extends ConsumerWidget {
  const TeacherProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Tok.of(context);
    final user = ref.watch(authProvider).user;
    final coursesAsync = ref.watch(teacherCoursesProvider);
    final totalStudentsAsync = ref.watch(teacherTotalStudentsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    final totalStudents = totalStudentsAsync.when(
        data: (n) => n, loading: () => 0, error: (_, __) => 0);
    final totalCourses = coursesAsync.when(
        data: (c) => c.length, loading: () => 0, error: (_, __) => 0);

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Profile header ───────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppTokens.screenPad, 20, AppTokens.screenPad, 0),
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: t.accentTint,
                        shape: BoxShape.circle,
                        border: Border.all(color: t.accentLine, width: 2),
                      ),
                      child: Icon(Icons.person_rounded,
                          color: t.accentFg, size: 38),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'أ. ${user?.fullName ?? ''}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: t.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: t.accentTint,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user?.phone ?? '',
                        style: TextStyle(fontSize: 13, color: t.accentFg),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatPill(
                            value: '$totalStudents', label: 'طالب', t: t),
                        Container(
                          width: 1,
                          height: 28,
                          color: t.line,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 20)),
                        _StatPill(
                            value: '$totalCourses', label: 'دورة', t: t),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Menu ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppTokens.screenPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel('الحساب', t),
                const SizedBox(height: 10),
                Semantics(
                  identifier: 'teacher_profile_btn_edit_name',
                  child: _MenuItem(
                    icon: Icons.person_outline_rounded,
                    label: 'تعديل الاسم',
                    iconColor: t.accentFg,
                    iconBg: t.accentTint,
                    t: t,
                    onTap: () =>
                        _showEditDialog(context, ref, user?.fullName ?? ''),
                  ),
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: 'الإشعارات',
                  iconColor: const Color(0xFFF59E0B),
                  iconBg: const Color(0xFFFFFBEB),
                  t: t,
                  onTap: () => showAppToast(context,
                      message: 'الإشعارات — قريباً', type: ToastType.info),
                ),
                Semantics(
                  identifier: 'teacher_profile_btn_theme',
                  child: _MenuItem(
                    icon: isDarkMode
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    label: isDarkMode
                        ? 'تفعيل الوضع الفاتح'
                        : 'تفعيل الوضع الداكن',
                    iconColor: t.accentFg,
                    iconBg: t.accentTint,
                    t: t,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .setMode(isDarkMode ? ThemeMode.light : ThemeMode.dark),
                  ),
                ),

                const SizedBox(height: 20),
                _SectionLabel('الدعم', t),
                const SizedBox(height: 10),
                _MenuItem(
                  icon: Icons.help_outline_rounded,
                  label: 'المساعدة والدعم',
                  iconColor: const Color(0xFF16A34A),
                  iconBg: const Color(0xFFF0FDF4),
                  t: t,
                  onTap: () => showAppToast(context,
                      message: 'المساعدة — قريباً', type: ToastType.info),
                ),
                _MenuItem(
                  icon: Icons.info_outline_rounded,
                  label: 'عن التطبيق',
                  iconColor: const Color(0xFF6B7280),
                  iconBg: t.isDark
                      ? const Color(0xFF2D2D3E)
                      : const Color(0xFFF9FAFB),
                  t: t,
                  onTap: () => showAppToast(context,
                      message: 'منصة تعليمية — الإصدار 1.0.0', type: ToastType.info),
                ),

                const SizedBox(height: 28),

                // ── Logout ──
                Semantics(
                  identifier: 'teacher_profile_btn_logout',
                  child: GestureDetector(
                    onTap: () => _confirmLogout(context, ref),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded,
                              color: Color(0xFFDC2626), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'تسجيل الخروج',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'تعديل الاسم',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Semantics(
                  identifier: 'teacher_profile_dialog_field_name',
                  child: TextField(
                    controller: controller,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'الاسم الكامل',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        identifier:
                            'teacher_profile_dialog_btn_cancel_edit',
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 13),
                            side: const BorderSide(
                                color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('إلغاء',
                              style:
                                  TextStyle(color: Color(0xFF64748B))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Semantics(
                        identifier:
                            'teacher_profile_dialog_btn_save_edit',
                        child: ElevatedButton(
                          onPressed: () async {
                            final name = controller.text.trim();
                            if (name.isEmpty) {
                              showAppToast(context,
                                  message: 'الرجاء إدخال الاسم',
                                  type: ToastType.error);
                              return;
                            }
                            Navigator.pop(context);
                            await ref
                                .read(authProvider.notifier)
                                .updateProfile(fullName: name);
                            if (context.mounted) {
                              showAppToast(context,
                                  message: 'تم تحديث الاسم',
                                  color: const Color(0xFF6264A7));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6264A7),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('حفظ',
                              style: TextStyle(
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
    ).then((_) => controller.dispose());
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2), shape: BoxShape.circle),
                  child: const Icon(Icons.logout_rounded,
                      color: Color(0xFFEF4444), size: 32),
                ),
                const SizedBox(height: 18),
                const Text('تسجيل الخروج',
                    style: TextStyle(
                        fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('هل تريد تسجيل الخروج من حسابك؟',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 14, color: Colors.grey[500])),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        identifier:
                            'teacher_profile_dialog_btn_cancel_logout',
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 13),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text('إلغاء',
                              style:
                                  TextStyle(color: Colors.grey[600])),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Semantics(
                        identifier:
                            'teacher_profile_dialog_btn_confirm_logout',
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await ref.read(authProvider.notifier).logout();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (_) => const LoginPage()),
                                (_) => false,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('خروج',
                              style: TextStyle(
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
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Tok t;
  const _StatPill({required this.value, required this.label, required this.t});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: t.ink)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 13, color: t.muted)),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Tok t;
  const _SectionLabel(this.text, this.t);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: t.muted,
            letterSpacing: 0.5));
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color iconBg;
  final Tok t;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.iconBg,
    required this.t,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        radius: AppTokens.rMd,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      color: t.ink,
                      fontWeight: FontWeight.w500)),
            ),
            Icon(Icons.chevron_left, size: 18, color: t.faint),
          ],
        ),
      ),
    );
  }
}
