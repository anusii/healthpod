/// Home Page Widget
//
// Time-stamp: <Friday 2025-02-21 08:30:05 +1100 Graham Williams>
//
/// Copyright (C) 2025, Software Innovation Institute, ANU
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://www.gnu.org/licenses/>.
///
/// Authors: Kevin Wang, Zheyuan Xu

library;

import 'package:flutter/material.dart';

import 'package:healthpod/widgets/avatar_name.dart';
import 'package:healthpod/widgets/manage_plan.dart';
import 'package:healthpod/widgets/next_appointment.dart';
import 'package:healthpod/widgets/number_appointments.dart';
import 'package:healthpod/widgets/personal_details.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _buildHeader() {
    return const Text(
      'Your Personal Health Data Management System',
      style: TextStyle(fontSize: 20, color: Colors.grey),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              const AvatarName(),
              const SizedBox(height: 16),
              const NextAppointment(),
              const SizedBox(height: 16),
              const ManagePlan(),
              const SizedBox(height: 16),
              const PersonalDetails(),
              const SizedBox(height: 16),
              const NumberAppointments(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(int index) {
    final List<Widget> gridItems = [
      Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          AvatarName(),
          SizedBox(height: 10),
          NumberAppointments(),
          SizedBox(height: 10),
          ManagePlan(),
        ],
      ),
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [NextAppointment()],
      ),
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [PersonalDetails()],
      ),
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400, minHeight: 220),
      child: gridItems[index],
    );
  }

  Widget _buildDesktopLayout(double maxWidth) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: maxWidth < 1200 ? 2 : 3,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                mainAxisExtent: 370,
              ),
              itemCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => _buildGridItem(index),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return constraints.maxWidth < 800
              ? _buildMobileLayout()
              : _buildDesktopLayout(constraints.maxWidth);
        },
      ),
    );
  }
}
