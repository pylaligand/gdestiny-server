// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:postgresql/postgresql.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'params.dart' as param;
import 'schema.dart';

/// Handles requests for grimoire score.
Future<shelf.Response> handle(shelf.Request request) async {
  final log = new Logger('Grimoire');
  final params = request.context;
  final content = {
    'max-grimoire': {'xb': 4980, 'ps': 5020}
  };
  final db = await connect(params[param.DATABASE_URL]);
  final scores = await db
      .query(
          'SELECT * FROM ${Schema.TABLE_GRIMOIRE} ORDER BY ${Schema.GRIMOIRE_SCORE} DESC')
      .map((row) {
    final columns = row.toMap();
    return {
      'name': columns[Schema.GRIMOIRE_GAMERTAG],
      'grimoire': columns[Schema.GRIMOIRE_SCORE],
      'platform': columns[Schema.GRIMOIRE_ON_XBOX] ? 'xb' : 'ps'
    };
  }).toList();
  log.info('Got data for ${scores.length} clan members.');
  content['data'] = scores;
  final body = JSON.encode(content);
  final headers = {'content-type': 'application/json'};
  return new shelf.Response.ok(body, headers: headers);
}
