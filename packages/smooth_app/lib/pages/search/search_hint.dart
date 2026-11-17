import 'package:flutter/material.dart';
import 'package:smooth_app/generic_lib/design_constants.dart';

/// Empty-state hint of the search page (Apple style: centred, quiet).
class SearchHint extends StatelessWidget {
  const SearchHint({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          top: 56.0,
          start: LARGE_SPACE * 2,
          end: LARGE_SPACE * 2,
        ),
        child: Column(
          children: <Widget>[
            const Icon(
              Icons.search_rounded,
              size: 44.0,
              color: Color(0xFF8E8E93),
            ),
            const SizedBox(height: 14.0),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.3,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
