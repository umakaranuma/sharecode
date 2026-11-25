import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/qr_view.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'home.dart';

class MerchPage extends StatelessWidget {
  const MerchPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final c = context.c;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order physical QR'),
        actions: [
          TextButton(
            onPressed: () => pushPage(context, const OrdersPage()),
            child: Text(
              'Orders${s.orders.isEmpty ? '' : ' (${s.orders.length})'}',
              style: TextStyle(color: c.accent, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Glow(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: VC.sunset,
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Take your QR offline',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Your dynamic link is auto-added to every print. Update your profile anytime — no reprint needed.',
                          style: TextStyle(
                            color: Colors.white70,
                            height: 1.4,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(
                    Icons.local_shipping_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                ],
              ),
            ),
            const SectionTitle('Choose a product'),
            for (final p in merch)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Box(
                  pad: 14,
                  onTap: () => pushPage(context, ProductPage(p: p)),
                  child: Row(
                    children: [
                      _Art(p: p, size: 96),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Pill(p.tag, color: VC.orange),
                            const SizedBox(height: 8),
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              p.desc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: c.sub,
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'LKR ${fmt(p.price)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: c.accent,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Art extends StatelessWidget {
  const _Art({required this.p, this.size = 96});
  final MerchProduct p;
  final double size;
  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final cfg = QrConfig(frame: false, showAvatar: false);
    final qr = VibeQr(
      data: 'https://${s.me.url}',
      cfg: cfg,
      me: s.me,
      size: size * .6,
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: p.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * .24),
      ),
      child: Center(
        child: switch (p.id) {
          'sticker' => Container(
            padding: EdgeInsets.all(size * .05),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
            ),
            child: ClipOval(child: qr),
          ),
          'keychain' => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: size * .16,
                height: size * .16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
              Container(
                padding: EdgeInsets.all(size * .04),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SizedBox(
                  width: size * .5,
                  height: size * .5,
                  child: FittedBox(child: qr),
                ),
              ),
            ],
          ),
          _ => Container(
            width: size * .82,
            height: size * .54,
            padding: EdgeInsets.all(size * .05),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0B10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                Icon(Icons.nfc_rounded, color: Colors.white70, size: size * .2),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(3),
                  color: Colors.white,
                  child: SizedBox(
                    width: size * .3,
                    height: size * .3,
                    child: FittedBox(child: qr),
                  ),
                ),
              ],
            ),
          ),
        },
      ),
    );
  }
}

class ProductPage extends StatefulWidget {
  const ProductPage({super.key, required this.p});
  final MerchProduct p;
  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  int qty = 1;
  int finish = 0;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final p = widget.p;
    final total = p.price * qty;
    final finishes = p.id == 'card'
        ? ['Matte Black', 'Metal Silver', 'Gold']
        : ['Glossy', 'Matte', 'Holographic'];
    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: Glow(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  Center(
                    child: Hero(
                      tag: p.id,
                      child: _Art(p: p, size: 220),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Pill(p.tag, color: VC.orange),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(p.desc, style: TextStyle(color: c.sub, height: 1.45)),
                  const FormLabel('Finish'),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (var i = 0; i < finishes.length; i++)
                        ChoiceChip(
                          label: Text(finishes[i]),
                          selected: finish == i,
                          showCheckmark: false,
                          selectedColor: VC.violet,
                          backgroundColor: c.card,
                          side: BorderSide(color: c.border),
                          labelStyle: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: finish == i ? Colors.white : c.text,
                          ),
                          onSelected: (_) => setState(() => finish = i),
                        ),
                    ],
                  ),
                  const FormLabel('Quantity'),
                  Row(
                    children: [
                      _qtyBtn(
                        Icons.remove_rounded,
                        qty > 1 ? () => setState(() => qty--) : null,
                      ),
                      SizedBox(
                        width: 60,
                        child: Center(
                          child: Text(
                            '$qty',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      _qtyBtn(
                        Icons.add_rounded,
                        qty < 10 ? () => setState(() => qty++) : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Box(
                    child: Row(
                      children: [
                        const Icon(Icons.link_rounded, color: VC.violet),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Prints your link: ${context.store.me.url}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                MediaQuery.paddingOf(context).bottom + 14,
              ),
              decoration: BoxDecoration(
                color: c.card,
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(color: c.sub, fontSize: 12),
                      ),
                      Text(
                        'LKR ${fmt(total)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: GradBtn(
                      'Checkout',
                      icon: Icons.arrow_forward_rounded,
                      onTap: () => pushPage(
                        context,
                        OrderCheckoutPage(
                          p: p,
                          qty: qty,
                          finish: finishes[finish],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData i, VoidCallback? f) => Tap(
    onTap: f,
    child: Opacity(
      opacity: f == null ? .4 : 1,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: context.c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.c.border),
        ),
        child: Icon(i),
      ),
    ),
  );
}

class OrderCheckoutPage extends StatefulWidget {
  const OrderCheckoutPage({
    super.key,
    required this.p,
    required this.qty,
    required this.finish,
  });
  final MerchProduct p;
  final int qty;
  final String finish;
  @override
  State<OrderCheckoutPage> createState() => _OrderCheckoutPageState();
}

class _OrderCheckoutPageState extends State<OrderCheckoutPage> {
  final form = GlobalKey<FormState>();
  bool cod = true, busy = false;
  String district = 'Jaffna';

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final p = widget.p;
    final sub = p.price * widget.qty;
    const ship = 350;
    String? req(String? v) =>
        (v == null || v.trim().isEmpty) ? 'Required' : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery & payment')),
      body: Glow(
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            children: [
              Box(
                child: Row(
                  children: [
                    _Art(p: p, size: 56),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${p.name} × ${widget.qty}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            widget.finish,
                            style: TextStyle(color: c.sub, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'LKR ${fmt(sub)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const FormLabel('Full name'),
              TextFormField(
                initialValue: context.store.me.name,
                validator: req,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const FormLabel('Phone'),
              TextFormField(
                initialValue: '077 123 4567',
                keyboardType: TextInputType.phone,
                validator: req,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const FormLabel('Address'),
              TextFormField(
                validator: req,
                decoration: const InputDecoration(
                  hintText: 'No. 12, Hospital Road',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              const FormLabel('District'),
              DropdownButtonFormField<String>(
                initialValue: district,
                dropdownColor: c.card,
                items: [
                  for (final d in [
                    'Jaffna',
                    'Colombo',
                    'Kandy',
                    'Galle',
                    'Kilinochchi',
                    'Batticaloa',
                    'Other',
                  ])
                    DropdownMenuItem(value: d, child: Text(d)),
                ],
                onChanged: (v) => setState(() => district = v!),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.map_outlined),
                ),
              ),
              const FormLabel('Payment'),
              Row(
                children: [
                  Expanded(
                    child: _pay(
                      context,
                      Icons.payments_rounded,
                      'Cash on delivery',
                      cod,
                      () => setState(() => cod = true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _pay(
                      context,
                      Icons.credit_card_rounded,
                      'Card / LankaQR',
                      !cod,
                      () => setState(() => cod = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Box(
                child: Column(
                  children: [
                    _l('Subtotal', 'LKR ${fmt(sub)}'),
                    _l('Delivery', 'LKR $ship'),
                    const Divider1(),
                    _l('Total', 'LKR ${fmt(sub + ship)}', bold: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GradBtn(
                cod ? 'Place order' : 'Pay & place order',
                icon: Icons.check_rounded,
                loading: busy,
                onTap: () async {
                  if (!form.currentState!.validate()) return;
                  setState(() => busy = true);
                  await Future.delayed(const Duration(milliseconds: 1200));
                  if (!context.mounted) return;
                  final o = context.store.placeOrder(p, widget.qty);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => OrderDoneInfo(order: o)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _l(String a, String b, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
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
          ),
        ),
      ],
    ),
  );

  Widget _pay(
    BuildContext context,
    IconData i,
    String t,
    bool on,
    VoidCallback f,
  ) => Tap(
    onTap: f,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: on ? VC.violet.withValues(alpha: .14) : context.c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: on ? VC.violet : context.c.border,
          width: on ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(i, color: on ? context.c.accent : context.c.sub),
          const SizedBox(height: 6),
          Text(
            t,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
          ),
        ],
      ),
    ),
  );
}

class OrderDoneInfo extends StatelessWidget {
  const OrderDoneInfo({super.key, required this.order});
  final Order order;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      body: Glow(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                const Spacer(),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  builder: (_, v, _) => Transform.scale(
                    scale: v,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [VC.green, Color(0xFF16A34A)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 66,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                const Text(
                  'Order placed!',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order ${order.id} • ${order.product}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.sub),
                ),
                const SizedBox(height: 6),
                Text(
                  'Estimated delivery in 3–5 days',
                  style: TextStyle(color: c.sub),
                ),
                const Spacer(),
                GradBtn(
                  'Track my order',
                  icon: Icons.local_shipping_rounded,
                  onTap: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const OrdersPage()),
                  ),
                ),
                const SizedBox(height: 10),
                SoftBtn(
                  'Back to home',
                  onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final c = context.c;
    const steps = ['Placed', 'Printing', 'Shipped', 'Delivered'];
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: Glow(
        child: s.orders.isEmpty
            ? Center(
                child: Text('No orders yet', style: TextStyle(color: c.sub)),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                children: [
                  for (final o in s.orders)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Box(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    o.product,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Text(
                                  'LKR ${fmt(o.total)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${o.id} • ${o.date}',
                              style: TextStyle(color: c.sub, fontSize: 12.5),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                for (var i = 0; i < steps.length; i++) ...[
                                  Column(
                                    children: [
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: i <= o.status
                                              ? VC.brand
                                              : null,
                                          color: i <= o.status ? null : c.card2,
                                        ),
                                        child: Icon(
                                          i <= o.status
                                              ? Icons.check_rounded
                                              : Icons.circle,
                                          size: i <= o.status ? 16 : 7,
                                          color: i <= o.status
                                              ? Colors.white
                                              : c.sub,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        steps[i],
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: i <= o.status ? c.text : c.sub,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (i < steps.length - 1)
                                    Expanded(
                                      child: Container(
                                        height: 3,
                                        margin: const EdgeInsets.only(
                                          bottom: 18,
                                        ),
                                        color: i < o.status
                                            ? VC.violet
                                            : c.card2,
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
