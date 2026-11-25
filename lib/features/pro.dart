import 'package:flutter/material.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class ProPage extends StatefulWidget {
  const ProPage({super.key, this.reason});
  final String? reason;
  @override
  State<ProPage> createState() => _ProPageState();
}

class _ProPageState extends State<ProPage> {
  int plan = 1; // 0 monthly, 1 yearly

  static const feats = [
    (
      Icons.tune_rounded,
      'Custom mode',
      'Choose exactly which links each person sees',
    ),
    (
      Icons.lock_rounded,
      'PIN & secret question lock',
      'Riddle or 4-digit PIN before links unlock',
    ),
    (
      Icons.timer_rounded,
      'Burner links',
      '24-hour self-destructing QR for events',
    ),
    (
      Icons.bar_chart_rounded,
      'Detailed analytics',
      'Daily graphs, city-level, devices & link clicks',
    ),
    (
      Icons.palette_rounded,
      'Premium QR styling',
      'Neon presets, liquid & diamond dots, logos',
    ),
    (
      Icons.photo_library_rounded,
      '9 gallery photos',
      'Up from 3 on the free plan',
    ),
    (
      Icons.description_rounded,
      'Vector SVG / PDF export',
      'Infinite-resolution for printing',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final c = context.c;
    if (s.pro) return _active(context);
    final price = plan == 0 ? 'LKR 590' : 'LKR 4,900';
    final per = plan == 0 ? '/ month' : '/ year';
    return Scaffold(
      body: Glow(
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    MediaQuery.paddingOf(context).top + 60,
                    24,
                    28,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF4C1D95),
                        Color(0xFF9333EA),
                        Color(0xFFEC4899),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          gradient: VC.proGrad,
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: [
                            BoxShadow(
                              color: VC.orange.withValues(alpha: .2),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'VibeDrop Pro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.reason == null
                            ? 'Unlock the full identity toolkit.'
                            : 'Unlock: ${widget.reason}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 260),
                  child: Column(
                    children: [
                      for (final f in feats)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(
                            children: [
                              RoundIconBg(
                                f.$1,
                                VC.orange,
                                size: 46,
                                radius: 15,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      f.$2,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15.5,
                                      ),
                                    ),
                                    Text(
                                      f.$3,
                                      style: TextStyle(
                                        color: c.sub,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.check_circle_rounded,
                                color: VC.green,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 14),
                      Box(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              color: VC.green,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Cancel anytime. Pay with Visa/Mastercard, Genie, FriMi, eZ Cash, LankaQR or in-app purchase.',
                                style: TextStyle(
                                  color: c.sub,
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // sticky purchase bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.paddingOf(context).bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  border: Border.all(color: c.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .25),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _planCard(
                            context,
                            0,
                            'Monthly',
                            'LKR 590',
                            '/ mo',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _planCard(
                            context,
                            1,
                            'Yearly',
                            'LKR 4,900',
                            '/ yr',
                            badge: 'Save 31%',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    GradBtn(
                      'Continue • $price $per',
                      icon: Icons.bolt_rounded,
                      gradient: VC.proGrad,
                      onTap: () => pushPage(context, CheckoutPage(plan: plan)),
                    ),
                    TextButton(
                      onPressed: () => toast(
                        context,
                        'No previous purchases found',
                        icon: Icons.info_rounded,
                        color: VC.gold,
                      ),
                      child: Text(
                        'Restore purchase',
                        style: TextStyle(
                          color: c.sub,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planCard(
    BuildContext context,
    int i,
    String t,
    String p,
    String per, {
    String? badge,
  }) {
    final c = context.c;
    final on = plan == i;
    return Tap(
      onTap: () => setState(() => plan = i),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(14),
            width: double.infinity,
            decoration: BoxDecoration(
              color: on ? VC.orange.withValues(alpha: .12) : c.card2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: on ? VC.orange : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t,
                  style: TextStyle(color: c.sub, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: p,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      TextSpan(
                        text: ' $per',
                        style: TextStyle(color: c.sub, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              right: 10,
              top: -10,
              child: Pill(badge, color: VC.green, filled: true),
            ),
        ],
      ),
    );
  }

  Widget _active(BuildContext context) {
    final s = context.store;
    final c = context.c;
    return Scaffold(
      appBar: AppBar(title: const Text('Pro')),
      body: Glow(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: VC.proGrad,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: VC.orange.withValues(alpha: .2),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'You\'re Pro! 🎉',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                '${s.proPlan} plan • renews automatically',
                style: TextStyle(color: c.sub),
              ),
              const SizedBox(height: 28),
              Box(
                child: Column(
                  children: [
                    for (final f in feats.take(4))
                      RowTile(
                        icon: f.$1,
                        title: f.$2,
                        color: VC.orange,
                        trailing: const Icon(
                          Icons.check_circle_rounded,
                          color: VC.green,
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              SoftBtn(
                'Cancel subscription',
                icon: Icons.cancel_outlined,
                color: VC.red,
                onTap: () async {
                  if (await confirm(
                    context,
                    'Cancel Pro?',
                    'You\'ll lose custom modes, PIN lock and analytics.',
                    ok: 'Cancel plan',
                    danger: true,
                  )) {
                    s.downgrade();
                    if (context.mounted) {
                      toast(
                        context,
                        'Pro cancelled',
                        icon: Icons.info_rounded,
                        color: VC.gold,
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.plan});
  final int plan;
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int method = 0;
  bool busy = false;
  final promo = TextEditingController();
  bool promoOk = false;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final base = widget.plan == 0 ? 590 : 4900;
    final total = promoOk ? (base * .8).round() : base;
    final methods = [
      (
        Icons.credit_card_rounded,
        'Card (Visa / Mastercard)',
        'via PayHere',
        VC.blue,
      ),
      (Icons.qr_code_2_rounded, 'LankaQR', 'Scan with any bank app', VC.violet),
      (
        Icons.phone_android_rounded,
        'Genie / FriMi / eZ Cash',
        'Mobile wallets',
        VC.green,
      ),
      (
        Icons.apple,
        'App Store / Google Play',
        'In-app purchase via RevenueCat',
        c.sub,
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Glow(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          children: [
            Box(
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: VC.proGrad,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VibeDrop Pro • ${widget.plan == 0 ? 'Monthly' : 'Yearly'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Billed ${widget.plan == 0 ? 'monthly' : 'annually'}',
                          style: TextStyle(color: c.sub),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'LKR $base',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SectionTitle('Payment method'),
            for (var i = 0; i < methods.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Box(
                  pad: 14,
                  color: method == i ? VC.violet.withValues(alpha: .12) : null,
                  onTap: () => setState(() => method = i),
                  child: Row(
                    children: [
                      RoundIconBg(
                        methods[i].$1,
                        methods[i].$4,
                        size: 42,
                        radius: 13,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              methods[i].$2,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              methods[i].$3,
                              style: TextStyle(color: c.sub, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        method == i
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: method == i ? VC.violet : c.sub,
                      ),
                    ],
                  ),
                ),
              ),
            const SectionTitle('Promo code'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: promo,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Try VIBE20',
                      suffixIcon: promoOk
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: VC.green,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 100,
                  child: SoftBtn(
                    'Apply',
                    height: 56,
                    onTap: () {
                      final ok = promo.text.trim().toUpperCase() == 'VIBE20';
                      setState(() => promoOk = ok);
                      toast(
                        context,
                        ok ? '20% discount applied' : 'Invalid promo code',
                        icon: ok
                            ? Icons.local_offer_rounded
                            : Icons.error_rounded,
                        color: ok ? VC.green : VC.red,
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Box(
              child: Column(
                children: [
                  _line('Subtotal', 'LKR $base'),
                  if (promoOk)
                    _line(
                      'Promo VIBE20',
                      '- LKR ${base - total}',
                      col: VC.green,
                    ),
                  const Divider1(),
                  _line('Total today', 'LKR $total', bold: true),
                ],
              ),
            ),
            const SizedBox(height: 22),
            GradBtn(
              'Pay LKR $total',
              icon: Icons.lock_rounded,
              loading: busy,
              onTap: () async {
                setState(() => busy = true);
                await Future.delayed(const Duration(milliseconds: 1600));
                if (!context.mounted) return;
                final store = context.store;
                store.upgrade(widget.plan == 0 ? 'Monthly' : 'Yearly');
                Navigator.of(context).popUntil((r) => r.isFirst);
                toast(
                  context,
                  'Welcome to VibeDrop Pro! 🎉',
                  icon: Icons.workspace_premium_rounded,
                  color: VC.gold,
                );
              },
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Demo checkout — no real payment is taken.',
                style: TextStyle(color: c.sub, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String a, String b, {bool bold = false, Color? col}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Text(
          a,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            fontSize: bold ? 17 : 15,
          ),
        ),
        const Spacer(),
        Text(
          b,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w700 : FontWeight.w700,
            fontSize: bold ? 17 : 15,
            color: col,
          ),
        ),
      ],
    ),
  );
}
