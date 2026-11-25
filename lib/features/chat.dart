import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.handle,
    required this.name,
    required this.seed,
  });
  final String handle, name;
  final int seed;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final input = TextEditingController();
  final scroll = ScrollController();

  void send() {
    final t = input.text.trim();
    if (t.isEmpty) return;
    context.store.sendChat(widget.handle, t);
    input.clear();
    Future.delayed(const Duration(milliseconds: 100), jump);
    Future.delayed(const Duration(milliseconds: 1600), jump);
  }

  void jump() {
    if (scroll.hasClients) {
      scroll.animateTo(
        scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final c = context.c;
    final msgs = s.chats[widget.handle] ?? [];
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          children: [
            Avatar(
              name: widget.name,
              seed: widget.seed,
              size: 38,
              online: true,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'Mutual wave • online',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: VC.green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => toast(
              context,
              'Handle sharing: tap their profile for links',
              icon: Icons.info_rounded,
              color: VC.gold,
            ),
            icon: const Icon(Icons.lock_open_rounded),
          ),
        ],
      ),
      body: Glow(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 90, 16, 12),
                itemCount: msgs.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Center(
                        child: Pill(
                          'Mutual wave unlocked 💜 private handles visible',
                          color: c.accent,
                        ),
                      ),
                    );
                  }
                  final m = msgs[i - 1];
                  return _Bubble(m);
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                decoration: BoxDecoration(
                  color: c.card,
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: input,
                        onSubmitted: (_) => send(),
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: 'Message…',
                          fillColor: c.card2,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(99),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(99),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(99),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Tap(
                      onTap: send,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          gradient: VC.brand,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
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

class _Bubble extends StatelessWidget {
  const _Bubble(this.m);
  final ChatMsg m;
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Align(
      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        constraints: BoxConstraints(maxWidth: context.screen.width * .74),
        decoration: BoxDecoration(
          gradient: m.mine ? VC.brand : null,
          color: m.mine ? null : c.card,
          border: m.mine ? null : Border.all(color: c.border),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(m.mine ? 20 : 5),
            bottomRight: Radius.circular(m.mine ? 5 : 20),
          ),
        ),
        child: Text(
          m.text,
          style: TextStyle(
            color: m.mine ? Colors.white : c.text,
            fontSize: 15,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
