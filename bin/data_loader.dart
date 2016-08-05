// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:io' show Platform;

import 'package:bungie_client/bungie_client.dart';
import 'package:logging/logging.dart';
import 'package:postgresql/postgresql.dart';

import '../lib/schema.dart';

const _MEMBER_ACTIVITY_THRESHOLD = const Duration(days: 30 * 6);

final _log = new Logger('DataLoader');

/// Data about a player.
class Guardian {
  final ClanMember member;
  final Profile profile;
  final int motProgress;

  Guardian(this.member, this.profile, this.motProgress);
}

/// Returns the value for [name] in the server configuration.
String _getConfigValue(String name) {
  final value = Platform.environment[name];
  if (value == null) {
    throw 'Missing configuration value for $name';
  }
  return value;
}

/// Loads the list of clan members with basic info.
Future<List<Guardian>> _getGuardians(BungieClient client, String clanId) async {
  final cutoff = new DateTime.now().subtract(_MEMBER_ACTIVITY_THRESHOLD);
  Future<List<Guardian>> loadPlatformGuardians(bool onXbox) async {
    final members = await client.getClanRoster(clanId, onXbox);
    return (await Future.wait(members.map((member) async {
      final profile = await client.getPlayerProfile(member.id);
      if (profile.lastPlayedCharacter.lastPlayed.isBefore(cutoff)) {
        return null;
      }
      final motProgress = await client.getTriumphsProgress(member.id);
      return new Guardian(member, profile, motProgress);
    })))
        .where((guardian) => guardian != null)
        .toList();
  }
  return [await loadPlatformGuardians(true), await loadPlatformGuardians(false)]
      .expand((x) => x);
}

/// Creates the main table with various data for clan members.
_createMainTable(Connection db, List<Guardian> guardians) async {
  _log.info('Creating main table...');
  final tableName = Schema.TABLE_MAIN;
  await db.execute('DROP TABLE IF EXISTS $tableName');
  await db.execute('CREATE TABLE $tableName ('
      '${Schema.MAIN_GAMERTAG} TEXT, '
      '${Schema.MAIN_GRIMOIRE} BIGINT, '
      '${Schema.MAIN_ON_XBOX} BOOLEAN, '
      '${Schema.MAIN_MOT_PROGRESS} BIGINT)');
  await Future.forEach(
      guardians,
      (Guardian guardian) async =>
          await db.execute('INSERT INTO $tableName VALUES ('
              '\$\$${guardian.member.gamertag}\$\$, '
              '${guardian.profile.grimoire}, '
              '${guardian.member.onXbox ? 'TRUE' : 'FALSE'}, '
              '${guardian.motProgress})'));
  _log.info('Main table complete');
}

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.loggerName}: ${rec.message}');
  });
  final clanId = _getConfigValue('BUNGIE_CLAN_ID');
  final client = new BungieClient(_getConfigValue('BUNGIE_API_KEY'));
  final db = await connect(_getConfigValue('DATABASE_URL'));
  try {
    _log.info('Loading guardian data...');
    final guardians = await _getGuardians(client, clanId);
    final xbCount =
        guardians.where((guardian) => guardian.member.onXbox).length;
    final psCount =
        guardians.where((guardian) => !guardian.member.onXbox).length;
    _log.info('$xbCount Xbox guardians, $psCount Playstation guardians');
    await _createMainTable(db, guardians);
  } finally {
    db.close();
  }
}
