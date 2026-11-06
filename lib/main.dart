import 'package:flutter/material.dart';
import 'game_engine.dart';

void main() => runApp(const HokmApp());

class HokmApp extends StatelessWidget {
  const HokmApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'حکم آنلاین',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D6B52), brightness: Brightness.dark),
      useMaterial3: true,
      fontFamily: 'sans-serif',
    ),
    home: const HomePage(),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF123D35), Color(0xFF071B19)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.style, size: 76, color: Color(0xFFE6C878)),
                const SizedBox(height: 18),
                const Text('حکم', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('بازی چهار نفره', style: TextStyle(color: Colors.white70, fontSize: 17)),
                const SizedBox(height: 34),
                _MenuButton(label: 'بازی آزمایشی', icon: Icons.play_arrow, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LocalGamePage()));
                }),
                const SizedBox(height: 12),
                const _MenuButton(label: 'بازی با دوستان — به‌زودی', icon: Icons.people, enabled: false),
                const SizedBox(height: 12),
                const _MenuButton(label: 'بازی آنلاین عمومی — به‌زودی', icon: Icons.public, enabled: false),
                const SizedBox(height: 30),
                const Text('نسخه آزمایشی ۰٫۳', style: TextStyle(color: Colors.white54)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;
  const _MenuButton({required this.label, required this.icon, this.onTap, this.enabled = true});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity, height: 56,
    child: FilledButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon), label: Text(label),
      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB8944D), foregroundColor: Colors.black87),
    ),
  );
}

class LocalGamePage extends StatefulWidget {
  const LocalGamePage({super.key});
  @override
  State<LocalGamePage> createState() => _LocalGamePageState();
}

class _LocalGamePageState extends State<LocalGamePage> {
  late HokmGame game;
  @override
  void initState() { super.initState(); _newGame(); }
  void _newGame() { game = HokmGame.newGame(seed: DateTime.now().millisecondsSinceEpoch); }
  String _suit(Suit s) => switch (s) { Suit.clubs => '♣', Suit.diamonds => '♦', Suit.hearts => '♥', Suit.spades => '♠' };
  @override
  Widget build(BuildContext context) {
    final hand = game.hands[game.currentSeat];
    return Scaffold(
      appBar: AppBar(title: const Text('بازی آزمایشی حکم'), actions: [
        IconButton(onPressed: () => setState(_newGame), icon: const Icon(Icons.refresh), tooltip: 'شروع دوباره'),
      ]),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text('تیم شما: ${game.tricksTeam0}  —  تیم رقیب: ${game.tricksTeam1}', style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 12),
          if (game.trump == null) ...[
            const Text('انتخاب خال حکم', style: TextStyle(fontSize: 20)),
            Wrap(spacing: 8, children: Suit.values.map((s) => FilledButton(
              onPressed: () => setState(() => game.chooseTrump(game.hakemSeat, s)),
              child: Text(_suit(s), style: const TextStyle(fontSize: 24)),
            )).toList()),
          ] else ...[
            Text('حکم: ${_suit(game.trump!)}   |   نوبت صندلی ${game.currentSeat + 1}'),
            const SizedBox(height: 24),
            const Text('کارت‌های بازیکن نوبت', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: game.legalCardsFor(game.currentSeat).map((card) => OutlinedButton(
              onPressed: () => setState(() { game.playCard(game.currentSeat, card); }),
              child: Text('${card.label} ${_suit(card.suit)}', style: TextStyle(fontSize: 18, color: card.suit == Suit.hearts || card.suit == Suit.diamonds ? Colors.redAccent : null)),
            )).toList()),
            const Spacer(),
            Text('دست‌های تکمیل‌شده: ${game.completedTricks}'),
            if (game.isRoundOver) Text('برنده تیم ${game.roundWinnerTeam! + 1}', style: const TextStyle(fontSize: 24)),
          ],
        ]),
      ),
    );
  }
}
