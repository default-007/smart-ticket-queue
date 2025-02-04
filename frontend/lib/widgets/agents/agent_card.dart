import 'package:flutter/material.dart';
import '../../models/agent.dart';
import 'agent_status_badge.dart';

class AgentCard extends StatelessWidget {
  final Agent agent;
  final VoidCallback? onTap; // Added onTap parameter

  const AgentCard({
    Key? key,
    required this.agent,
    this.onTap, // Added to constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        // Wrapped with InkWell for tap effect
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Text(agent.name[0].toUpperCase()),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agent.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(agent.email),
                      ],
                    ),
                  ),
                  AgentStatusBadge(
                    status: agent.status,
                    isOnShift: agent.isOnShift,
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Department: ${agent.department}'),
                  Text('Load: ${agent.currentLoad}/${agent.maxTickets}h'),
                ],
              ),
              if (agent.skills.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: agent.skills
                      .map((skill) => Chip(
                            label: Text(skill),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
