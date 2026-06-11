import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../widgets/atmosphere_background.dart';
import '../../widgets/glass_card.dart';

class UploadMaterialPage extends ConsumerStatefulWidget {
  final String courseId;

  const UploadMaterialPage({super.key, required this.courseId});

  @override
  ConsumerState<UploadMaterialPage> createState() =>
      _UploadMaterialPageState();
}

class _UploadMaterialPageState extends ConsumerState<UploadMaterialPage> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController(text: '0');

  String? _selectedCourseId;
  File? _pickedFile;
  String? _pickedFileName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCourseId =
        widget.courseId.isNotEmpty ? widget.courseId : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) {
      _showError('تعذر الوصول للملف');
      return;
    }
    setState(() {
      _pickedFile = File(file.path!);
      _pickedFileName = file.name;
    });
  }

  Future<void> _upload() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('الرجاء إدخال اسم الملزمة');
      return;
    }
    if (_selectedCourseId == null) {
      _showError('الرجاء اختيار الدورة');
      return;
    }
    if (_pickedFile == null) {
      _showError('الرجاء اختيار ملف PDF');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).user;
      if (user == null) {
        _showError('يجب تسجيل الدخول أولاً');
        setState(() => _isLoading = false);
        return;
      }
      final supabase = Supabase.instance.client;

      final courseRow = await supabase
          .from('courses')
          .select('subject_id')
          .eq('id', _selectedCourseId!)
          .single();
      final subjectId = courseRow['subject_id'] as String;

      final fileBytes = await _pickedFile!.readAsBytes();
      final fileSize = fileBytes.length;
      final storagePath =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}_$_pickedFileName';

      await supabase.storage.from('books').uploadBinary(
            storagePath,
            fileBytes,
            fileOptions:
                const FileOptions(contentType: 'application/pdf'),
          );

      final price = double.tryParse(_priceController.text) ?? 0;
      await supabase.from('books').insert({
        'title': title,
        'teacher_id': user.id,
        'course_id': _selectedCourseId,
        'subject_id': subjectId,
        'price': price,
        'pdf_url': storagePath,
        'file_size': fileSize,
        'is_active': true,
        'downloads_count': 0,
      });

      if (mounted) {
        showAppToast(context,
            message: 'تم رفع الملزمة بنجاح',
            color: const Color(0xFF6264A7));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showError('حدث خطأ أثناء الرفع: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    showAppToast(context, message: msg, type: ToastType.error);
  }

  @override
  Widget build(BuildContext context) {
    final t = Tok.of(context);
    final coursesAsync = ref.watch(teacherCoursesProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AtmosphereBackground(
          child: CustomScrollView(
            slivers: [
              // ── Header ────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppTokens.screenPad, 16,
                        AppTokens.screenPad, 12),
                    child: Row(
                      children: [
                        Semantics(
                          label: 'رجوع',
                          identifier: 'upload_btn_back',
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: t.isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : t.bg2,
                                borderRadius: BorderRadius.circular(
                                    AppTokens.rSm),
                                border: Border.all(color: t.line),
                              ),
                              child: Icon(Icons.arrow_back_ios_new,
                                  color: t.ink2, size: 15),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'رفع ملزمة',
                                style: TextStyle(
                                  fontSize: AppTokens.tsAppBar,
                                  fontWeight: FontWeight.w700,
                                  color: t.ink,
                                ),
                              ),
                              Text(
                                'أضف ملزمة PDF لطلابك',
                                style: TextStyle(
                                    fontSize: 12, color: t.muted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: t.accentTint,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.description_rounded,
                              color: t.accentFg, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppTokens.screenPad,
                    0, AppTokens.screenPad, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Title Field ────────────────────────────────────
                    _FieldLabel('اسم الملزمة', t),
                    const SizedBox(height: 8),
                    _StyledTextField(
                      controller: _titleController,
                      hint: 'مثال: ملزمة الأسبوع 3',
                      keyboardType: TextInputType.text,
                      textDirection: TextDirection.rtl,
                      prefixIcon: Icons.edit_outlined,
                      t: t,
                    ),

                    const SizedBox(height: 20),

                    // ── Price Field ────────────────────────────────────
                    _FieldLabel('السعر (د.ب)', t),
                    const SizedBox(height: 8),
                    _StyledTextField(
                      controller: _priceController,
                      hint: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      textDirection: TextDirection.ltr,
                      prefixIcon: Icons.payments_outlined,
                      t: t,
                    ),

                    const SizedBox(height: 20),

                    // ── Course Selector ────────────────────────────────
                    _FieldLabel('الدورة', t),
                    const SizedBox(height: 8),
                    coursesAsync.when(
                      loading: () =>
                          LinearProgressIndicator(color: t.accentFg),
                      error: (_, __) => Text(
                        'تعذر تحميل الدورات',
                        style: const TextStyle(color: Colors.red),
                      ),
                      data: (courses) => GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: courses.any(
                                    (c) => c.id == _selectedCourseId)
                                ? _selectedCourseId
                                : null,
                            isExpanded: true,
                            hint: Text(
                              'اختر الدورة',
                              style: TextStyle(color: t.muted),
                            ),
                            icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: t.muted),
                            dropdownColor:
                                t.isDark ? const Color(0xFF2D2D3E) : Colors.white,
                            items: courses
                                .map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.title,
                                          style: TextStyle(color: t.ink)),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCourseId = v),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── File Picker ────────────────────────────────────
                    _FieldLabel('ملف PDF', t),
                    const SizedBox(height: 8),
                    Semantics(
                      identifier: 'upload_btn_pick_file',
                      child: GestureDetector(
                        onTap: _isLoading ? null : _pickFile,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: 28),
                          decoration: BoxDecoration(
                            color: _pickedFile != null
                                ? const Color(0xFFF0FDF4)
                                : (t.isDark
                                    ? const Color(0xFF1E1E2E)
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(
                                AppTokens.rLg),
                            border: Border.all(
                              color: _pickedFile != null
                                  ? const Color(0xFF86EFAC)
                                  : t.line,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: _pickedFile != null
                                      ? const Color(0xFFDCFCE7)
                                      : t.accentTint,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _pickedFile != null
                                      ? Icons.check_circle_rounded
                                      : Icons.upload_file_rounded,
                                  size: 28,
                                  color: _pickedFile != null
                                      ? const Color(0xFF16A34A)
                                      : t.accentFg,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _pickedFile != null
                                    ? _pickedFileName ??
                                        'تم اختيار الملف'
                                    : 'اضغط لاختيار ملف PDF',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _pickedFile != null
                                      ? const Color(0xFF16A34A)
                                      : t.ink2,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              if (_pickedFile == null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'PDF فقط',
                                  style: TextStyle(
                                      fontSize: 12, color: t.muted),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Submit ─────────────────────────────────────────
                    Semantics(
                      identifier: 'upload_btn_submit',
                      child: GestureDetector(
                        onTap: _isLoading ? null : _upload,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: 17),
                          decoration: BoxDecoration(
                            gradient: _isLoading
                                ? null
                                : const LinearGradient(
                                    colors: [
                                      Color(0xFF464775),
                                      Color(0xFF6264A7)
                                    ],
                                    begin: Alignment.centerRight,
                                    end: Alignment.centerLeft,
                                  ),
                            color: _isLoading ? null : null,
                            borderRadius:
                                BorderRadius.circular(AppTokens.rLg),
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.cloud_upload_rounded,
                                          color: Colors.white,
                                          size: 20),
                                      SizedBox(width: 10),
                                      Text(
                                        'رفع الملزمة',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  final Tok t;
  const _FieldLabel(this.text, this.t);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: t.ink,
        fontSize: 14,
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final TextDirection textDirection;
  final IconData prefixIcon;
  final Tok t;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.keyboardType,
    required this.textDirection,
    required this.prefixIcon,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: textDirection,
      style: TextStyle(color: t.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: t.muted),
        prefixIcon: Icon(prefixIcon, size: 20, color: t.muted),
        filled: true,
        fillColor: t.isDark ? const Color(0xFF2D2D3E) : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rMd),
          borderSide: BorderSide(color: t.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rMd),
          borderSide: BorderSide(color: t.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.rMd),
          borderSide: BorderSide(color: t.accentFg, width: 1.5),
        ),
      ),
    );
  }
}
