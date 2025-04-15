/// Profile provider for managing profile data.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.
///
/// Authors: Ashley Tang

library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:healthpod/constants/profile.dart';
import 'package:healthpod/utils/fetch_profile_data.dart';

/// Profile state class that holds the current profile data
class ProfileState {
  final Map<String, dynamic> profileData;
  final bool isLoading;
  final String? error;

  ProfileState({
    required this.profileData,
    this.isLoading = false,
    this.error,
  });

  /// Constructor for initial state
  factory ProfileState.initial() {
    return ProfileState(
      profileData: Map<String, dynamic>.from(defaultProfileData['data'] as Map<String, dynamic>),
      isLoading: false,
      error: null,
    );
  }

  /// Creates a copy of this state with specified values changed
  ProfileState copyWith({
    Map<String, dynamic>? profileData,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profileData: profileData ?? this.profileData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Profile notifier that manages profile state and operations
class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(ProfileState.initial());

  /// Refreshes profile data from the POD
  Future<void> refreshProfileData(BuildContext context) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Make sure context is still valid
      if (!context.mounted) {
        state = state.copyWith(isLoading: false);
        return;
      }
      
      final data = await fetchProfileData(context);
      
      // Check again if context is still valid after async operation
      if (!context.mounted) {
        state = state.copyWith(isLoading: false);
        return;
      }
      
      state = state.copyWith(
        profileData: data,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error refreshing profile data: $e');
      state = state.copyWith(
        isLoading: false, 
        error: 'Failed to load profile data: ${e.toString()}'
      );
    }
  }

  /// Updates specific profile field values
  void updateProfileField(String field, dynamic value) {
    final updatedData = Map<String, dynamic>.from(state.profileData);
    updatedData[field] = value;
    
    state = state.copyWith(profileData: updatedData);
  }
  
  /// Updates multiple profile fields at once
  void updateProfileFields(Map<String, dynamic> fields) {
    final updatedData = Map<String, dynamic>.from(state.profileData);
    updatedData.addAll(fields);
    
    state = state.copyWith(profileData: updatedData);
  }
}

/// Global provider for profile state
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier();
});