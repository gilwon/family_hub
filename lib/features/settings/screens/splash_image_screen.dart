// lib/features/settings/screens/splash_image_screen.dart
// 스플래시 이미지 변경 설정 화면

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/utils/error_message.dart';
import '../../../core/utils/splash_prefs.dart';
import '../../splash/splash_screen.dart';

class SplashImageScreen extends StatefulWidget {
  const SplashImageScreen({super.key});

  @override
  State<SplashImageScreen> createState() => _SplashImageScreenState();
}

class _SplashImageScreenState extends State<SplashImageScreen> {
  String? _imagePath;
  bool _hasImage = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final path = await SplashPrefs.getImagePath();
    final exists = path != null && await File(path).exists();
    if (mounted) setState(() { _imagePath = path; _hasImage = exists; });
  }

  Future<void> _pickImage() async {
    final xFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xFile == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      // 앱 문서 디렉토리에 고정 이름으로 복사 (경로 영구 보존)
      final dir = await getApplicationDocumentsDirectory();
      final target = File('${dir.path}/splash.jpg');
      await File(xFile.path).copy(target.path);
      await SplashPrefs.setImagePath(target.path);

      if (mounted) {
        setState(() { _imagePath = target.path; _hasImage = true; });
        ShadToaster.of(context).show(
          const ShadToast(title: Text('커버 이미지가 변경되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('변경 실패'),
            description: Text(friendlyError(e)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetImage() async {
    if (_imagePath != null) {
      try {
        await File(_imagePath!).delete();
      } catch (_) {}
    }
    await SplashPrefs.clear();
    if (mounted) {
      setState(() { _imagePath = null; _hasImage = false; });
      ShadToaster.of(context).show(
        const ShadToast(title: Text('기본 이미지로 변경되었습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('커버 이미지'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 미리보기
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_hasImage)
                      Image.file(File(_imagePath!), fit: BoxFit.cover)
                    else
                      const SplashDefaultBackground(),
                    Container(color: Colors.black.withValues(alpha: 0.35)),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.home_outlined,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Family Hub',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '우리 가족의 공간',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 현재 상태 뱃지
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _hasImage ? '사용자 이미지' : '기본 이미지',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 앨범에서 선택
            ShadButton(
              width: double.infinity,
              onPressed: _isLoading ? null : _pickImage,
              child: _isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('앨범에서 선택'),
                      ],
                    ),
            ),

            // 기본 이미지로 복원
            if (_hasImage) ...[
              const SizedBox(height: 10),
              ShadButton.outline(
                width: double.infinity,
                onPressed: _resetImage,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restore_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('기본 이미지로 변경'),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Text(
              '선택한 이미지는 앱 실행 시 커버 이미지로 표시됩니다.\n이미지가 없으면 기본 그라데이션 배경이 사용됩니다.',
              style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.mutedForeground,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
