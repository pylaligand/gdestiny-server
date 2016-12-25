// Copyright (c) 2016 P.Y. Laligand

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'tourney/matchups.dart' as matchups;

const _FLAG_DEFINITIONS = 'definitions';
const _FLAG_GAME_COUNT = 'game-count';

main(List<String> args) async {
  final parser = new ArgParser()
    ..addOption(_FLAG_DEFINITIONS, help: 'Contains the various game options')
    ..addOption(_FLAG_GAME_COUNT, help: 'Number of games to generate');
  final params = parser.parse(args);
  if (!params.options.contains(_FLAG_DEFINITIONS) ||
      !params.options.contains(_FLAG_GAME_COUNT)) {
    print(parser.usage);
    exit(1);
  }

  final definitions =
      JSON.decode(new File(params[_FLAG_DEFINITIONS]).readAsStringSync());
  final count = int.parse(params[_FLAG_GAME_COUNT]);
  final games = matchups.createGames(
      count, definitions['maps'], definitions['modifiers']);
  print(new JsonEncoder.withIndent('  ').convert(games
      .map((game) => {
            'playlist': game.type,
            'map': game.map,
            'modifier': game.modifier,
            'id': ''
          })
      .toList()));
}
