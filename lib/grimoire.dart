// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';

import 'package:postgresql/postgresql.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'params.dart' as param;
import 'schema.dart';

/// Handles requests for grimoire score.
Future<shelf.Response> handle(shelf.Request request) async {
  final params = request.context;
  final content = {
    'max-grimoire': {'xb': 4980, 'ps': 5020}
  };
  final db = await connect(params[param.DATABASE_URL]);
  try {
    content['data'] = await db
        .query(
            'SELECT * FROM ${Schema.TABLE_MAIN} ORDER BY ${Schema.MAIN_GRIMOIRE} DESC')
        .map((row) {
      final columns = row.toMap();
      return {
        'name': columns[Schema.MAIN_GAMERTAG],
        'grimoire': columns[Schema.MAIN_GRIMOIRE],
        'platform': columns[Schema.MAIN_ON_XBOX] ? 'xb' : 'ps'
      };
    }).toList();
  } finally {
    db.close();
  }
  final body = JSON.encode(content);
  final headers = {'content-type': 'application/json'};
  return new shelf.Response.ok(body, headers: headers);
}
