import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingField extends ConsumerWidget {
  final String label;
  final String hint;
  final StateProvider<String> provider;
  final bool isPassword;
  final String tooltip;

  const SettingField({
    super.key,
    required this.label,
    required this.hint,
    required this.provider,
    this.isPassword = false,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(provider);

    Future<void> saveSetting(String value) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(label.toLowerCase().replaceAll(' ', '_'), value);
    }

    return MarkdownTooltip(
      message: tooltip,
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                width: 120, // Fixed width for label
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: value)
                    ..selection = TextSelection.collapsed(offset: value.length),
                  obscureText: isPassword,
                  onChanged: (value) {
                    ref.read(provider.notifier).state = value;
                    saveSetting(value);
                  },
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: hint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
