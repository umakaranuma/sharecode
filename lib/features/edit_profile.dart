import 'dart:math';
import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'links.dart';
import 'me.dart';
import 'pro.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final Profile me = context.store.me;
  late final name = TextEditingController(text: me.name);
  late final bio = TextEditingController(text: me.bio);
  late final campus = TextEditingController(text: me.campus);
  late final phone = TextEditingController(text: me.phone);
  late final phone2 = TextEditingController(text: me.phone2);
  late final email = TextEditingController(text: me.email);
  late final company = TextEditingController(text: me.company);
  late final desig = TextEditingController(text: me.designation);
  late String city = me.city;
  late bool saveContact = me.saveContact;
  bool dirty = false;
  final form = GlobalKey<FormState>();

  void mark() {
    if (!dirty) setState(() => dirty = true);
  }

  void save() {
    if (!form.currentState!.validate()) return;
    me
      ..name = name.text.trim()
      ..bio = bio.text.trim()
      ..campus = campus.text.trim()
      ..phone = phone.text.trim()
      ..phone2 = phone2.text.trim()
      ..email = email.text.trim()
      ..company = company.text.trim()
      ..designation = desig.text.trim()
      ..city = city
      ..saveContact = saveContact;
    context.store.touch();
    setState(() => dirty = false);
    toast(context, 'Profile saved');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.store;
    final c = context.c;
    final maxGallery = s.pro ? 9 : 3;
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await confirm(
          context,
          'Discard changes?',
          'Your edits haven\'t been saved.',
          ok: 'Discard',
          danger: true,
        )) {
          nav.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit profile'),
          actions: [
            TextButton(
              onPressed: dirty ? save : null,
              child: Text(
                'Save',
                style: TextStyle(
                  color: dirty ? c.accent : c.sub,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        body: Glow(
          child: Form(
            key: form,
            onChanged: mark,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 60),
              children: [
                SizedBox(
                  height: 190,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        bottom: 40,
                        child: Tap(
                          onTap: () {
                            pickCover(context);
                          },
                          child: Scenic(seed: me.coverSeed, radius: 24),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        bottom: 0,
                        child: Tap(
                          onTap: () async {
                            final r = await pickAvatar(
                              context,
                              me.name,
                              me.avatarSeed,
                              me.emoji,
                            );
                            if (r != null) {
                              me
                                ..avatarSeed = r.$1
                                ..emoji = r.$2;
                              s.touch();
                            }
                          },
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: c.bg,
                                  shape: BoxShape.circle,
                                ),
                                child: Avatar(
                                  name: me.name,
                                  seed: me.avatarSeed,
                                  emoji: me.emoji,
                                  size: 96,
                                ),
                              ),
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    gradient: VC.brand,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: c.bg, width: 3),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 14,
                                    color: Colors.white,
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
                const FormLabel('Display name'),
                TextFormField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Name is required' : null,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                const FormLabel('Tagline / bio'),
                TextFormField(
                  controller: bio,
                  maxLength: 150,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Say something in English, தமிழ் or සිංහල',
                  ),
                ),
                const FormLabel('City'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final x in [
                      'Jaffna',
                      'Colombo',
                      'Kandy',
                      'Galle',
                      'Other',
                    ])
                      ChoiceChip(
                        label: Text(x),
                        selected: city == x,
                        showCheckmark: false,
                        selectedColor: VC.violet,
                        backgroundColor: c.card,
                        side: BorderSide(color: c.border),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: city == x ? Colors.white : c.text,
                        ),
                        onSelected: (_) {
                          setState(() => city = x);
                          mark();
                        },
                      ),
                  ],
                ),
                const FormLabel('Campus / badge (optional)'),
                TextFormField(
                  controller: campus,
                  decoration: const InputDecoration(
                    hintText: 'e.g. UoJ',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                ),
                SectionTitle(
                  'Photo gallery',
                  sub:
                      '${me.gallery.length}/$maxGallery photos${s.pro ? '' : ' • Pro unlocks 9'}',
                ),
                SizedBox(
                  height: 92,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (var i = 0; i < me.gallery.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Stack(
                            children: [
                              SizedBox(
                                width: 92,
                                height: 92,
                                child: Scenic(seed: me.gallery[i], radius: 18),
                              ),
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Tap(
                                  onTap: () {
                                    me.gallery.removeAt(i);
                                    s.touch();
                                    mark();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Tap(
                        onTap: () {
                          if (me.gallery.length >= maxGallery) {
                            pushPage(
                              context,
                              const ProPage(reason: 'Up to 9 gallery photos'),
                            );
                            return;
                          }
                          me.gallery.add(Random().nextInt(40) + 10);
                          s.touch();
                          mark();
                        },
                        child: Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: c.card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: VC.violet.withValues(alpha: .5),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_rounded,
                                color: c.accent,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add',
                                style: TextStyle(
                                  color: c.accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SectionTitle(
                  'Social & platform links',
                  sub: 'Hold & drag to reorder',
                  action: '+ Add',
                  onAction: () => editLinkSheet(context),
                ),
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  proxyDecorator: (child, _, _) => Material(
                    color: Colors.transparent,
                    elevation: 8,
                    shadowColor: VC.violet,
                    borderRadius: BorderRadius.circular(22),
                    child: child,
                  ),
                  onReorderItem: (a, b) {
                    s.reorderLinks(a, b);
                    mark();
                  },
                  children: [
                    for (var i = 0; i < me.links.length; i++)
                      Padding(
                        key: ValueKey(me.links[i].id),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Box(
                          pad: 10,
                          onTap: () =>
                              editLinkSheet(context, link: me.links[i]),
                          child: Row(
                            children: [
                              ReorderableDragStartListener(
                                index: i,
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.drag_indicator_rounded,
                                    color: c.sub,
                                  ),
                                ),
                              ),
                              PlatformBadge(me.links[i].meta, size: 42),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      me.links[i].meta.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      me.links[i].display,
                                      style: TextStyle(
                                        color: c.sub,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.edit_outlined, size: 18, color: c.sub),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                if (me.links.isEmpty)
                  Box(
                    child: Center(
                      child: Text(
                        'No links yet — add your first one',
                        style: TextStyle(color: c.sub),
                      ),
                    ),
                  ),
                const SectionTitle(
                  'Contact card (vCard)',
                  sub: 'Shown in Work / Campus mode',
                ),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Primary mobile',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phone2,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Secondary number',
                    prefixIcon: Icon(Icons.phone_android_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      (v ?? '').isEmpty ||
                          RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!)
                      ? null
                      : 'Enter a valid email',
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: company,
                  decoration: const InputDecoration(
                    labelText: 'Company / university',
                    prefixIcon: Icon(Icons.apartment_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: desig,
                  decoration: const InputDecoration(
                    labelText: 'Designation',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                Box(
                  pad: 14,
                  child: Row(
                    children: [
                      RoundIconBg(
                        Icons.contact_page_rounded,
                        VC.green,
                        size: 40,
                        radius: 12,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Allow 1-tap save to contacts',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Switch(
                        value: saveContact,
                        onChanged: (v) {
                          setState(() => saveContact = v);
                          mark();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GradBtn(
                  'Save changes',
                  icon: Icons.check_rounded,
                  onTap: dirty ? save : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
