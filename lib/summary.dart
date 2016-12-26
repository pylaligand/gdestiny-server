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
    content['kd'] = {
      'xb': await _getAverageKd(db, true),
      'ps': await _getAverageKd(db, false)
    };
    content['win_percentage'] = {
      'xb': await _getAverageWinPercentage(db, true),
      'ps': await _getAverageWinPercentage(db, false)
    };
    content['lighthouse_trips'] = {
      'xb': await _getTotalLighthouseTrips(db, true),
      'ps': await _getTotalLighthouseTrips(db, false)
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

/// Returns the average K/D ratio for the given platform.
/// This excludes guardians who have not played PvP in the current season.
Future<double> _getAverageKd(Connection db, bool onXbox) async {
  final row = await db
      .query(
          'SELECT AVG(${Schema.MAIN_PVP_KD}) FROM ${Schema.TABLE_MAIN} WHERE ${_getPlatformSelector(onXbox)} AND ${Schema.MAIN_PVP_KD}!=0')
      .first;
  final double average = row[0];
  return average != null ? (100 * average).round() / 100 : 0.0;
}

/// Returns the average win percentage for the given platform.
/// This excludes guardians who have not played PvP in the current season.
Future<int> _getAverageWinPercentage(Connection db, bool onXbox) async {
  final row = await db
      .query(
          'SELECT AVG(${Schema.MAIN_PVP_WIN_PERCENTAGE}) FROM ${Schema.TABLE_MAIN} WHERE ${_getPlatformSelector(onXbox)} AND ${Schema.MAIN_PVP_WIN_PERCENTAGE}!=0')
      .first;
  final String average = row[0];
  return average != null ? num.parse(average).round() : 0;
}

/// Returns the total number of Lighthouse trips for the given platform.
Future<int> _getTotalLighthouseTrips(Connection db, bool onXbox) async {
  final row = await db
      .query(
          'SELECT SUM(${Schema.MAIN_LIGHTHOUSE_TRIPS}) FROM ${Schema.TABLE_MAIN} WHERE ${_getPlatformSelector(onXbox)}')
      .first;
  return num.parse(row[0]);
}

String _getPlatformSelector(bool onXbox) {
  return onXbox ? Schema.MAIN_ON_XBOX : 'NOT(${Schema.MAIN_ON_XBOX})';
}
