import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerService {
  /// Opens a high-performance native modal scanner dialog.
  /// Uses native system APIs (Vision on macOS) for ultra-fast detection.
  static Future<String?> scanBarcode(BuildContext context) async {
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
  final FocusNode _manualFocusNode = FocusNode();
  
  bool _hasScanned = false;
  late AnimationController _animationController;
  bool _showSuccessFlash = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[NativeScanner] Initializing enterprise scanner...');
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    // Auto-focus manual entry for physical scanner gun support
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _manualFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _manualFocusNode.dispose();
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
        
        if (code != null && code.trim().isNotEmpty) {
          _hasScanned = true;
          
          // Visual & Audio Feedback
          setState(() => _showSuccessFlash = true);
          HapticFeedback.heavyImpact();
          SystemSound.play(SystemSoundType.click);
          
          debugPrint('[NativeScanner] SUCCESS: Scanned "$code"');
          
          // Small delay to show the success flash before closing
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              Navigator.of(context).pop(code.trim());
            }
          });
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define the scan window coordinates (centered hole)
    // MobileScanner uses relative coordinates [0, 0, 1, 1] for scanWindow
    // For simplicity with BoxFit.cover, we can rely on standard detection 
    // but we visually guide the user.
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Container(
        width: 850,
        height: 750,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Slate 900
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 50,
              offset: const Offset(0, 25),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Header - Refined MNC Style
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B), // Slate 800
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF818CF8), size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Precision Barcode Scanner',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Native Vision System Active',
                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      hoverColor: Colors.white.withValues(alpha: 0.1),
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
                  
                  // Primary Overlay
                  Positioned.fill(
                    child: _ScannerOverlay(
                      animation: _animationController,
                      isSuccess: _showSuccessFlash,
                    ),
                  ),
                  
                  // High-End Control Panel (Floating)
                  Positioned(
                    top: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        children: [
                          _ControlButton(
                            icon: Icons.flash_on_rounded,
                            tooltip: 'Toggle Torch',
                            onPressed: () => controller.toggleTorch(),
                          ),
                          const SizedBox(height: 8),
                          _ControlButton(
                            icon: Icons.flip_camera_ios_rounded,
                            tooltip: 'Switch Camera',
                            onPressed: () => controller.switchCamera(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Footer - Optimized for Speed & Physical Scanners
            Container(
              padding: const EdgeInsets.all(32),
              color: const Color(0xFF0F172A), // Slate 900
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualInputController,
                          focusNode: _manualFocusNode,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'Ready for scanning or manual input...',
                            hintStyle: const TextStyle(color: Color(0xFF475569)),
                            prefixIcon: const Icon(Icons.keyboard_command_key_rounded, color: Color(0xFF6366F1), size: 20),
                            filled: true,
                            fillColor: const Color(0xFF1E293B),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                            ),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              Navigator.of(context).pop(val.trim());
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      FilledButton(
                        onPressed: () {
                          final text = _manualInputController.text.trim();
                          if (text.isNotEmpty) {
                            Navigator.of(context).pop(text);
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('Process', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 14),
                      SizedBox(width: 8),
                      Text(
                        'Supports EAN, UPC, QR, and standard physical laser scanners',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
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
  final String tooltip;
  final VoidCallback onPressed;

  const _ControlButton({required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
          ),
        ),
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  final Animation<double> animation;
  final bool isSuccess;

  const _ScannerOverlay({required this.animation, required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark Vignette with centered hole
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.7),
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
                  width: 480,
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Centered Frame Brackets
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 480,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(
                color: isSuccess 
                  ? const Color(0xFF10B981) 
                  : const Color(0xFF4F46E5).withValues(alpha: 0.4), 
                width: isSuccess ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(24),
              color: isSuccess ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.transparent,
            ),
            child: Stack(
              children: [
                // Corner Brackets
                ..._buildCorners(isSuccess),
                
                // Animated Scan Line
                if (!isSuccess)
                  AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) {
                      return Positioned(
                        top: 15 + (210 * animation.value),
                        left: 15,
                        right: 15,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF818CF8).withValues(alpha: 0.8),
                                blurRadius: 12,
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
                
                // Success Icon Center
                if (isSuccess)
                  const Center(
                    child: Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 64),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCorners(bool isSuccess) {
    const double size = 36;
    const double thickness = 5;
    final Color color = isSuccess ? const Color(0xFF10B981) : const Color(0xFF818CF8);

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
          topLeft: tl ? const Radius.circular(16) : Radius.zero,
          topRight: tr ? const Radius.circular(16) : Radius.zero,
          bottomLeft: bl ? const Radius.circular(16) : Radius.zero,
          bottomRight: br ? const Radius.circular(16) : Radius.zero,
        ),
      ),
    );
  }
}
