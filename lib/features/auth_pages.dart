import 'package:flutter/material.dart';

import '../api/backend_store.dart';
import '../data/demo_store.dart';
import '../ui/widgets.dart';

/// E-mail verification: paste the token from the verification mail, resend,
/// or continue browsing (publishing stays locked until verified).
class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key, this.popOnSuccess = true});
  final bool popOnSuccess;
  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final token = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    token.dispose();
    super.dispose();
  }

  BackendStore? get store {
    final s = DemoScope.of(context);
    return s is BackendStore ? s : null;
  }

  Future<void> verify() async {
    final s = store;
    if (s == null) return;
    final raw = token.text.trim();
    // Accept a pasted link (…?token=xxx) as well as the bare token.
    final value = Uri.tryParse(raw)?.queryParameters['token'] ?? raw;
    if (value.isEmpty) {
      setState(() => error = 'ألصق رمز التأكيد من البريد.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    final result = await s.verifyEmail(value);
    if (!mounted) return;
    setState(() => busy = false);
    if (result != null) {
      setState(() => error = result);
      return;
    }
    toast(context, 'تم توثيق بريدك. يمكنك النشر الآن.');
    if (widget.popOnSuccess) Navigator.pop(context, true);
  }

  Future<void> resend() async {
    final s = store;
    if (s == null) return;
    setState(() => busy = true);
    final result = await s.resendVerification();
    if (!mounted) return;
    setState(() => busy = false);
    toast(context, result ?? 'أرسلنا رابط تأكيد جديدًا إلى بريدك.');
  }

  Future<void> recheck() async {
    final s = store;
    if (s == null) return;
    setState(() => busy = true);
    await s.refreshUser();
    if (!mounted) return;
    setState(() => busy = false);
    if (s.emailVerified) {
      toast(context, 'بريدك موثّق.');
      if (widget.popOnSuccess) Navigator.pop(context, true);
    } else {
      toast(context, 'لم يُوثَّق بعد. افتح رابط البريد أو ألصق الرمز.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('توثيق البريد الإلكتروني'),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'خطوة أخيرة قبل النشر',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const Text(
          'أرسلنا رسالة تأكيد إلى بريدك. افتح الرابط فيها، أو الصق الرمز أدناه. يمكنك التصفح والمراسلة الآن، لكن نشر الإعلانات يحتاج بريدًا موثّقًا.',
        ),
        const SizedBox(height: 24),
        TextField(
          controller: token,
          enabled: !busy,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
            labelText: 'رمز التأكيد أو رابط البريد',
            errorText: error,
          ),
          onSubmitted: (_) => verify(),
        ),
        const SizedBox(height: 16),
        PrimaryButton('تأكيد', onPressed: busy ? null : verify),
        const SizedBox(height: 8),
        TextButton(
          onPressed: busy ? null : resend,
          child: const Text('إعادة إرسال رسالة التأكيد'),
        ),
        TextButton(
          onPressed: busy ? null : recheck,
          child: const Text('فتحت الرابط؟ تحقّق من الحالة'),
        ),
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context, false),
          child: const Text('لاحقًا — متابعة التصفح'),
        ),
      ],
    ),
  );
}

/// Forgot password: request a reset mail, then enter token + new password.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final key = GlobalKey<FormState>();
  final email = TextEditingController();
  bool busy = false, sent = false;

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!key.currentState!.validate()) return;
    final s = DemoScope.of(context);
    if (s is! BackendStore) return;
    setState(() => busy = true);
    final result = await s.forgotPassword(email.text);
    if (!mounted) return;
    setState(() => busy = false);
    if (result != null) {
      toast(context, result);
      return;
    }
    setState(() => sent = true);
    go(context, ResetPasswordPage(email: email.text.trim()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('نسيت كلمة المرور'),
    body: Form(
      key: key,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'استعادة كلمة المرور',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Text(
            'أدخل بريدك المسجّل. إن كان موجودًا وصلك رابط ورمز استعادة صالحان لفترة محدودة.',
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: email,
            enabled: !busy,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
            validator: (v) =>
                (v ?? '').contains('@') ? null : 'أدخل بريدًا صالحًا',
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            sent ? 'إعادة الإرسال' : 'إرسال رابط الاستعادة',
            onPressed: busy ? null : submit,
          ),
          TextButton(
            onPressed: () => go(context, ResetPasswordPage(email: email.text)),
            child: const Text('لديك رمز بالفعل؟ أدخله'),
          ),
        ],
      ),
    ),
  );
}

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, this.email = ''});
  final String email;
  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final key = GlobalKey<FormState>();
  late final email = TextEditingController(text: widget.email);
  final token = TextEditingController(), password = TextEditingController();
  bool busy = false, hidden = true;

  @override
  void dispose() {
    email.dispose();
    token.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!key.currentState!.validate()) return;
    final s = DemoScope.of(context);
    if (s is! BackendStore) return;
    setState(() => busy = true);
    final raw = token.text.trim();
    final value = Uri.tryParse(raw)?.queryParameters['token'] ?? raw;
    final result = await s.resetPassword(
      email: email.text,
      token: value,
      password: password.text,
    );
    if (!mounted) return;
    setState(() => busy = false);
    if (result != null) {
      toast(context, result);
      return;
    }
    toast(context, 'غيّرت كلمة المرور. سجّل الدخول بها الآن.');
    Navigator.popUntil(context, (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('كلمة مرور جديدة'),
    body: Form(
      key: key,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: email,
            enabled: !busy,
            keyboardType: TextInputType.emailAddress,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
            validator: (v) =>
                (v ?? '').contains('@') ? null : 'أدخل بريدًا صالحًا',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: token,
            enabled: !busy,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              labelText: 'رمز الاستعادة أو رابط البريد',
            ),
            validator: (v) => (v ?? '').trim().isEmpty ? 'الرمز مطلوب' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: password,
            enabled: !busy,
            obscureText: hidden,
            decoration: InputDecoration(
              labelText: 'كلمة المرور الجديدة (10 أحرف على الأقل)',
              suffixIcon: IconButton(
                tooltip: 'إظهار كلمة المرور',
                onPressed: () => setState(() => hidden = !hidden),
                icon: Icon(hidden ? Icons.visibility : Icons.visibility_off),
              ),
            ),
            validator: (v) =>
                (v ?? '').length >= 10 ? null : 'أدخل 10 أحرف على الأقل',
          ),
          const SizedBox(height: 16),
          PrimaryButton('حفظ كلمة المرور', onPressed: busy ? null : submit),
        ],
      ),
    ),
  );
}
