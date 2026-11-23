import 'package:material_ui/material_ui.dart';

import '../theme.dart';

class ComingSoonScreen extends StatelessWidget {
  final String title;
  const ComingSoonScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction, size: 56, color: kSaffron),
              SizedBox(height: 12),
              Text('यह हिस्सा अभी बना नहीं है',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('अगले चरणों में इसे बनाया जाएगा।',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 17)),
            ],
          ),
        ),
      ),
    );
  }
}
