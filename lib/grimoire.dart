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
  const maxXbScore = 5475;
  const maxPsScore = 5515;
  final content = {
    'max-grimoire': {'xb': maxXbScore, 'ps': maxPsScore}
  };
  final db = await connect(params[param.DATABASE_URL]);
  List<dynamic> data;
  try {
    data = await db.query('SELECT * FROM ${Schema.TABLE_MAIN}').map((row) {
      final columns = row.toMap();
      final score = columns[Schema.MAIN_GRIMOIRE];
      final onXbox = columns[Schema.MAIN_ON_XBOX];
      final max = onXbox ? maxXbScore : maxPsScore;
      final percentage = (1000 * score / max).round() / 10;
      return {
        'name': columns[Schema.MAIN_GAMERTAG],
        'grimoire': score,
        'platform': onXbox ? 'xb' : 'ps',
        'percentage': percentage
      };
    }).toList();
  } finally {
    db.close();
  }
  data.sort((a, b) => b['percentage'] - a['percentage']);
  content['data'] = data;
  final body = JSON.encode(content);
  final headers = {'content-type': 'application/json'};
  return new shelf.Response.ok(body, headers: headers);
}
