// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:logging/logging.dart';

import 'json.dart' as json;

/// Stats of a given guardian.
class Stats {
  final double kd;
  final int winPercentage;

  const Stats(this.kd, this.winPercentage);

  const Stats.invalid() : this(0.0, 0);

  bool get isValid => kd != 0.0 || winPercentage != 0;

  @override
  String toString() => '{$kd, $winPercentage}';
}

/// Client for the guardian.gg REST API.
class GuardianGgClient {
  /// Returns base PvP stats for the given player.
  Future<Stats> getPvPStats(String destinyId) async {
    final url = 'https://api.guardian.gg/v2/players/$destinyId';
    final data = await json.get(url, new Logger('GuardianGgClient'));
    const invalidStats = const Stats.invalid();
    if (data == null || data['statusCode'] != 200) {
      return invalidStats;
    }
    final List<Map> gameModes = data['data']['modes'].values;
    if (gameModes.isEmpty) {
      return invalidStats;
    }
    int getCount(String property) =>
        gameModes.map((mode) => mode[property]).reduce((int x, int y) => x + y);
    final kills = getCount('kills');
    final deaths = getCount('deaths');
    final games = getCount('gamesPlayed');
    final wins = getCount('wins');
    final kd = deaths > 0 ? (100 * kills / deaths).round() / 100 : 0.0;
    final winPercentage = games > 0 ? (100 * wins / games).round() : 0;
    return new Stats(kd, winPercentage);
  }
}
