import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_info.dart';
import '../../core/colors.dart';
import '../widgets/brand.dart';
import '../widgets/gold_button.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  Future<void> _openPaypal() async {
    final uri = Uri.parse(AppInfo.donatePaypalUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _copy(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label kopiert')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          const SectionLabel('INFO'),
          const SizedBox(height: 16),
          GoldPanel(
            child: Column(
              children: [
                const TdLogo(size: 120),
                const SizedBox(height: 8),
                const Text(
                  AppInfo.name,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 20,
                    letterSpacing: 2,
                    color: TdColors.gold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  AppInfo.tagline,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 10,
                    letterSpacing: 2.2,
                    color: TdColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  AppInfo.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 15,
                    color: TdColors.textMuted,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                _meta('ENTWICKLER', AppInfo.developer),
                const SizedBox(height: 6),
                _meta('VERSION', '${AppInfo.version} (${AppInfo.buildNumber})'),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const SectionLabel('SPENDE'),
          const SizedBox(height: 12),
          const Text(
            'TECH//DECK bleibt kostenlos und werbefrei. '
            'Wer die App unterstützen möchte, kann freiwillig etwas beitragen.',
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 15,
              color: TdColors.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          GoldButton(
            label: 'PAYPAL',
            icon: Icons.favorite_border,
            onTap: _openPaypal,
          ),
          const SizedBox(height: 14),
          _addr(context, 'Bitcoin', AppInfo.donateBtc),
          _addr(context, 'Ethereum', AppInfo.donateEth),
          _addr(context, 'Solana', AppInfo.donateSol),
          _addr(context, 'XRP', AppInfo.donateXrp),
          _addr(context, 'USDT (ERC-20)', AppInfo.donateUsdtErc20),
          const SizedBox(height: 16),
          const Text(
            'Keine Bezahlschranke. Keine Werbung. Danke, wenn du dabei bist.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Rajdhani',
              fontSize: 14,
              color: TdColors.textDim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(String k, String v) {
    return Row(
      children: [
        Text(
          k,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 10,
            letterSpacing: 1.6,
            color: TdColors.textDim,
          ),
        ),
        const Spacer(),
        Text(
          v,
          style: const TextStyle(
            fontFamily: 'Rajdhani',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: TdColors.text,
          ),
        ),
      ],
    );
  }

  Widget _addr(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GoldPanel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        glow: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 10,
                      letterSpacing: 1.4,
                      color: TdColors.gold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 13,
                      color: TdColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _copy(context, label, value),
              icon: const Icon(Icons.copy_rounded, color: TdColors.gold, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
