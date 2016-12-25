// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart' as shelf;

/// Handles requests for PvP tourney data.
Future<shelf.Response> handle(shelf.Request request) async {
  final mainContent = {};
  mainContent['teams'] = _getJson('teams.json');
  mainContent['round-robin'] = _getJson('round_robin.json');
  mainContent['rankings'] = _getJson('rankings.json');
  mainContent['elimination'] = _getJson('elimination.json');
  mainContent.addAll(_getJson('definitions.json'));
  final body = JSON.encode(mainContent);
  final headers = {'content-type': 'application/json'};
  return new shelf.Response.ok(body, headers: headers);
}

Map _getJson(String fileName) {
  final jsonPath = path.join(path.dirname(Platform.script.toFilePath()), '..',
      'lib', 'data', fileName);
  final content = new File(jsonPath).readAsStringSync();
  return JSON.decode(content);
}
