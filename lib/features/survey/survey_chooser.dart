import 'package:flutter/material.dart';
import 'package:healthpod/features/bp/survey.dart';
import 'package:healthpod/features/vaccination/survey.dart';

class SurveyChooser extends StatefulWidget {
  const SurveyChooser({super.key});

  @override
  State<SurveyChooser> createState() => _SurveyChooserState();
}

class _SurveyChooserState extends State<SurveyChooser> {
  Widget? _currentSurvey;

  @override
  Widget build(BuildContext context) {
    if (_currentSurvey != null) {
      return Column(
        children: [
          // Back button row
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentSurvey = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to Survey List'),
                ),
              ],
            ),
          ),
          // Survey content
          Expanded(
            child: _currentSurvey!,
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Choose a Survey',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          _SurveyOption(
            title: 'Blood Pressure',
            icon: Icons.favorite,
            color: Colors.red,
            onTap: () {
              setState(() {
                _currentSurvey = BPSurvey();
              });
            },
          ),
          const SizedBox(height: 16),
          _SurveyOption(
            title: 'Vaccinations',
            icon: Icons.vaccines,
            color: Colors.blue,
            onTap: () {
              setState(() {
                _currentSurvey = const VaccinationSurvey();
              });
            },
          ),
        ],
      ),
    );
  }
}

class _SurveyOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SurveyOption({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
