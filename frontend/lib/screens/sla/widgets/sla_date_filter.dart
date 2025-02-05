import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SLADateFilter extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime, DateTime) onDateRangeSelected;

  const SLADateFilter({
    Key? key,
    required this.startDate,
    required this.endDate,
    required this.onDateRangeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.date_range),
                const SizedBox(width: 8),
                const Text(
                  'Date Range',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    context,
                    'Start Date',
                    startDate,
                    (date) {
                      if (date != null && endDate != null) {
                        onDateRangeSelected(date, endDate!);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateButton(
                    context,
                    'End Date',
                    endDate,
                    (date) {
                      if (date != null && startDate != null) {
                        onDateRangeSelected(startDate!, date);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickFilterChip('Last 7 Days', () {
                  _setDateRange(7);
                }),
                _buildQuickFilterChip('Last 30 Days', () {
                  _setDateRange(30);
                }),
                _buildQuickFilterChip('Last 90 Days', () {
                  _setDateRange(90);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton(
    BuildContext context,
    String label,
    DateTime? date,
    Function(DateTime?) onDateSelected,
  ) {
    return OutlinedButton(
      onPressed: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (selected != null) {
          onDateSelected(selected);
        }
      },
      child: Text(
        date != null ? DateFormat('MMM dd, yyyy').format(date) : label,
        style: TextStyle(
          color: date != null ? Colors.black : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, VoidCallback onPressed) {
    return ChoiceChip(
      label: Text(label),
      selected: false,
      onSelected: (_) => onPressed(),
    );
  }

  void _setDateRange(int days) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    onDateRangeSelected(start, now);
  }
}
