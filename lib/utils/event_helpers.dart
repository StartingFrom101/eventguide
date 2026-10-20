
import 'package:flutter/material.dart';

const List<String> eventCategories = [
  'All',
  'Music',
  'Technology',
  'Education',
  'Sports',
  'Art',
  'Food',
  'Community',
  'Other',
];

IconData categoryIcon(String category) {
  switch (category) {
    case 'Music':
      return Icons.music_note;
    case 'Technology':
      return Icons.computer;
    case 'Education':
      return Icons.school;
    case 'Sports':
      return Icons.sports_soccer;
    case 'Art':
      return Icons.palette;
    case 'Food':
      return Icons.restaurant;
    case 'Community':
      return Icons.people;
    default:
      return Icons.event;
  }
}

String formatEventDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();

  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '$day/$month/$year at $hour:$minute';
}
