import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// A reusable document upload field that opens the device gallery/files.
/// Shows a preview after selection. Returns the picked bytes via callback.
class DocumentUploadField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final ValueChanged<Uint8List?> onPicked;
  final bool isRequired;

  const DocumentUploadField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onPicked,
    this.isRequired = true,
  });

  @override
  State<DocumentUploadField> createState() => DocumentUploadFieldState();
}

class DocumentUploadFieldState extends State<DocumentUploadField> {
  Uint8List? _imageBytes;
  String? _fileName;
  bool _picking = false;
  final _picker = ImagePicker();

  bool get hasImage => _imageBytes != null;
  Uint8List? get imageBytes => _imageBytes;

  Future<void> _pickImage() async {
    setState(() => _picking = true);
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _fileName = file.name;
        });
        widget.onPicked(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _removeImage() {
    setState(() {
      _imageBytes = null;
      _fileName = null;
    });
    widget.onPicked(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(widget.icon, size: 18, color: const Color(0xFF0F2850)),
          const SizedBox(width: 8),
          Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          if (widget.isRequired) const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _picking ? null : _pickImage,
          child: Container(
            width: double.infinity,
            height: _imageBytes != null ? 160 : 100,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _imageBytes != null ? const Color(0xFF4AB3F4) : const Color(0xFFDDE5F0),
                width: 1.5,
              ),
            ),
            child: _imageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(_imageBytes!, fit: BoxFit.cover),
                        // Overlay with file name and actions
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                              ),
                            ),
                            child: Row(children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 18),
                              const SizedBox(width: 6),
                              Expanded(child: Text(_fileName ?? 'Image selected', style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis)),
                              GestureDetector(
                                onTap: _pickImage,
                                child: const Icon(Icons.refresh, color: Colors.white, size: 18),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _removeImage,
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _picking ? Icons.hourglass_top : Icons.cloud_upload_outlined,
                        size: 32,
                        color: _picking ? Colors.black38 : const Color(0xFF4AB3F4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _picking ? 'Opening gallery...' : widget.hint,
                        style: const TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text('Tap to select from gallery or files', style: TextStyle(color: Colors.black38, fontSize: 11)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
