import 'package:flutter/material.dart';

class ContenidoCentrado extends StatelessWidget {
  const ContenidoCentrado({super.key, required this.child});

  static const double anchoMaximo = 520;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    
    
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: anchoMaximo),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
