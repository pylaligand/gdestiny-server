// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';

import 'package:postgresql/postgresql.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'params.dart' as param;
import 'schema.dart';

/// Handles requests for lighthouse trip count.
Future<shelf.Response> handle(shelf.Request request) async {
  final params = request.context;
  final db = await connect(params[param.DATABASE_URL]);
  List<Row> rows;
  try {
    rows = await db
        .query(
            'SELECT * FROM ${Schema.TABLE_MAIN} ORDER BY ${Schema.MAIN_LIGHTHOUSE_TRIPS} DESC')
        .toList();
  } finally {
    db.close();
  }
  final content = rows
      .where((row) => row.toMap()[Schema.MAIN_LIGHTHOUSE_TRIPS] > 0)
      .map((row) {
    final columns = row.toMap();
    return {
      'name': columns[Schema.MAIN_GAMERTAG],
      'count': columns[Schema.MAIN_LIGHTHOUSE_TRIPS],
      'platform': columns[Schema.MAIN_ON_XBOX] ? 'xb' : 'ps'
    };
  }).toList();
  final body = JSON.encode(content);
  final headers = {'content-type': 'application/json'};
  return new shelf.Response.ok(body, headers: headers);
}
