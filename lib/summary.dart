// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';

import 'package:postgresql/postgresql.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'params.dart' as param;
import 'schema.dart';

/// Handles requests for aggregate stats.
Future<shelf.Response> handle(shelf.Request request) async {
  final params = request.context;
  final db = await connect(params[param.DATABASE_URL]);
  Map content = {};
  try {
    content['grimoire'] = {
      'xb': await _getAverageGrimoireScore(db, true),
      'ps': await _getAverageGrimoireScore(db, false)
    };
    content['triumphs'] = {
      'xb': await _getAverageTriumphsCompletion(db, true),
      'ps': await _getAverageTriumphsCompletion(db, false)
    };
  } finally {
    db.close();
  }
  final body = JSON.encode(content);
  final headers = {'content-type': 'application/json'};
  return new shelf.Response.ok(body, headers: headers);
}

/// Returns the average grimoire score for the given platform.
Future<int> _getAverageGrimoireScore(Connection db, bool onXbox) async {
  final row = await db
      .query(
          'SELECT AVG(${Schema.MAIN_GRIMOIRE}) FROM ${Schema.TABLE_MAIN} WHERE ${_getPlatformSelector(onXbox)}')
      .first;
  return num.parse(row[0]).round();
}

/// Returns the average Moments of Triumph completion for the given platform.
/// This excludes guardians who have not started their MoT campaign.
Future<int> _getAverageTriumphsCompletion(Connection db, bool onXbox) async {
  final row = await db
      .query(
          'SELECT AVG(${Schema.MAIN_MOT_PROGRESS}) FROM ${Schema.TABLE_MAIN} WHERE ${_getPlatformSelector(onXbox)} AND ${Schema.MAIN_MOT_PROGRESS}!=0')
      .first;
  return num.parse(row[0]).round();
}

String _getPlatformSelector(bool onXbox) {
  return onXbox ? Schema.MAIN_ON_XBOX : 'NOT(${Schema.MAIN_ON_XBOX})';
}