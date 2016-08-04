// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:io' show Platform;

import 'package:bungie_client/bungie_client.dart';
import 'package:logging/logging.dart';
import 'package:postgresql/postgresql.dart';

import '../lib/schema.dart';

const _MEMBER_ACTIVITY_THRESHOLD = const Duration(days: 30 * 6);

final _log = new Logger('DataLoader');

/// Returns the value for [name] in the server configuration.
String _getConfigValue(String name) {
  final value = Platform.environment[name];
  if (value == null) {
    throw 'Missing configuration value for $name';
  }
  return value;
}

/// Creates a table of grimoire scores for clan members.
_loadGrimoire(Connection db, BungieClient client, String clanId) async {
  _log.info('Creating grimoire table...');
  final tableName = Schema.TABLE_GRIMOIRE;
  await db.execute('DROP TABLE IF EXISTS $tableName');
  await db.execute('CREATE TABLE $tableName ('
      '${Schema.GRIMOIRE_GAMERTAG} TEXT, '
      '${Schema.GRIMOIRE_SCORE} BIGINT, '
      '${Schema.GRIMOIRE_ON_XBOX} BOOLEAN)');
  final cutoff = new DateTime.now().subtract(_MEMBER_ACTIVITY_THRESHOLD);
  Future<int> getGrimoire(bool onXbox) async {
    final members = await client.getClanRoster(clanId, onXbox);
    final counts = await Future.wait(members.map((member) async {
      final profile = await client.getPlayerProfile(member.id);
      if (profile.lastPlayedCharacter.lastPlayed.isBefore(cutoff)) {
        return 0;
      }
      await db.execute('INSERT INTO $tableName VALUES ('
          '\$\$${member.gamertag}\$\$, '
          '${profile.grimoire}, '
          '${onXbox ? 'TRUE' : 'FALSE'})');
      return 1;
    }));
    return counts.fold(0, (x, y) => x + y);
  }
  final xbCount = await getGrimoire(true);
  final psCount = await getGrimoire(false);
  _log.info('Grimoire table complete; $xbCount XB users, $psCount PSN users.');
}

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.loggerName}: ${rec.message}');
  });
  final dbUrl = _getConfigValue('DATABASE_URL');
  final clanId = _getConfigValue('BUNGIE_CLAN_ID');
  final client = new BungieClient(_getConfigValue('BUNGIE_API_KEY'));
  final db = await connect(dbUrl);
  try {
    await _loadGrimoire(db, client, clanId);
  } finally {
    db.close();
  }
}
