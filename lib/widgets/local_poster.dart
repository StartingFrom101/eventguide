
import 'dart:io';

import 'package:flutter/material.dart';

class LocalPoster extends StatelessWidget {
  final String path;
  final double height;

  const LocalPoster({
    super.key,
    required this.path,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return _placeholder();
    }

    final file = File(path);

    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snapshot) {
        if (snapshot.data != true) {
          return _placeholder();
        }

        return Image.file(
          file,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.deepPurple.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 52,
        color: Colors.deepPurple,
      ),
    );
  }
}
