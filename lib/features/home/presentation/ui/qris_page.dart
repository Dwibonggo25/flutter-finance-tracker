import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../libraries/core/localization/app_localizations.dart';
import '../../../../libraries/core/localization/language_keys.dart';
import '../../../../libraries/core/theme/app_colors.dart';

class QrisPage extends StatefulWidget {
  const QrisPage({super.key});

  @override
  State<QrisPage> createState() => _QrisPageState();
}

class _QrisPageState extends State<QrisPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F8FC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          context.tr(LanguageKeys.qris),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF75D7E8), Color(0xFFE8F8FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
            children: [
              _QrisPanel(
                selectedTab: _selectedTab,
                onTabChanged: (index) => setState(() => _selectedTab = index),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: _selectedTab == 0
                      ? _MyQrContent(
                          key: const ValueKey('myQr'),
                          onAction: _showDemoNotice,
                        )
                      : _ScanQrContent(
                          key: const ValueKey('scanQr'),
                          onOpenCamera: _showDemoNotice,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDemoNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr(LanguageKeys.featureComingSoon)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _QrisPanel extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final Widget child;

  const _QrisPanel({
    required this.selectedTab,
    required this.onTabChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2B064F77),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _QrisTab(
                  label: context.tr(LanguageKeys.myQr),
                  selected: selectedTab == 0,
                  onTap: () => onTabChanged(0),
                ),
                _QrisTab(
                  label: context.tr(LanguageKeys.scanQr),
                  selected: selectedTab == 1,
                  onTap: () => onTabChanged(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}

class _QrisTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QrisTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: AppColors.primaryShadow,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF60717A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _MyQrContent extends StatelessWidget {
  final VoidCallback onAction;

  const _MyQrContent({super.key, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          context.tr(LanguageKeys.receivePayment),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF53636B),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: 254,
          height: 254,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFD6E0E5), width: 1.4),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              QrImageView(
                data: 'finance-project://qris/demo/dwi-bonggo',
                version: QrVersions.auto,
                size: 224,
                padding: EdgeInsets.zero,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF111A1E),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF111A1E),
                ),
              ),
              Container(height: 2, color: const Color(0xFFE43C45)),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'DWI BONGGO',
          style: TextStyle(
            color: Color(0xFF16262E),
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'NMID ID1020304050607',
          style: TextStyle(color: Color(0xFF77858C), fontSize: 12),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.share_outlined),
                label: Text(context.tr(LanguageKeys.share)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.download_rounded),
                label: Text(context.tr(LanguageKeys.download)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F7FA),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  context.tr(LanguageKeys.qrisDemoNotice),
                  style: const TextStyle(
                    color: Color(0xFF60717A),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanQrContent extends StatelessWidget {
  final VoidCallback onOpenCamera;

  const _ScanQrContent({super.key, required this.onOpenCamera});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          context.tr(LanguageKeys.pointCameraAtQr),
          style: const TextStyle(
            color: Color(0xFF53636B),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: const Color(0xFF16262E),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Color(0x6675D7E8),
                  size: 170,
                ),
              ),
              Center(
                child: Container(
                  width: 220,
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE43C45),
                    boxShadow: const [
                      BoxShadow(color: Color(0x99E43C45), blurRadius: 12),
                    ],
                  ),
                ),
              ),
              ..._scannerCorners,
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onOpenCamera,
            icon: const Icon(Icons.camera_alt_outlined),
            label: Text(context.tr(LanguageKeys.openCamera)),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> get _scannerCorners => const [
    _ScannerCorner(alignment: Alignment.topLeft, quarterTurns: 0),
    _ScannerCorner(alignment: Alignment.topRight, quarterTurns: 1),
    _ScannerCorner(alignment: Alignment.bottomRight, quarterTurns: 2),
    _ScannerCorner(alignment: Alignment.bottomLeft, quarterTurns: 3),
  ];
}

class _ScannerCorner extends StatelessWidget {
  final Alignment alignment;
  final int quarterTurns;

  const _ScannerCorner({required this.alignment, required this.quarterTurns});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: RotatedBox(
          quarterTurns: quarterTurns,
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF75D7E8), width: 4),
                left: BorderSide(color: Color(0xFF75D7E8), width: 4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
