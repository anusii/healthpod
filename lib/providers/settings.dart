import 'package:flutter_riverpod/flutter_riverpod.dart';

final serverURLProvider =
    StateProvider<String>((ref) => 'https://pods.dev.solidcommunity.au');
final usernameProvider = StateProvider<String>((ref) => '');
final passwordProvider = StateProvider<String>((ref) => '');
final secretKeyProvider = StateProvider<String>((ref) => '');
