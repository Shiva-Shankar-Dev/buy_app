import 'package:flutter/material.dart';

void main() {
  // Test the search matching logic
  debugPrint("Testing search matching logic...");

  // Test cases
  final testCases = [
    {'text': 'television', 'query': 'tel', 'expected': true},
    {'text': 'smart television', 'query': 'tel', 'expected': true},
    {'text': 'electronics-television', 'query': 'tel', 'expected': true},
    {'text': 'digital television', 'query': 'tel', 'expected': true},
    {
      'text': 'hotel management',
      'query': 'tel',
      'expected': false,
    }, // 'tel' not at start
    {'text': 'television smart tv', 'query': 'smart', 'expected': true},
    {'text': 'smartphone', 'query': 'phone', 'expected': false}, // not at start
    {'text': 'phone case', 'query': 'phone', 'expected': true},
  ];

  for (var testCase in testCases) {
    final result = matchesSearch(
      testCase['text'] as String,
      testCase['query'] as String,
    );
    final expected = testCase['expected'] as bool;
    final status = result == expected ? '✅' : '❌';

    debugPrint(
      "$status '${testCase['text']}' + '${testCase['query']}' = $result (expected: $expected)",
    );
  }
}

bool matchesSearch(String text, String query) {
  if (text.isEmpty || query.isEmpty) return false;

  final textLower = text.toLowerCase().trim();
  final queryLower = query.toLowerCase().trim();

  // Check if the whole text starts with the query
  if (textLower.startsWith(queryLower)) return true;

  // Word-by-word prefix matching (only from start of words)
  final words = textLower.split(RegExp(r'\s+'));
  for (String word in words) {
    if (word.isNotEmpty && word.startsWith(queryLower)) {
      return true;
    }
  }

  // Segment prefix matching for compound words/categories
  final segments = textLower.split(RegExp(r'[,\-_\s]+'));
  for (String segment in segments) {
    if (segment.isNotEmpty && segment.startsWith(queryLower)) {
      return true;
    }
  }

  return false;
}
