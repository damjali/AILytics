import 'package:flutter/material.dart';

class FeatureSelectionPage extends StatefulWidget {
  final Map<String, dynamic> processedData;
  final String fileName;

  const FeatureSelectionPage({
    super.key,
    required this.processedData,
    required this.fileName,
  });

  @override
  _FeatureSelectionPageState createState() => _FeatureSelectionPageState();
}


class _FeatureSelectionPageState extends State<FeatureSelectionPage> {
  List<String> features = [];
  List<String> selectedFeatures = [];

  @override
  void initState() {
    super.initState();
    // Initialize features from the processedData passed via constructor.
    if (widget.processedData['columns'] != null) {
      features = List<String>.from(widget.processedData['columns']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Feature Selection for ${widget.fileName}"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: features.length,
              itemBuilder: (context, index) {
                final feature = features[index];
                return CheckboxListTile(
                  title: Text(feature),
                  value: selectedFeatures.contains(feature),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selectedFeatures.add(feature);
                      } else {
                        selectedFeatures.remove(feature);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Handle the confirmation of selected features.
                Navigator.pushNamed(context, '/finalResult', arguments: {
                  'selectedFeatures': selectedFeatures,
                  'fileName': widget.fileName,
                });
              },
              child: const Text("Confirm Selection"),
            ),
          ),
        ],
      ),
    );
  }
}
