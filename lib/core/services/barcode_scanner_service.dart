import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerService {
  /// Opens a high-performance native modal scanner dialog.
  /// Uses native system APIs (Vision on macOS) for ultra-fast detection.
  static Future<String?> scanBarcode(BuildContext context) async {
    // macOS permissions are usually handled by the OS when the camera is first accessed
    // provided the entitlements and Info.plist are correct.
    
    // Launch Native Scanner Dialog
    try {
      if (!context.mounted) return null;
      final result = await showDialog<String?>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _NativeScannerDialog(),
      );
      return result;
    } catch (e) {
      debugPrint('[BarcodeScannerService] Error opening scanner: $e');
      return null;
    }
  }
}

class _NativeScannerDialog extends StatefulWidget {
  const _NativeScannerDialog();

  @override
  State<_NativeScannerDialog> createState() => _NativeScannerDialogState();
}

class _NativeScannerDialogState extends State<_NativeScannerDialog> with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: [BarcodeFormat.all],
  );
  
  final TextEditingController _manualInputController = TextEditingController();
  bool _hasScanned = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    debugPrint('[NativeScanner] Initializing scanner controller...');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _manualInputController.dispose();
    _animationController.dispose();
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      for (final barcode in barcodes) {
        final code = barcode.rawValue ?? barcode.displayValue;
        debugPrint('[NativeScanner] Detect Event: count=${barcodes.length}');
        debugPrint('[NativeScanner] Barcode: raw=${barcode.rawValue}, display=${barcode.displayValue}, format=${barcode.format}');
        
        if (code != null && code.trim().isNotEmpty) {
          _hasScanned = true;
          debugPrint('[NativeScanner] SUCCESS: Found valid code "$code"');
          
          // Success Feedback
          HapticFeedback.heavyImpact();
          SystemSound.play(SystemSoundType.click);
          
          // Close with result
          if (mounted) {
            Navigator.of(context).pop(code.trim());
          }
          break;
        }
      }
    } else {
      debugPrint('[NativeScanner] Detect event fired but no barcodes in capture');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Container(
        width: 800,
        height: 700,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Slate 900
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 40,
              offset: const Offset(0, 20),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF818CF8), size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Enterprise Barcode Scanner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
            
            // Scanner Body
            Expanded(
              child: Stack(
                children: [
                  MobileScanner(
                    controller: controller,
                    onDetect: _onDetect,
                    fit: BoxFit.cover,
                  ),
                  Positioned.fill(
                    child: _ScannerOverlay(animation: _animationController),
                  ),
                  
                  // Internal Controls (Floating)
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Column(
                      children: [
                        _ControlButton(
                          icon: Icons.flash_on_rounded,
                          onPressed: () => controller.toggleTorch(),
                        ),
                        const SizedBox(height: 12),
                        _ControlButton(
                          icon: Icons.flip_camera_ios_rounded,
                          onPressed: () => controller.switchCamera(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer (Manual Entry & Hint)
            Container(
              padding: const EdgeInsets.all(24),
              color: const Color(0xFF1E293B), // Slate 800
              child: Column(
                children: [
                  const Text(
                    'Align barcode within the center frame for instant detection',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualInputController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Or type / paste barcode manually...',
                            hintStyle: const TextStyle(color: Color(0xFF64748B)),
                            prefixIcon: const Icon(Icons.keyboard_outlined, color: Color(0xFF818CF8)),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            isDense: true,
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              Navigator.of(context).pop(val.trim());
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () {
                          final text = _manualInputController.text.trim();
                          if (text.isNotEmpty) {
                            Navigator.of(context).pop(text);
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ControlButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  final Animation<double> animation;

  const _ScannerOverlay({required this.animation});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark Vignette with centered hole
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.6),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Center(
                child: Container(
                  width: 450,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Centered Frame Brackets
        Center(
          child: Container(
            width: 450,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.3), width: 1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                // Corner Brackets
                ..._buildCorners(),
                
                // Animated Scan Line
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Positioned(
                      top: 10 + (180 * animation.value),
                      left: 10,
                      right: 10,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF818CF8).withValues(alpha: 0.8),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                          gradient: const LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFF818CF8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCorners() {
    const double size = 30;
    const double thickness = 4;
    const Color color = Color(0xFF818CF8);

    return [
      // Top Left
      Positioned(top: 0, left: 0, child: _corner(size, thickness, color, tl: true)),
      // Top Right
      Positioned(top: 0, right: 0, child: _corner(size, thickness, color, tr: true)),
      // Bottom Left
      Positioned(bottom: 0, left: 0, child: _corner(size, thickness, color, bl: true)),
      // Bottom Right
      Positioned(bottom: 0, right: 0, child: _corner(size, thickness, color, br: true)),
    ];
  }

  Widget _corner(double size, double thickness, Color color, {bool tl = false, bool tr = false, bool bl = false, bool br = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: tl || tr ? BorderSide(color: color, width: thickness) : BorderSide.none,
          bottom: bl || br ? BorderSide(color: color, width: thickness) : BorderSide.none,
          left: tl || bl ? BorderSide(color: color, width: thickness) : BorderSide.none,
          right: tr || br ? BorderSide(color: color, width: thickness) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: tl ? const Radius.circular(12) : Radius.zero,
          topRight: tr ? const Radius.circular(12) : Radius.zero,
          bottomLeft: bl ? const Radius.circular(12) : Radius.zero,
          bottomRight: br ? const Radius.circular(12) : Radius.zero,
        ),
      ),
    );
  }
}
