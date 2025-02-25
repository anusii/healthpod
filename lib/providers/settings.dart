import 'package:flutter_riverpod/flutter_riverpod.dart';

final serverURLProvider = StateProvider<String>((ref) => '');
final usernameProvider = StateProvider<String>((ref) => '');
final passwordProvider = StateProvider<String>((ref) => '');
final secretKeyProvider = StateProvider<String>((ref) => '');
