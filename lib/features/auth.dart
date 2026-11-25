import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

Future<void> _fakeProvider(
  BuildContext context,
  String provider,
  String email,
) async {
  final store = context.store;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => Center(
      child: Box(
        pad: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: VC.violet),
            const SizedBox(height: 18),
            Text(
              'Connecting to $provider…',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await Future.delayed(const Duration(milliseconds: 1100));
  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  store.signIn(email);
}

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget provider(
      String label,
      Widget icon,
      VoidCallback onTap, {
      bool filled = false,
    }) => Tap(
      onTap: onTap,
      child: Container(
        height: 56,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: filled ? (c.dark ? Colors.white : Colors.black) : c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15.5,
                color: filled ? (c.dark ? Colors.black : Colors.white) : c.text,
              ),
            ),
          ],
        ),
      ),
    );
    return Scaffold(
      body: Glow(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Reveal(child: VLogo(size: 44)),
                const SizedBox(height: 40),
                Reveal(
                  i: 1,
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 38,
                        height: 1.08,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                        color: c.text,
                      ),
                      children: const [
                        TextSpan(text: 'Your digital\nidentity, '),
                        TextSpan(
                          text: 'one QR.',
                          style: TextStyle(color: VC.fuchsia),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Reveal(
                  i: 2,
                  child: Text(
                    'Sign in to build your card in under 45 seconds.',
                    style: TextStyle(color: c.sub, fontSize: 15.5),
                  ),
                ),
                const SizedBox(height: 36),
                Reveal(
                  i: 3,
                  child: Column(
                    children: [
                      provider(
                        'Continue with Google',
                        const Text(
                          'G',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                            color: Color(0xFF4285F4),
                          ),
                        ),
                        () => _fakeProvider(
                          context,
                          'Google',
                          'kavishan@gmail.com',
                        ),
                      ),
                      provider(
                        'Continue with Apple',
                        Icon(
                          Icons.apple,
                          color: c.dark ? Colors.black : Colors.white,
                          size: 24,
                        ),
                        () => _fakeProvider(
                          context,
                          'Apple',
                          'kavishan@icloud.com',
                        ),
                        filled: true,
                      ),
                      provider(
                        'Mobile number + OTP',
                        Icon(Icons.sms_rounded, color: VC.green, size: 22),
                        () => pushPage(context, const PhoneAuthPage()),
                      ),
                      provider(
                        'Email & password',
                        Icon(
                          Icons.alternate_email_rounded,
                          color: c.accent,
                          size: 22,
                        ),
                        () => pushPage(context, const EmailAuthPage()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        color: c.sub,
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: 'By continuing you agree to our '),
                        TextSpan(
                          text: 'Terms',
                          style: TextStyle(
                            color: c.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: c.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── email ─────────────────────────
class EmailAuthPage extends StatefulWidget {
  const EmailAuthPage({super.key});
  @override
  State<EmailAuthPage> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends State<EmailAuthPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(), pass = TextEditingController();
  bool signup = true, hide = true, busy = false, sent = false;

  int get strength {
    final p = pass.text;
    var s = 0;
    if (p.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) s++;
    if (RegExp(r'\d').hasMatch(p)) s++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    return s;
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    if (signup) {
      setState(() {
        busy = false;
        sent = true;
      });
    } else {
      final store = context.store;
      Navigator.of(context).popUntil((r) => r.isFirst);
      store.signIn(email.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (sent) return _verify(context);
    final strengthLabels = ['Too short', 'Weak', 'Okay', 'Good', 'Strong'];
    final strengthColors = [c.sub, VC.red, VC.orange, VC.gold, VC.green];
    return Scaffold(
      appBar: AppBar(title: Text(signup ? 'Create account' : 'Welcome back')),
      body: Glow(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: form,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    signup ? 'Let\'s get you set up' : 'Log in to VibeDrop',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    signup
                        ? 'We\'ll send a verification link to your email.'
                        : 'Enter your details to continue.',
                    style: TextStyle(color: c.sub),
                  ),
                  const FormLabel('Email'),
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'you@example.com',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: (v) =>
                        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v ?? '')
                        ? null
                        : 'Enter a valid email address',
                  ),
                  const FormLabel('Password'),
                  TextFormField(
                    controller: pass,
                    obscureText: hide,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'At least 8 characters',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hide
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                        ),
                        onPressed: () => setState(() => hide = !hide),
                      ),
                    ),
                    validator: (v) => (v ?? '').length >= 8
                        ? null
                        : 'Use at least 8 characters',
                  ),
                  if (signup) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (var i = 0; i < 4; i++)
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              height: 5,
                              margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                              decoration: BoxDecoration(
                                color: i < strength
                                    ? strengthColors[strength]
                                    : c.border,
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strengthLabels[strength],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: strengthColors[strength],
                      ),
                    ),
                  ],
                  if (!signup)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            pushPage(context, ForgotPage(initial: email.text)),
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: c.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 22),
                  GradBtn(
                    signup ? 'Create account' : 'Log in',
                    loading: busy,
                    onTap: submit,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => signup = !signup),
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(color: c.sub),
                          children: [
                            TextSpan(
                              text: signup
                                  ? 'Already have an account? '
                                  : 'New here? ',
                            ),
                            TextSpan(
                              text: signup ? 'Log in' : 'Create account',
                              style: TextStyle(
                                color: c.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _verify(BuildContext context) {
    final c = context.c;
    return Scaffold(
      appBar: AppBar(),
      body: Glow(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: VC.brand,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_rounded,
                    size: 52,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Check your inbox',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  'We sent a verification link to\n${email.text.trim()}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.sub, height: 1.5, fontSize: 15),
                ),
                const SizedBox(height: 36),
                GradBtn(
                  'I\'ve verified my email',
                  icon: Icons.verified_rounded,
                  onTap: () {
                    final store = context.store;
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    store.signIn(email.text.trim());
                  },
                ),
                const SizedBox(height: 12),
                SoftBtn(
                  'Resend email',
                  icon: Icons.refresh_rounded,
                  onTap: () => toast(
                    context,
                    'Verification link sent again',
                    icon: Icons.mail_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ForgotPage extends StatefulWidget {
  const ForgotPage({super.key, this.initial = ''});
  final String initial;
  @override
  State<ForgotPage> createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  late final email = TextEditingController(text: widget.initial);
  bool sent = false, busy = false;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: Glow(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: sent
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.mark_email_unread_rounded,
                        size: 72,
                        color: VC.violet,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Reset link sent',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Open the email we sent to ${email.text} and follow the link.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: c.sub),
                      ),
                      const SizedBox(height: 28),
                      GradBtn(
                        'Back to login',
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Forgot your password?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your email and we\'ll send you a reset link.',
                        style: TextStyle(color: c.sub),
                      ),
                      const FormLabel('Email'),
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'you@example.com',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 24),
                      GradBtn(
                        'Send reset link',
                        loading: busy,
                        onTap: () async {
                          if (!email.text.contains('@')) {
                            toast(
                              context,
                              'Enter a valid email',
                              icon: Icons.error_rounded,
                              color: VC.red,
                            );
                            return;
                          }
                          setState(() => busy = true);
                          await Future.delayed(
                            const Duration(milliseconds: 900),
                          );
                          if (mounted) setState(() => sent = true);
                        },
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── phone + OTP ─────────────────────────
class PhoneAuthPage extends StatefulWidget {
  const PhoneAuthPage({super.key});
  @override
  State<PhoneAuthPage> createState() => _PhoneAuthPageState();
}

class _PhoneAuthPageState extends State<PhoneAuthPage> {
  final phone = TextEditingController();
  bool whatsapp = true;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final valid = phone.text.replaceAll(RegExp(r'\D'), '').length >= 9;
    return Scaffold(
      appBar: AppBar(title: const Text('Mobile sign-in')),
      body: Glow(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What\'s your number?',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'We\'ll send a 6-digit code to verify it\'s you.',
                  style: TextStyle(color: c.sub),
                ),
                const FormLabel('Mobile number'),
                Row(
                  children: [
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.border),
                      ),
                      child: const Row(
                        children: [
                          Text('🇱🇰', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 8),
                          Text(
                            '+94',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: phone,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => setState(() {}),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                          LengthLimitingTextInputFormatter(12),
                        ],
                        decoration: const InputDecoration(
                          hintText: '77 123 4567',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Send code via',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: c.sub,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Segment(
                  items: const ['WhatsApp', 'SMS'],
                  index: whatsapp ? 0 : 1,
                  onChanged: (i) => setState(() => whatsapp = i == 0),
                ),
                const Spacer(),
                GradBtn(
                  'Send code',
                  onTap: valid
                      ? () => pushPage(
                          context,
                          OtpPage(
                            number: '+94 ${phone.text.trim()}',
                            whatsapp: whatsapp,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OtpPage extends StatefulWidget {
  const OtpPage({super.key, required this.number, required this.whatsapp});
  final String number;
  final bool whatsapp;
  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  String code = '';
  int secs = 30;
  bool wrong = false, busy = false;
  Timer? t;

  @override
  void initState() {
    super.initState();
    t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (secs > 0 && mounted) setState(() => secs--);
    });
  }

  @override
  void dispose() {
    t?.cancel();
    super.dispose();
  }

  Future<void> press(String k) async {
    if (busy) return;
    setState(() {
      wrong = false;
      if (k == '<') {
        if (code.isNotEmpty) code = code.substring(0, code.length - 1);
      } else if (code.length < 6) {
        code += k;
      }
    });
    if (code.length == 6) {
      setState(() => busy = true);
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      if (code == '123456') {
        final store = context.store;
        Navigator.of(context).popUntil((r) => r.isFirst);
        store.signIn(widget.number);
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          wrong = true;
          code = '';
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      appBar: AppBar(title: const Text('Verify')),
      body: Glow(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              children: [
                Text(
                  'Enter the 6-digit code sent via ${widget.whatsapp ? 'WhatsApp' : 'SMS'} to',
                  style: TextStyle(color: c.sub),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.number,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 6; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 46,
                        height: 58,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: wrong
                                ? VC.red
                                : (i == code.length ? VC.violet : c.border),
                            width: i == code.length || wrong ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          i < code.length ? code[i] : '',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                if (wrong)
                  const Text(
                    'That code isn\'t right. Try again.',
                    style: TextStyle(
                      color: VC.red,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  Pill(
                    'Demo code: 123456',
                    icon: Icons.info_outline_rounded,
                    color: c.accent,
                  ),
                const SizedBox(height: 12),
                secs > 0
                    ? Text(
                        'Resend code in 0:${secs.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: c.sub,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : TextButton(
                        onPressed: () => setState(() => secs = 30),
                        child: Text(
                          'Resend code',
                          style: TextStyle(
                            color: c.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                const Spacer(),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: CircularProgressIndicator(color: VC.violet),
                  ),
                for (final row in const [
                  ['1', '2', '3'],
                  ['4', '5', '6'],
                  ['7', '8', '9'],
                  ['', '0', '<'],
                ])
                  Row(
                    children: [
                      for (final k in row)
                        Expanded(
                          child: k.isEmpty
                              ? const SizedBox(height: 62)
                              : Tap(
                                  onTap: () => press(k),
                                  child: SizedBox(
                                    height: 62,
                                    child: Center(
                                      child: k == '<'
                                          ? const Icon(Icons.backspace_outlined)
                                          : Text(
                                              k,
                                              style: const TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                    ),
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
