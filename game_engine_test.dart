import 'package:flutter_test/flutter_test.dart';
import 'package:hokm_online/game_engine.dart';

void main() {
  group('شروع بازی', () {
    test('ابتدا پنج کارت و پس از انتخاب حکم سیزده کارت به هر نفر می‌رسد', () {
      final game = HokmGame.newGame(seed: 42, hakemSeat: 0);
      expect(game.hands.length, 4);
      expect(game.hands.every((h) => h.length == 5), isTrue);

      game.chooseTrump(0, Suit.hearts);

      expect(game.hands.every((h) => h.length == 13), isTrue);
      expect(game.hands.expand((h) => h).toSet().length, 52);
    });

    test('بازیکنان روبه‌رو هم‌تیمی هستند', () {
      expect(HokmGame.teamOf(0), 0);
      expect(HokmGame.teamOf(2), 0);
      expect(HokmGame.teamOf(1), 1);
      expect(HokmGame.teamOf(3), 1);
    });
  });

  group('قوانین نوبت و حکم', () {
    test('فقط حاکم می‌تواند حکم را تعیین کند', () {
      final game = HokmGame.newGame(seed: 7, hakemSeat: 0);
      expect(
        () => game.chooseTrump(1, Suit.hearts),
        throwsA(isA<HokmRuleException>()),
      );
      game.chooseTrump(0, Suit.hearts);
      expect(game.trump, Suit.hearts);
    });

    test('پیش از تعیین حکم بازی کارت مجاز نیست', () {
      final game = HokmGame.newGame(seed: 8, hakemSeat: 0);
      final seat = game.currentSeat;
      expect(
        () => game.playCard(seat, game.hands[seat].first),
        throwsA(isA<HokmRuleException>()),
      );
    });

    test('پس از انتخاب حکم، حاکم آغازگر دست اول است', () {
      final game = HokmGame.newGame(seed: 9, hakemSeat: 0);
      game.chooseTrump(0, Suit.spades);
      expect(game.currentSeat, 0);
    });

    test('بازی خارج از نوبت رد می‌شود', () {
      final game = HokmGame.newGame(seed: 10, hakemSeat: 0);
      game.chooseTrump(0, Suit.spades);
      expect(
        () => game.playCard(1, game.hands[1].first),
        throwsA(isA<HokmRuleException>()),
      );
    });
  });

  test('بعد از چهار کارت یک دست ثبت و برنده آغازگر دست بعد می‌شود', () {
    final game = HokmGame.newGame(seed: 123, hakemSeat: 0);
    game.chooseTrump(0, Suit.spades);

    int? winner;
    for (var i = 0; i < 4; i++) {
      final seat = game.currentSeat;
      final card = game.legalCardsFor(seat).first;
      final result = game.playCard(seat, card);
      if (result != null) winner = result.winnerSeat;
    }

    expect(game.completedTricks, 1);
    expect(game.trickHistory.length, 1);
    expect(game.currentTrick, isEmpty);
    expect(game.currentSeat, winner);
    expect(game.hands.every((h) => h.length == 12), isTrue);
  });

  test('یک دور کامل با انتخاب کارت قانونی به پایان می‌رسد', () {
    final game = HokmGame.newGame(seed: 321, hakemSeat: 2);
    game.chooseTrump(2, Suit.diamonds);

    while (!game.isRoundOver) {
      for (var i = 0; i < 4 && !game.isRoundOver; i++) {
        final seat = game.currentSeat;
        final card = game.legalCardsFor(seat).first;
        game.playCard(seat, card);
      }
    }

    expect(game.roundWinnerTeam, anyOf(0, 1));
    expect(game.completedTricks, inInclusiveRange(7, 13));
    expect(game.tricksTeam0 + game.tricksTeam1, game.completedTricks);
  });

  test('در هر نوبت فقط کارت‌های قانونی نمایش داده می‌شوند', () {
    final game = HokmGame.newGame(seed: 15, hakemSeat: 0);
    game.chooseTrump(0, Suit.clubs);

    final firstSeat = game.currentSeat;
    final firstCard = game.hands[firstSeat].first;
    game.playCard(firstSeat, firstCard);

    final nextSeat = game.currentSeat;
    final nextHand = game.hands[nextSeat];
    final legal = game.legalCardsFor(nextSeat);
    final hasLeadSuit = nextHand.any((c) => c.suit == firstCard.suit);

    if (hasLeadSuit) {
      expect(legal.every((c) => c.suit == firstCard.suit), isTrue);
    } else {
      expect(legal.length, nextHand.length);
    }
  });
}
