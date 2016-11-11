// Copyright (c) 2016 P.Y. Laligand

import 'dart:async' show runZoned;
import 'dart:io' show Platform;

import 'package:bungie_client/bungie_client.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_route/shelf_route.dart';

import '../lib/grimoire.dart' as grimoire;
import '../lib/kd.dart' as kd;
import '../lib/params.dart' as param;
import '../lib/summary.dart' as summary;
import '../lib/tourney.dart' as tourney;
import '../lib/triumphs.dart' as triumphs;
import '../lib/wins.dart' as wins;

/// Returns the value for [name] in the server configuration.
String _getConfigValue(String name) {
  final value = Platform.environment[name];
  if (value == null) {
    throw 'Missing configuration value for $name';
  }
  return value;
}

main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.loggerName}: ${rec.message}');
  });

  final log = new Logger('gDestinyServer');
  final portEnv = Platform.environment['PORT'];
  final port = portEnv == null ? 9999 : int.parse(portEnv);

  final context = {
    param.BUNGIE_CLIENT: new BungieClient(_getConfigValue('BUNGIE_API_KEY')),
    param.BUNGIE_CLAN_ID: _getConfigValue('BUNGIE_CLAN_ID'),
    param.DATABASE_URL: _getConfigValue('DATABASE_URL')
  };

  final commandRouter = router()
    ..get('/grimoire', grimoire.handle)
    ..get('/triumphs', triumphs.handle)
    ..get('/summary', summary.handle)
    ..get('/kd', kd.handle)
    ..get('/wins', wins.handle)
    ..get('/tourney', tourney.handle);

  final handler = const shelf.Pipeline()
      .addMiddleware(
          shelf.logRequests(logger: (String message, _) => log.info(message)))
      .addMiddleware((shelf.Handler handler) {
    // Injects common parameters for request handlers to use.
    return (shelf.Request request) {
      return handler(request.change(context: context));
    };
  }).addMiddleware((shelf.Handler handler) {
    // Add access control headers.
    return (shelf.Request request) async {
      final shelf.Response response = await handler(request);
      return response.change(headers: {'Access-Control-Allow-Origin': '*'});
    };
  }).addHandler(commandRouter.handler);

  runZoned(() {
    log.info('Serving on port $port');
    printRoutes(commandRouter, printer: log.info);
    io.serve(handler, '0.0.0.0', port);
  }, onError: (e, stackTrace) => log.severe('Oh noes! $e $stackTrace'));
}
