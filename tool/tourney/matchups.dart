// Copyright (c) 2016 P.Y. Laligand

import 'dart:math';

import 'package:quiver/iterables.dart' as iter;

/// Represents of matchup.
/// Indices represent the teams in a way that's transparent to the scheduling
/// algorithm.
class Matchup {
  final int homeIndex;
  final int awayIndex;

  const Matchup(this.homeIndex, this.awayIndex);
}

/// Generates a list of matchdays in a round-robin fashion.
List<List<Matchup>> generate(int nTeams) {
  if (nTeams.isOdd) {
    throw 'Only even numbers of teams are supported!';
  }

  final randomizer = new Random();
  Matchup _getMatchup(int teamA, int teamB) {
    final firstIsHome = randomizer.nextBool();
    return new Matchup(
        firstIsHome ? teamA : teamB, firstIsHome ? teamB : teamA);
  }

  // Team 1 to |nTeams - 1| are rotating.
  final rotatingIndices = new List.generate(nTeams - 1, (index) => index + 1);
  return new List.generate(nTeams - 1, (index) => index).map((matchday) {
    final firstTeams = new List.generate(
        (nTeams / 2).round() - 1,
        (index) =>
            rotatingIndices[(index - matchday) % rotatingIndices.length]);
    firstTeams.insert(0, 0); // Team 0 is always fixed in first place.

    final secondTeams = new List.generate(
        (nTeams / 2).round(),
        (index) => rotatingIndices[
            (rotatingIndices.length - index - matchday - 1) %
                rotatingIndices.length]);

    return iter.zip([firstTeams, secondTeams]).map(
        (teams) => _getMatchup(teams[0], teams[1]));
  });
}

/// Represents the parameters of a game.
class GameParams {
  final String type;
  final String map;
  final String modifier;

  const GameParams(this.type, this.map, this.modifier);

  @override
  String toString() => '$type{$map, $modifier}';
}

List<GameParams> createGames(
    int nGames, Map<String, String> mapsPerType, List<String> allModifiers) {
  final randomizer = new Random();
  final types = mapsPerType.keys.toList()..shuffle();
  final nTypes = mapsPerType.keys.length;
  final modifiers = new List.from(allModifiers)..shuffle();
  final nModifiers = modifiers.length;
  return new List.generate(nGames, (index) => index).map((index) {
    final type = types[index % nTypes];
    final maps = mapsPerType[type];
    final map = maps[randomizer.nextInt(maps.length)];
    final modifier = modifiers[index % nModifiers]['id'];
    return new GameParams(type, map, modifier);
  }).toList();
}
