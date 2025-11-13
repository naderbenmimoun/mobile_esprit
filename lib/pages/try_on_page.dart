import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import '../services/tryon_api_service.dart';
import '../models/outfit.dart';
import '../models/tryon_history.dart';
import '../database/database_helper.dart';

class TryOnPage extends StatefulWidget {
  final Outfit outfit;
  const TryOnPage({super.key, required this.outfit});

  @override
  State<TryOnPage> createState() => _TryOnPageState();
}

class _TryOnPageState extends State<TryOnPage> {
  final db = DatabaseHelper.instance;
  File? userImage;
  Uint8List? generatedImage;
  bool loading = false;

  final TryOnApiService tryOnService = TryOnApiService();

  Future<void> pickUserImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final ext = picked.path.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png'].contains(ext)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a JPG or PNG image.')),
      );
      return;
    }

    setState(() {
      userImage = File(picked.path);
      generatedImage = null;
    });
  }

  Future<File> _getGarmentFileFromAsset(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final ext = assetPath.split('.').last;
    final file = File('${tempDir.path}/garment_${widget.outfit.id}.$ext');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file;
  }

  Future<void> generateTryOn() async {
    if (userImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your photo first.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final garmentFile = await _getGarmentFileFromAsset(widget.outfit.imagePath);
      final result = await tryOnService.generateTryOn(
        personImage: userImage!,
        productImage: garmentFile,
      );

      if (result != null) {
        setState(() => generatedImage = result);
        final savedPath = await _saveGeneratedImage(result);
        await _saveTryOnHistory(savedPath);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Try-on saved to history.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate try-on.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Future<String> _saveGeneratedImage(Uint8List imageBytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/tryon_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(imageBytes);
    return file.path;
  }

  Future<void> _saveTryOnHistory(String path) async {
    await db.addTryOnHistory(TryOnHistory(
      outfitId: widget.outfit.id,
      userImagePath: userImage!.path,
      generatedImagePath: path,
      triedAt: DateTime.now(),
    ));
  }

  Future<void> saveImageLocally() async {
    if (generatedImage == null) return;
    final path = await _saveGeneratedImage(generatedImage!);
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('✅ Image saved: $path')));
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = const Color(0xFFB388FF);
    final Color accent = const Color(0xFF9575CD);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: mainColor,
        foregroundColor: Colors.white,
        title: Text('Try-On: ${widget.outfit.name}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Outfit card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: mainColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(widget.outfit.imagePath,
                    height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),

            // User image upload area
            GestureDetector(
              onTap: pickUserImage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                height: 160,
                width: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: mainColor.withOpacity(0.4),
                    width: 3,
                  ),
                  gradient: LinearGradient(
                    colors: [mainColor.withOpacity(0.1), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: mainColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: userImage == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt,
                                size: 40, color: accent.withOpacity(0.7)),
                            const SizedBox(height: 8),
                            Text("Upload Photo",
                                style: TextStyle(
                                    color: accent, fontWeight: FontWeight.w600))
                          ],
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Image.file(userImage!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 25),

            // Try-On button
            ElevatedButton.icon(
              onPressed: loading ? null : generateTryOn,
              icon: const Icon(Icons.auto_fix_high),
              label: Text(loading ? "Generating..." : "Generate Try-On"),
              style: ElevatedButton.styleFrom(
                backgroundColor: mainColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                textStyle: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
            ),
            const SizedBox(height: 30),

            if (loading)
              Column(
                children: [
                  CircularProgressIndicator(color: accent),
                  const SizedBox(height: 10),
                  Text("Processing your image...", style: TextStyle(color: accent)),
                ],
              ),

            if (generatedImage != null && !loading) ...[
              const SizedBox(height: 25),
              Text("✨ Result Preview",
                  style: TextStyle(
                      color: accent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.memory(generatedImage!, fit: BoxFit.contain),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: saveImageLocally,
                icon: const Icon(Icons.download),
                label: const Text("Save Result"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
