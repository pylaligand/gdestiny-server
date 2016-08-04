// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';

import 'package:bungie_client/bungie_client.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'params.dart' as param;

/// Handles requests for grimoire score.
Future<shelf.Response> handle(shelf.Request request) async {
  final log = new Logger('Grimoire');
  final params = request.context;
  final BungieClient client = params[param.BUNGIE_CLIENT];
  final String clanId = params[param.BUNGIE_CLAN_ID];
  final content = {
    'max-grimoire': {'xb': 4980, 'ps': 5020}
  };
  final cutoff = new DateTime.now().subtract(const Duration(days: 6 * 30));
  log.info('Grimoire score; cutoff date: $cutoff');
  Future<List> getGrimoire(bool onXbox) async {
    final members = await client.getClanRoster(clanId, onXbox);
    return Future.wait(members.map((member) async {
      final profile = await client.getPlayerProfile(member.id);
      return profile.lastPlayedCharacter.lastPlayed.isAfter(cutoff)
          ? {
              'name': member.gamertag,
              'grimoire': profile.grimoire,
              'platform': onXbox ? 'xb' : 'ps'
            }
          : null;
    }));
  }
  final scores = [await getGrimoire(true), await getGrimoire(false)]
      .expand((x) => x)
      .where((member) => member != null)
      .toList();
  log.info('Got data for ${scores.length} clan members.');
  content['data'] = scores;
  final body = JSON.encode(content);
  final headers = {'content-type': 'application/json'};
  return new shelf.Response.ok(body, headers: headers);
}
