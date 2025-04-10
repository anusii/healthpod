/// Sample app that demonstrates the usage of InAppWebView to display a web page within the app.
//
// Time-stamp: <Thursday 2024-12-19 13:33:06 +1100 Graham Williams>
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
/// Authors: Ashley Tang

library;

import 'package:flutter/material.dart';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// A Flutter application that demonstrates the usage of InAppWebView to display
/// a web page within the app. This implementation creates a simple browser
/// that loads a specific URL (like the Solid login browser page) and provides basic web viewing functionality.
///
/// The app uses the `flutter_inappwebview` package to render web content and
/// handle web browser functionality within the Flutter application.

// Entry point of application.

void main() {
  // Initialise Flutter bindings before running the app.
  // This is required for platform channel functionality.

  WidgetsFlutterBinding.ensureInitialized();

  runApp(const WebViewSampleApp());
}

/// Root widget of the application that sets up the basic app structure.

class WebViewSampleApp extends StatelessWidget {
  const WebViewSampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        // Creates an app bar with the title "InAppWebView Test".

        appBar: AppBar(title: const Text('InAppWebView Test')),

        // Sets main content area to our web view screen.

        body: const WebViewSampleAppScreen(),
      ),
    );
  }
}

/// Stateful widget that contains the InAppWebView implementation.
/// This widget handles the web view functionality and state management.

class WebViewSampleAppScreen extends StatefulWidget {
  const WebViewSampleAppScreen({super.key});

  @override
  State<WebViewSampleAppScreen> createState() => _WebViewSampleAppScreenState();
}

/// State class for InAppWebViewScreen that manages the web view controller
/// and builds the web view interface.

class _WebViewSampleAppScreenState extends State<WebViewSampleAppScreen> {
  // Controller for interacting with the web view.

  late InAppWebViewController webViewController;

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      // Sets the initial URL to load in the web view.

      initialUrlRequest:
          URLRequest(url: WebUri('https://pods.dev.solidcommunity.au')),

      // Configure initial settings for the web view.

      initialSettings: InAppWebViewSettings(
        // Enable JavaScript execution in the web view.

        javaScriptEnabled: true,
        // Disable transparent background for the web view.

        transparentBackground: false,
      ),
      // Callback triggered when the web view is created.
      // Stores the controller for later use.

      onWebViewCreated: (controller) {
        webViewController = controller;
      },
      // Callback triggered when the web page finishes loading.
      // Prints the loaded URL for debugging purposes.

      onLoadStop: (controller, url) {
        debugPrint('WebView Finished Loading: $url');
      },
    );
  }
}
