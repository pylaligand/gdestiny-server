// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart' as shelf;

/// Handles requests for PvP tourney data.
Future<shelf.Response> handle(shelf.Request request) async {
  final jsonPath = path.join(path.dirname(Platform.script.toFilePath()), '..',
      'lib', 'tournament.json');
  final body = new File(jsonPath).readAsStringSync();
  final headers = {'content-type': 'application/json'};
  return new shelf.Response.ok(body, headers: headers);
}
