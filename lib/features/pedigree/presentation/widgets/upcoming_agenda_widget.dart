import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/pedigree_providers.dart';

enum AgendaEventType { whelping, heat }

class AgendaEvent {
  final int dogId;
  final AgendaEventType type;
  final DateTime eventDate;

  AgendaEvent({
    required this.dogId,
    required this.type,
    required this.eventDate,
  });
}

final upcomingAgendaProvider = StreamProvider.autoDispose<List<AgendaEvent>>((ref) {
  final db = ref.watch(databaseProvider);
  
  final whelpingsStream = db.watchUpcomingWhelpings().map((matings) {
    return matings.map((m) => AgendaEvent(
      dogId: m.damId,
      type: AgendaEventType.whelping,
      eventDate: m.matingDate.add(const Duration(days: 63)),
    )).toList();
  });

  final heatsStream = db.watchAllHeatCycles().map((heats) {
    final upcomingHeats = <AgendaEvent>[];
    final now = DateTime.now();
    // Only look at most recent heat per dog to predict next heat
    final latestHeats = <int, HeatCycle>{};
    for (var h in heats) {
      if (!latestHeats.containsKey(h.dogId) || h.startDate.isAfter(latestHeats[h.dogId]!.startDate)) {
        latestHeats[h.dogId] = h;
      }
    }
    
    for (var h in latestHeats.values) {
      final nextHeat = h.startDate.add(const Duration(days: 180));
      // Show heats coming up in the next 30 days or currently overdue
      if (nextHeat.difference(now).inDays <= 30) {
        upcomingHeats.add(AgendaEvent(
          dogId: h.dogId,
          type: AgendaEventType.heat,
          eventDate: nextHeat,
        ));
      }
    }
    return upcomingHeats;
  });

  return Rx.combineLatest2(whelpingsStream, heatsStream, (List<AgendaEvent> w, List<AgendaEvent> h) {
    final combined = [...w, ...h];
    combined.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    return combined;
  });
});

class UpcomingAgendaWidget extends ConsumerWidget {
  const UpcomingAgendaWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaAsync = ref.watch(upcomingAgendaProvider);

    return agendaAsync.when(
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: 8.0, top: 8.0),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final daysLeft = event.eventDate.difference(DateTime.now()).inDays;
              return _buildAgendaCard(context, ref, event, daysLeft);
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, stack) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildAgendaCard(BuildContext context, WidgetRef ref, AgendaEvent event, int daysLeft) {
    final damAsync = ref.watch(dogByIdProvider(event.dogId));
    
    final isWhelping = event.type == AgendaEventType.whelping;
    final isUrgent = daysLeft <= 7;
    
    final gradientColors = isWhelping 
        ? (isUrgent ? [Colors.red.shade50, Colors.white] : [Colors.blue.shade50, Colors.white])
        : (isUrgent ? [Colors.orange.shade50, Colors.white] : [Colors.pink.shade50, Colors.white]);

    final iconColor = isWhelping 
        ? (isUrgent ? Colors.red.shade400 : Colors.blue.shade400)
        : (isUrgent ? Colors.orange.shade400 : Colors.pink.shade400);

    final titleColor = isWhelping 
        ? (isUrgent ? Colors.red.shade700 : AppTheme.primaryColor)
        : (isUrgent ? Colors.orange.shade700 : Colors.pink.shade700);

    final eventTitle = isWhelping 
        ? (daysLeft <= 0 ? 'Whelping Now!' : '$daysLeft Days to Whelp')
        : (daysLeft <= 0 ? 'Heat Overdue!' : '$daysLeft Days to Heat');

    final iconData = isWhelping ? Icons.pets : Icons.favorite;

    return Card(
      margin: const EdgeInsets.only(right: 12.0),
      elevation: 4,
      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  eventTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: titleColor,
                  ),
                ),
              ],
            ),
            const Spacer(),
            damAsync.when(
              data: (dam) => Text(
                'Dam: ${dam.callName}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              loading: () => const Text('Loading...'),
              error: (_, _) => const Text('Unknown Dog'),
            ),
            const SizedBox(height: 4),
            Text(
              'Est: ${DateFormat('MMM d, yyyy').format(event.eventDate)}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
