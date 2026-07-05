import 'package:flutter/material.dart';

class PreviewDocumentMessage extends StatelessWidget {
  const PreviewDocumentMessage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, color: Colors.grey, size: 32),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontFamily: 'Consolas',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
