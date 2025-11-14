import 'package:flutter/material.dart';

// Define a typedef for your custom callback
typedef SeriesItemCallback = void Function(String title, bool isChecked);

class SeriesItem extends StatefulWidget {
  final String title;
  final bool initialValue;
  final SeriesItemCallback? onItemChecked;  // Changed from ValueChanged to custom type

  const SeriesItem({
    super.key,
    required this.title,
    this.initialValue = false,
    this.onItemChecked,
  });

  @override
  State<SeriesItem> createState() => _SeriesItemState();
}

class _SeriesItemState extends State<SeriesItem> {
  late bool _isChecked;

  @override
  void initState() {
    super.initState();
    _isChecked = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CheckboxListTile(
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                decoration: _isChecked ? TextDecoration.lineThrough : null,
                color: _isChecked ? Colors.grey : null,
              ),
        ),
        value: _isChecked,
        onChanged: (bool? value) {
          setState(() {
            _isChecked = value ?? false;
          });
          widget.onItemChecked?.call(widget.title, _isChecked);
        },
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        checkboxShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
          width: 1.5,
        ),
      ),
    );
  }
}

class SeriesList extends StatelessWidget {
  final List<String> seriesTitles;
  final Map<String, bool>? checkedState;
  final SeriesItemCallback? onItemChecked;  // Changed to custom type

  const SeriesList({
    super.key,
    required this.seriesTitles,
    this.checkedState,
    this.onItemChecked,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: seriesTitles.length,
      itemBuilder: (context, index) {
        final title = seriesTitles[index];
        return SeriesItem(
          title: title,
          initialValue: checkedState?[title] ?? false,
          onItemChecked: onItemChecked,  // Pass through the callback
        );
      },
    );
  }
}