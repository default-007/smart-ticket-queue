import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_ticketing/providers/ticket_provider.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  double _estimatedHours = 1;
  int _priority = 2;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate() && _dueDate != null) {
      try {
        await ref.read(ticketProvider.notifier).createTicket({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'dueDate': _dueDate!.toIso8601String(),
          'estimatedHours': _estimatedHours,
          'priority': _priority,
        });
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketState = ref.watch(ticketProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Ticket'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Due Date'),
                subtitle: Text(_dueDate == null
                    ? 'Not set'
                    : DateFormat('MMM dd, yyyy').format(_dueDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _dueDate = date;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Estimated Hours: '),
                  Expanded(
                    child: Slider(
                      value: _estimatedHours,
                      min: 0.5,
                      max: 8,
                      divisions: 15,
                      label: _estimatedHours.toString(),
                      onChanged: (value) {
                        setState(() {
                          _estimatedHours = value;
                        });
                      },
                    ),
                  ),
                  Text(_estimatedHours.toString()),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('High')),
                  DropdownMenuItem(value: 2, child: Text('Medium')),
                  DropdownMenuItem(value: 3, child: Text('Low')),
                ],
                onChanged: (value) {
                  setState(() {
                    _priority = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: ticketState.isLoading ? null : _handleSubmit,
                child: ticketState.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create Ticket'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
