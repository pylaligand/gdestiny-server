// Copyright (c) 2016 P.Y. Laligand

import 'dart:io' show Platform;
import 'dart:async' show runZoned;

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_route/shelf_route.dart';

main() {
  final log = new Logger('gDestinyServer');
  final portEnv = Platform.environment['PORT'];
  final port = portEnv == null ? 9999 : int.parse(portEnv);

  final commandRouter = router()
    ..get('/', (_) => new shelf.Response.ok('This is the gDestiny server!'));

  final handler = const shelf.Pipeline().addHandler(commandRouter.handler);

  runZoned(() {
    log.info('Serving on port $port');
    printRoutes(commandRouter, printer: log.info);
    io.serve(handler, '0.0.0.0', port);
  }, onError: (e, stackTrace) => log.severe('Oh noes! $e $stackTrace'));
}
