// Copyright (c) 2016 P.Y. Laligand

import 'dart:async' show runZoned;
import 'dart:io' show Platform;

import 'package:bungie_client/bungie_client.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_route/shelf_route.dart';

import '../lib/grimoire.dart' as grimoire;
import '../lib/params.dart' as param;

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
    param.BUNGIE_CLAN_ID: _getConfigValue('BUNGIE_CLAN_ID')
  };

  final commandRouter = router()..get('/grimoire', grimoire.handle);

  final handler = const shelf.Pipeline()
      .addMiddleware(
          shelf.logRequests(logger: (String message, _) => log.info(message)))
      .addMiddleware((shelf.Handler handler) {
    // Injects common parameters for request handlers to use.
    return (shelf.Request request) {
      return handler(request.change(context: context));
    };
  }).addHandler(commandRouter.handler);

  runZoned(() {
    log.info('Serving on port $port');
    printRoutes(commandRouter, printer: log.info);
    io.serve(handler, '0.0.0.0', port);
  }, onError: (e, stackTrace) => log.severe('Oh noes! $e $stackTrace'));
}
