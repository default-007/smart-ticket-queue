import 'package:flutter/material.dart';

class TicketFilter extends StatelessWidget {
  final String? selectedStatus;
  final Function(String?) onStatusChanged;

  const TicketFilter({
    Key? key,
    required this.selectedStatus,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('Filter by status: '),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButton<String>(
              value: selectedStatus,
              isExpanded: true,
              hint: const Text('All tickets'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All tickets'),
                ),
                ...['queued', 'assigned', 'in-progress', 'resolved', 'closed']
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status
                              .split('-')
                              .map((word) =>
                                  word[0].toUpperCase() + word.substring(1))
                              .join(' ')),
                        ))
                    .toList(),
              ],
              onChanged: onStatusChanged,
            ),
          ),
        ],
      ),
    );
  }
}
