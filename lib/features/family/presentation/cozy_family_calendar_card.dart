import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/models/erat_models.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/theme/cozy_theme.dart';

/// Shared Family Event Calendar summary card for Home screens (Parents & Kids/Teens/Adults).
/// Tapping opens the interactive monthly Family Calendar sheet with "+ Add Event" synced to Firestore.
class CozyFamilyCalendarCard extends ConsumerWidget {
  const CozyFamilyCalendarCard({super.key});

  static const Color _mochaPrimary = Color(0xFF6D4C41);
  static const Color _warmCocoa = Color(0xFF5A463C);
  static const Color _blushSurface = Color(0xFFF5E4DC);
  static const Color _blushBorder = Color(0xFFE5CEC2);
  static const Color _linenSurface = Color(0xFFFAF2E8);

  String _formatDateBadge(DateTime date, bool isMs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return isMs ? 'Hari Ini' : 'Today';
    if (diff == 1) return isMs ? 'Esok' : 'Tomorrow';
    const monthsMs = [
      'Jan', 'Feb', 'Mac', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ogo', 'Sep', 'Okt', 'Nov', 'Dis',
    ];
    const monthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final m = isMs ? monthsMs[date.month - 1] : monthsEn[date.month - 1];
    return '${date.day} $m';
  }

  String _participantSummary(
    FamilyCalendarEvent event,
    List<FamilyMember> members,
    bool isMs,
  ) {
    if (event.participantIds.isEmpty) {
      return isMs ? 'Semua Ahli Keluarga' : 'All Family';
    }
    final names = members
        .where((m) => event.participantIds.contains(m.id))
        .map((m) => m.name.split(' ').first)
        .toList();
    if (names.isEmpty) return isMs ? 'Semua Ahli Keluarga' : 'All Family';
    return names.join(', ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(eratControllerProvider);
    final strings = ref.watch(appStringsProvider);
    final isMs = strings.isMs;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = appState.calendarEvents
        .where((e) {
          final d = DateTime(e.eventDate.year, e.eventDate.month, e.eventDate.day);
          return !d.isBefore(today);
        })
        .toList()
      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

    final previewEvents = upcoming.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _blushBorder, width: 1.2),
        boxShadow: CozyTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _blushSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: _mochaPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMs ? 'Kalendar Keluarga' : 'Family Calendar',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: CozyTheme.textDark,
                      ),
                    ),
                    Text(
                      upcoming.isEmpty
                          ? (isMs
                              ? 'Rancang aktiviti & tarikh penting bersama'
                              : 'Plan shared moments & important dates')
                          : (isMs
                              ? '${upcoming.length} acara akan datang'
                              : '${upcoming.length} upcoming event${upcoming.length == 1 ? '' : 's'}'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _warmCocoa,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: _mochaPrimary,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    showAddFamilyEventSheet(context, ref);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          isMs ? 'Acara' : 'Event',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (previewEvents.isEmpty)
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                showCozyFamilyCalendarSheet(context, ref);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _linenSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _blushBorder),
                ),
                child: Row(
                  children: [
                    const Text('🗓️', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isMs
                            ? 'Belum ada acara keluarga. Ketik "+ Acara" untuk tambah hari lahir, cuti, atau aktiviti sekolah!'
                            : 'No family events yet. Tap "+ Event" to add birthdays, outings, or school dates!',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _warmCocoa,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ...previewEvents.map((event) {
              final badge = _formatDateBadge(event.eventDate, isMs);
              final who = _participantSummary(event, appState.members, isMs);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _linenSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _blushBorder),
                ),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    showCozyFamilyCalendarSheet(
                      context,
                      ref,
                      initialSelectedDate: event.eventDate,
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _blushBorder),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          event.emoji,
                          style: const TextStyle(fontSize: 19),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: CozyTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              event.timeLabel != null &&
                                      event.timeLabel!.trim().isNotEmpty
                                  ? '${event.timeLabel!} • $who'
                                  : who,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _warmCocoa,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _blushSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _mochaPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                showCozyFamilyCalendarSheet(context, ref);
              },
              icon: const Icon(
                Icons.open_in_full_rounded,
                size: 16,
                color: _mochaPrimary,
              ),
              label: Text(
                isMs ? 'Buka Kalendar Penuh →' : 'Open Full Calendar →',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _mochaPrimary,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: _blushSurface.withValues(alpha: 0.55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive Monthly Family Calendar modal sheet.
void showCozyFamilyCalendarSheet(
  BuildContext context,
  WidgetRef ref, {
  DateTime? initialSelectedDate,
}) {
  final initial = initialSelectedDate ?? DateTime.now();
  DateTime focusedMonth = DateTime(initial.year, initial.month, 1);
  DateTime selectedDay = DateTime(initial.year, initial.month, initial.day);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return Consumer(
            builder: (consumerCtx, consumerRef, _) {
              final appState = consumerRef.watch(eratControllerProvider);
              final strings = consumerRef.watch(appStringsProvider);
              final isMs = strings.isMs;
              final activeMember = appState.activeMember;

              const monthsMs = [
                'Januari', 'Februari', 'Mac', 'April', 'Mei', 'Jun',
                'Julai', 'Ogos', 'September', 'Oktober', 'November', 'Disember',
              ];
              const monthsEn = [
                'January', 'February', 'March', 'April', 'May', 'June',
                'July', 'August', 'September', 'October', 'November', 'December',
              ];
              const weekdaysMs = ['Isn', 'Sel', 'Rab', 'Kha', 'Jum', 'Sab', 'Ahd'];
              const weekdaysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

              final monthLabel =
                  '${isMs ? monthsMs[focusedMonth.month - 1] : monthsEn[focusedMonth.month - 1]} ${focusedMonth.year}';
              final firstWeekday = focusedMonth.weekday; // 1=Mon..7=Sun
              final daysInMonth =
                  DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
              final leadingBlanks = firstWeekday - 1;
              final totalCells = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;

              final eventsOnSelectedDay = appState.calendarEvents
                  .where((e) => e.isOnDate(selectedDay))
                  .toList();

              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);

              return DraggableScrollableSheet(
                initialChildSize: 0.86,
                minChildSize: 0.55,
                maxChildSize: 0.94,
                expand: false,
                builder: (sheetCtx, scrollCtrl) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: CozyTheme.background,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            Container(
                              width: 42,
                              height: 4.5,
                              decoration: BoxDecoration(
                                color: const Color(0xFFBBA396),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      isMs
                                          ? 'Kalendar Keluarga'
                                          : 'Family Calendar',
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w900,
                                        color: CozyTheme.textDark,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      showAddFamilyEventSheet(
                                        context,
                                        consumerRef,
                                        initialDate: selectedDay,
                                      );
                                    },
                                    icon: const Icon(Icons.add_rounded, size: 17),
                                    label: Text(
                                      isMs ? 'Tambah' : 'Add',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          CozyFamilyCalendarCard._mochaPrimary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: CozyTheme.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                controller: scrollCtrl,
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                                children: [
                                  // Month Navigation & Grid Card
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color:
                                            CozyFamilyCalendarCard._blushBorder,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                HapticFeedback.selectionClick();
                                                setModalState(() {
                                                  focusedMonth = DateTime(
                                                    focusedMonth.year,
                                                    focusedMonth.month - 1,
                                                    1,
                                                  );
                                                });
                                              },
                                              icon: const Icon(
                                                Icons.chevron_left_rounded,
                                                color: CozyFamilyCalendarCard
                                                    ._mochaPrimary,
                                              ),
                                            ),
                                            Text(
                                              monthLabel,
                                              style: const TextStyle(
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w800,
                                                color: CozyTheme.textDark,
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                HapticFeedback.selectionClick();
                                                setModalState(() {
                                                  focusedMonth = DateTime(
                                                    focusedMonth.year,
                                                    focusedMonth.month + 1,
                                                    1,
                                                  );
                                                });
                                              },
                                              icon: const Icon(
                                                Icons.chevron_right_rounded,
                                                color: CozyFamilyCalendarCard
                                                    ._mochaPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: (isMs
                                                  ? weekdaysMs
                                                  : weekdaysEn)
                                              .map(
                                                (w) => Expanded(
                                                  child: Center(
                                                    child: Text(
                                                      w,
                                                      style: const TextStyle(
                                                        fontSize: 11.5,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color:
                                                            CozyFamilyCalendarCard
                                                                ._warmCocoa,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                        const SizedBox(height: 8),
                                        GridView.builder(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 7,
                                            mainAxisSpacing: 4,
                                            crossAxisSpacing: 4,
                                            childAspectRatio: 1.0,
                                          ),
                                          itemCount: totalCells,
                                          itemBuilder: (_, idx) {
                                            final dayNum =
                                                idx - leadingBlanks + 1;
                                            if (dayNum < 1 ||
                                                dayNum > daysInMonth) {
                                              return const SizedBox.shrink();
                                            }
                                            final cellDate = DateTime(
                                              focusedMonth.year,
                                              focusedMonth.month,
                                              dayNum,
                                            );
                                            final isSelected =
                                                cellDate.year ==
                                                        selectedDay.year &&
                                                    cellDate.month ==
                                                        selectedDay.month &&
                                                    cellDate.day ==
                                                        selectedDay.day;
                                            final isToday =
                                                cellDate.year == today.year &&
                                                    cellDate.month ==
                                                        today.month &&
                                                    cellDate.day == today.day;
                                            final hasEvent = appState
                                                .calendarEvents
                                                .any((e) => e.isOnDate(cellDate));

                                            return InkWell(
                                              onTap: () {
                                                HapticFeedback.selectionClick();
                                                setModalState(
                                                  () => selectedDay = cellDate,
                                                );
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? CozyFamilyCalendarCard
                                                          ._mochaPrimary
                                                      : (isToday
                                                          ? CozyFamilyCalendarCard
                                                              ._blushSurface
                                                          : Colors.transparent),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: isToday && !isSelected
                                                      ? Border.all(
                                                          color:
                                                              CozyFamilyCalendarCard
                                                                  ._mochaPrimary,
                                                          width: 1.3,
                                                        )
                                                      : null,
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      '$dayNum',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: isSelected ||
                                                                isToday
                                                            ? FontWeight.w800
                                                            : FontWeight.w600,
                                                        color: isSelected
                                                            ? Colors.white
                                                            : CozyTheme.textDark,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    if (hasEvent)
                                                      Container(
                                                        width: 5,
                                                        height: 5,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: isSelected
                                                              ? const Color(
                                                                  0xFFFDE047,
                                                                )
                                                              : CozyFamilyCalendarCard
                                                                  ._mochaPrimary,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                      )
                                                    else
                                                      const SizedBox(height: 5),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Events on Selected Date
                                  Text(
                                    isMs
                                        ? 'Acara pada ${selectedDay.day} ${monthsMs[selectedDay.month - 1]} ${selectedDay.year}'
                                        : 'Events on ${selectedDay.day} ${monthsEn[selectedDay.month - 1]} ${selectedDay.year}',
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                      color: CozyTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (eventsOnSelectedDay.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: CozyFamilyCalendarCard
                                              ._blushBorder,
                                        ),
                                      ),
                                      child: Text(
                                        isMs
                                            ? 'Tiada acara pada tarikh ini. Tekan "+ Tambah" untuk jadualkan aktiviti keluarga.'
                                            : 'No events on this date. Tap "+ Add" to schedule a family activity.',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: CozyFamilyCalendarCard
                                              ._warmCocoa,
                                        ),
                                      ),
                                    )
                                  else
                                    ...eventsOnSelectedDay.map((event) {
                                      final canDelete =
                                          activeMember.isParentOrGuardian ||
                                              event.createdById ==
                                                  activeMember.id;
                                      final participantsText =
                                          event.participantIds.isEmpty
                                              ? (isMs
                                                  ? 'Semua Ahli Keluarga'
                                                  : 'All Family Members')
                                              : appState.members
                                                  .where(
                                                    (m) => event.participantIds
                                                        .contains(m.id),
                                                  )
                                                  .map((m) => m.name)
                                                  .join(', ');

                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          border: Border.all(
                                            color: CozyFamilyCalendarCard
                                                ._blushBorder,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: CozyFamilyCalendarCard
                                                    ._blushSurface,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                event.emoji,
                                                style: const TextStyle(
                                                  fontSize: 22,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    event.title,
                                                    style: const TextStyle(
                                                      fontSize: 14.5,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: CozyTheme.textDark,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    event.timeLabel != null &&
                                                            event.timeLabel!
                                                                .trim()
                                                                .isNotEmpty
                                                        ? '🕒 ${event.timeLabel!} • 👥 $participantsText'
                                                        : '👥 $participantsText',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          CozyFamilyCalendarCard
                                                              ._warmCocoa,
                                                    ),
                                                  ),
                                                  if (event.description !=
                                                          null &&
                                                      event.description!
                                                          .trim()
                                                          .isNotEmpty) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      event.description!,
                                                      style: const TextStyle(
                                                        fontSize: 12.5,
                                                        color: CozyTheme
                                                            .textMuted,
                                                        height: 1.35,
                                                      ),
                                                    ),
                                                  ],
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    isMs
                                                        ? 'Ditambah oleh ${event.createdByName}'
                                                        : 'Added by ${event.createdByName}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: CozyTheme
                                                          .textMuted,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (canDelete)
                                              IconButton(
                                                tooltip:
                                                    isMs ? 'Padam' : 'Delete',
                                                onPressed: () {
                                                  HapticFeedback.lightImpact();
                                                  consumerRef
                                                      .read(
                                                        eratControllerProvider
                                                            .notifier,
                                                      )
                                                      .deleteCalendarEvent(
                                                        event.id,
                                                      );
                                                },
                                                icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 20,
                                                  color: Color(0xFFB91C1C),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      );
    },
  );
}

/// Bottom sheet to create a new Family Calendar Event (synced to Cloud Firestore).
void showAddFamilyEventSheet(
  BuildContext context,
  WidgetRef ref, {
  DateTime? initialDate,
}) {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  DateTime chosenDate = initialDate ?? DateTime.now();
  TimeOfDay? chosenTime;
  String chosenEmoji = '🎉';
  bool allFamily = true;
  final Set<String> selectedMemberIds = {};

  const emojis = ['🎉', '🎂', '🍽️', '🕌', '🏫', '✈️', '🏥', '⚽'];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (modalCtx, setSheetState) {
          final appState = ref.read(eratControllerProvider);
          final strings = ref.read(appStringsProvider);
          final isMs = strings.isMs;
          final viewInsets = MediaQuery.of(modalCtx).viewInsets.bottom;
          final bottomPad = MediaQuery.of(modalCtx).padding.bottom;

          final canSave = titleCtrl.text.trim().isNotEmpty;
          final dateLabel =
              '${chosenDate.day}/${chosenDate.month}/${chosenDate.year}';
          final timeLabel = chosenTime != null
              ? chosenTime!.format(modalCtx)
              : (isMs ? 'Sepanjang Hari' : 'All Day');

          return Padding(
            padding: EdgeInsets.only(bottom: viewInsets),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  decoration: const BoxDecoration(
                    color: CozyTheme.background,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      bottomPad > 24 ? bottomPad + 12 : 28,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4.5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFBBA396),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isMs
                                    ? 'Tambah Acara Keluarga'
                                    : 'Add Family Event',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: CozyTheme.textDark,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: CozyTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Event Title
                        Text(
                          isMs ? 'Nama Acara:' : 'Event Title:',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: CozyFamilyCalendarCard._warmCocoa,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: titleCtrl,
                          onChanged: (_) => setSheetState(() {}),
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: isMs
                                ? 'Cth: Makan Malam Rumah Tok Wan / Hari Sukan'
                                : 'e.g. Family Dinner / School Sports Day',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: CozyFamilyCalendarCard._blushBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: CozyFamilyCalendarCard._blushBorder,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: CozyFamilyCalendarCard._mochaPrimary,
                                width: 1.8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Date & Time Row
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: modalCtx,
                                    initialDate: chosenDate,
                                    firstDate: DateTime(2024),
                                    lastDate: DateTime(2032),
                                  );
                                  if (picked != null) {
                                    setSheetState(() => chosenDate = picked);
                                  }
                                },
                                icon: const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                ),
                                label: Text(dateLabel),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      CozyFamilyCalendarCard._mochaPrimary,
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: CozyFamilyCalendarCard._blushBorder,
                                  ),
                                  minimumSize: const Size(0, 46),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                    context: modalCtx,
                                    initialTime: chosenTime ??
                                        const TimeOfDay(hour: 19, minute: 0),
                                  );
                                  if (picked != null) {
                                    setSheetState(() => chosenTime = picked);
                                  }
                                },
                                icon: const Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                ),
                                label: Text(timeLabel),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      CozyFamilyCalendarCard._mochaPrimary,
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: CozyFamilyCalendarCard._blushBorder,
                                  ),
                                  minimumSize: const Size(0, 46),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Emoji Picker
                        Text(
                          isMs ? 'Ikon Acara:' : 'Event Icon:',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: CozyFamilyCalendarCard._warmCocoa,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: emojis.map((e) {
                            final sel = chosenEmoji == e;
                            return InkWell(
                              onTap: () => setSheetState(() => chosenEmoji = e),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 44,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: sel
                                      ? CozyFamilyCalendarCard._blushSurface
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: sel
                                        ? CozyFamilyCalendarCard._mochaPrimary
                                        : CozyFamilyCalendarCard._blushBorder,
                                    width: sel ? 1.8 : 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(e, style: const TextStyle(fontSize: 20)),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),

                        // Participants
                        Text(
                          isMs ? 'Ahli Terlibat:' : 'Who’s Involved:',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: CozyFamilyCalendarCard._warmCocoa,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: Text(
                                isMs ? 'Semua Ahli' : 'All Family',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: allFamily
                                      ? Colors.white
                                      : CozyTheme.textDark,
                                ),
                              ),
                              selected: allFamily,
                              selectedColor:
                                  CozyFamilyCalendarCard._mochaPrimary,
                              backgroundColor: Colors.white,
                              onSelected: (_) {
                                setSheetState(() {
                                  allFamily = true;
                                  selectedMemberIds.clear();
                                });
                              },
                            ),
                            ...appState.members.map((m) {
                              final isSel =
                                  !allFamily && selectedMemberIds.contains(m.id);
                              return FilterChip(
                                label: Text(
                                  '${m.avatarEmoji} ${m.name.split(' ').first}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isSel
                                        ? Colors.white
                                        : CozyTheme.textDark,
                                  ),
                                ),
                                selected: isSel,
                                selectedColor:
                                    CozyFamilyCalendarCard._mochaPrimary,
                                backgroundColor: Colors.white,
                                onSelected: (val) {
                                  setSheetState(() {
                                    allFamily = false;
                                    if (val) {
                                      selectedMemberIds.add(m.id);
                                    } else {
                                      selectedMemberIds.remove(m.id);
                                      if (selectedMemberIds.isEmpty) {
                                        allFamily = true;
                                      }
                                    }
                                  });
                                },
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Optional Notes / Location
                        Text(
                          isMs ? 'Nota / Lokasi (Pilihan):' : 'Notes / Location (Optional):',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: CozyFamilyCalendarCard._warmCocoa,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: descCtrl,
                          maxLines: 2,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: isMs
                                ? 'Cth: Bawa baju sukan & botol air'
                                : 'e.g. Bring snacks & water bottle',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: CozyFamilyCalendarCard._blushBorder,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: CozyFamilyCalendarCard._blushBorder,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: canSave
                                ? () {
                                    HapticFeedback.mediumImpact();
                                    ref
                                        .read(eratControllerProvider.notifier)
                                        .addCalendarEvent(
                                          title: titleCtrl.text.trim(),
                                          description:
                                              descCtrl.text.trim().isEmpty
                                                  ? null
                                                  : descCtrl.text.trim(),
                                          emoji: chosenEmoji,
                                          eventDate: DateTime(
                                            chosenDate.year,
                                            chosenDate.month,
                                            chosenDate.day,
                                            chosenTime?.hour ?? 9,
                                            chosenTime?.minute ?? 0,
                                          ),
                                          timeLabel: chosenTime?.format(modalCtx),
                                          participantIds: allFamily
                                              ? const []
                                              : selectedMemberIds.toList(),
                                        );
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isMs
                                              ? 'Acara "${titleCtrl.text.trim()}" disimpan ke Kalendar Keluarga!'
                                              : '"${titleCtrl.text.trim()}" added to Family Calendar!',
                                        ),
                                        backgroundColor:
                                            CozyFamilyCalendarCard._mochaPrimary,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.check_rounded, size: 20),
                            label: Text(
                              isMs ? 'Simpan Acara' : 'Save Event',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  CozyFamilyCalendarCard._mochaPrimary,
                              disabledBackgroundColor: const Color(0xFFD5C3B8),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
