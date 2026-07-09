import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';

class CreateTicketPage extends ConsumerStatefulWidget {
  const CreateTicketPage({super.key});

  @override
  ConsumerState<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends ConsumerState<CreateTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'Jaringan';
  String _priority = 'medium';
  final List<XFile> _images = [];
  bool _loading = false;

  static const _categories = ['Jaringan', 'Hardware', 'Aplikasi', 'Email', 'Printer', 'Lainnya'];

  static const _priorities = [
    {'value': 'low', 'label': 'Rendah', 'desc': 'Tidak urgent'},
    {'value': 'medium', 'label': 'Sedang', 'desc': 'Perlu ditangani'},
    {'value': 'high', 'label': 'Tinggi', 'desc': 'Segera ditangani'},
  ];

  Future<void> _pickImage(ImageSource src) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: src, imageQuality: 70);
    if (file != null) setState(() => _images.add(file));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;

    List<Map<String, dynamic>> filesData = [];
    for (var f in _images) {
      filesData.add({
        'name': f.name,
        'bytes': await f.readAsBytes(),
      });
    }

    setState(() => _loading = true);
    final success = await ref.read(ticketListProvider.notifier).createTicket(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      priority: _priority,
      userId: user.id,
      userName: user.name,
      attachments: filesData,
    );
    setState(() => _loading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiket berhasil dibuat!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Tiket')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Judul Masalah *',
                  prefixIcon: Icon(Icons.title),
                  hintText: 'Deskripsikan masalah secara singkat',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              // Description
              TextFormField(
                controller: _descCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Detail *',
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Jelaskan masalah secara detail, langkah yang sudah dicoba, dll.',
                  alignLabelWithHint: true,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Deskripsi wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              // Category
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Kategori', prefixIcon: Icon(Icons.folder)),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              // Priority
              const Text('Prioritas', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: _priorities.map((p) {
                  final sel = _priority == p['value'];
                  Color c = p['value'] == 'high' ? Colors.red : p['value'] == 'medium' ? Colors.orange : Colors.green;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p['value']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel ? c.withValues(alpha: 0.15) : Colors.transparent,
                          border: Border.all(color: sel ? c : Colors.grey.shade300, width: sel ? 2 : 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Icon(sel ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: sel ? c : Colors.grey, size: 18),
                            const SizedBox(height: 4),
                            Text(p['label']!, style: TextStyle(color: sel ? c : null, fontWeight: sel ? FontWeight.bold : null, fontSize: 13)),
                            Text(p['desc']!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // Attachment
              const Text('Lampiran (Opsional)', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _AttachBtn(icon: Icons.camera_alt, label: 'Kamera', onTap: () => _pickImage(ImageSource.camera)),
                  const SizedBox(width: 12),
                  _AttachBtn(icon: Icons.photo_library, label: 'Galeri', onTap: () => _pickImage(ImageSource.gallery)),
                ],
              ),
              if (_images.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    itemBuilder: (_, i) => Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 80, height: 80,
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                          child: kIsWeb 
                              ? Image.network(_images[i].path, fit: BoxFit.cover) 
                              : Image.file(File(_images[i].path), fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 2, right: 10,
                          child: GestureDetector(
                            onTap: () => setState(() => _images.removeAt(i)),
                            child: Container(
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: Text(_loading ? 'Mengirim...' : 'Kirim Tiket', style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AttachBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
    );
  }
}