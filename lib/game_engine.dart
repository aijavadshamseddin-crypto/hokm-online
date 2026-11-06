import 'dart:math';

enum Suit { clubs, diamonds, hearts, spades }

class PlayingCard {
  final Suit suit;
  final int rank; // 2..14 (Ace = 14)
  const PlayingCard(this.suit, this.rank);

  @override
  bool operator ==(Object other) =>
      other is PlayingCard && other.suit == suit && other.rank == rank;

  @override
  int get hashCode => Object.hash(suit, rank);

  String get label {
    const ranks = {11: 'J', 12: 'Q', 13: 'K', 14: 'A'};
    return '\${ranks[rank] ?? rank}';
  }
}

class HokmRuleException implements Exception {
  final String message;
  const HokmRuleException(this.message);
  @override
  String toString() => message;
}

class TrickResult {
  final int winnerSeat;
  const TrickResult(this.winnerSeat);
}

class HokmGame {
  final List<List<PlayingCard>> hands;
  final int hakemSeat;
  final List<PlayingCard> _remainingDeck;
  Suit? trump;
  int currentSeat;
  final List<Map<int, PlayingCard>> _trickHistory = [];
  final Map<int, PlayingCard> _currentTrick = {};
  int tricksTeam0 = 0;
  int tricksTeam1 = 0;
  bool isRoundOver = false;

  HokmGame._(this.hands, this.hakemSeat, this.currentSeat, this._remainingDeck);

  factory HokmGame.newGame({int? seed, int hakemSeat = 0}) {
    if (hakemSeat < 0 || hakemSeat > 3) {
      throw const HokmRuleException('جایگاه حاکم نامعتبر است');
    }
    final deck = <PlayingCard>[
      for (final suit in Suit.values)
        for (var rank = 2; rank <= 14; rank++) PlayingCard(suit, rank),
    ];
    deck.shuffle(seed == null ? Random() : Random(seed));
    final hands = List.generate(4, (_) => <PlayingCard>[]);
    // مرحله اول: فقط پنج کارت به حاکم داده می‌شود.
    hands[hakemSeat].addAll(deck.take(5));
    return HokmGame._(hands, hakemSeat, hakemSeat, deck.skip(5).toList());
  }

  bool get waitingForTrump => trump == null;
  int get dealtCardCount => hands.fold<int>(0, (sum, hand) => sum + hand.length);
  int get remainingCardCount => _remainingDeck.length;
  static int teamOf(int seat) => seat.isEven ? 0 : 1;
  int get completedTricks => _trickHistory.length;
  List<Map<int, PlayingCard>> get trickHistory =>
      _trickHistory.map((e) => Map<int, PlayingCard>.from(e)).toList();
  Map<int, PlayingCard> get currentTrick =>
      Map<int, PlayingCard>.from(_currentTrick);
  int? get roundWinnerTeam => isRoundOver
      ? (tricksTeam0 > tricksTeam1 ? 0 : 1)
      : null;

  void chooseTrump(int seat, Suit suit) {
    if (seat != hakemSeat) {
      throw const HokmRuleException('فقط حاکم می‌تواند حکم را انتخاب کند');
    }
    if (trump != null) throw const HokmRuleException('حکم قبلاً انتخاب شده است');
    if (hands[hakemSeat].length != 5 || _remainingDeck.length != 47) {
      throw const HokmRuleException('مرحله انتخاب حکم در وضعیت نامعتبر است');
    }

    trump = suit;

    // مرحله دوم: پنج کارت به هر بازیکن دیگر، به ترتیب ساعت‌گرد از نفر بعد حاکم.
    for (var offset = 1; offset < 4; offset++) {
      final seatToDeal = (hakemSeat + offset) % 4;
      hands[seatToDeal].addAll(_takeCards(5));
    }

    // مرحله سوم: ۳۲ کارت باقی‌مانده، در بسته‌های چهارتایی؛ هر بسته یک دور بین چهار نفر.
    while (_remainingDeck.isNotEmpty) {
      for (var offset = 0; offset < 4; offset++) {
        final seatToDeal = (hakemSeat + offset) % 4;
        hands[seatToDeal].addAll(_takeCards(4));
      }
    }
    currentSeat = hakemSeat;
  }

  List<PlayingCard> _takeCards(int count) {
    if (_remainingDeck.length < count) {
      throw const HokmRuleException('تعداد کارت‌های باقی‌مانده کافی نیست');
    }
    return _remainingDeck.sublist(0, count).toList()
      ..asMap().forEach((index, card) {
        _remainingDeck.remove(card);
      });
  }

  List<PlayingCard> legalCardsFor(int seat) {
    if (seat < 0 || seat > 3 || trump == null) return [];
    final hand = hands[seat];
    if (_currentTrick.isEmpty) return List.unmodifiable(hand);
    final leadSuit = _currentTrick.values.first.suit;
    final matching = hand.where((c) => c.suit == leadSuit).toList();
    return List.unmodifiable(matching.isNotEmpty ? matching : hand);
  }

  TrickResult? playCard(int seat, PlayingCard card) {
    if (trump == null) throw const HokmRuleException('ابتدا حکم باید انتخاب شود');
    if (isRoundOver) throw const HokmRuleException('این دور تمام شده است');
    if (seat != currentSeat) throw const HokmRuleException('نوبت این بازیکن نیست');
    if (!legalCardsFor(seat).contains(card)) {
      throw const HokmRuleException('این کارت مجاز نیست');
    }
    hands[seat].remove(card);
    _currentTrick[seat] = card;
    if (_currentTrick.length < 4) {
      currentSeat = (currentSeat + 1) % 4;
      return null;
    }

    final leadSuit = _currentTrick.values.first.suit;
    var winner = _currentTrick.keys.first;
    var winningCard = _currentTrick[winner]!;
    int strength(PlayingCard c) {
      if (c.suit == trump) return 100 + c.rank;
      if (c.suit == leadSuit) return c.rank;
      return -1;
    }
    for (final entry in _currentTrick.entries.skip(1)) {
      if (strength(entry.value) > strength(winningCard)) {
        winner = entry.key;
        winningCard = entry.value;
      }
    }
    _trickHistory.add(Map<int, PlayingCard>.from(_currentTrick));
    if (teamOf(winner) == 0) {
      tricksTeam0++;
    } else {
      tricksTeam1++;
    }
    _currentTrick.clear();
    currentSeat = winner;
    if (tricksTeam0 == 7 || tricksTeam1 == 7 || completedTricks == 13) {
      isRoundOver = true;
    }
    return TrickResult(winner);
  }
}