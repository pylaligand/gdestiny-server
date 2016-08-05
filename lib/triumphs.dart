// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';

import 'package:postgresql/postgresql.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'params.dart' as param;
import 'schema.dart';

/// Handles requests for MoT progress.
Future<shelf.Response> handle(shelf.Request request) async {
  final params = request.context;
  final db = await connect(params[param.DATABASE_URL]);
  final rows = await db.query('SELECT * FROM ${Schema.TABLE_MAIN}').toList();
  final tiers =
      new Set.from(rows.map((row) => row.toMap()[Schema.MAIN_MOT_PROGRESS]));
  final content = new Map.fromIterable(tiers,
      key: (tier) => tier.toString(),
      value: (tier) => rows
          .where((row) => row.toMap()[Schema.MAIN_MOT_PROGRESS] == tier)
          .map((row) => row.toMap()[Schema.MAIN_GAMERTAG])
          .toList());
  final body = JSON.encode(content);
  final headers = {'content-type': 'application/json'};
  return new shelf.Response.ok(body, headers: headers);
}
