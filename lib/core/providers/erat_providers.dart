import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/erat_models.dart';

/// Tracks whether Firebase is actively initialized & connected
final firebaseConnectedProvider = StateProvider<bool>((ref) => false);

/// Tracks whether the app is currently in Mode Selection, Shared Family View, or Personal Private View
enum AppViewMode { selection, family, private }

final appViewModeProvider = StateProvider<AppViewMode>((ref) => AppViewMode.selection);

/// Tracks whether Private Space is currently unlocked in demo mode
final isPrivateSpaceUnlockedProvider = StateProvider<bool>((ref) => false);

/// Tracks which child a Parent is currently inspecting on the Quests / Rewards tab
final selectedChildForParentViewProvider =
    StateProvider<String?>((ref) => null);

class EratAppState {
  final FamilySpace family;
  final List<FamilyMember> members;
  final String activeMemberId;
  final List<BondingActivity> activities;
  final List<WishGoal> wishGoals;
  final List<LedgerEntry> ledger;
  final List<ChatMessage> messages;
  final List<JournalEntry> journalEntries;
  final List<CommunityKnowledgePost> communityPosts;
  final List<DiningTableNote> diningTableNotes;
  final List<FamilyRewardGoal> familyGoals;
  final List<RoutineApprovalRequest> routineRequests;
  final List<FamilyCalendarEvent> calendarEvents;
  final Set<String> reportedPostIds;
  final Set<String> blockedAuthorIds;

  const EratAppState({
    required this.family,
    required this.members,
    required this.activeMemberId,
    required this.activities,
    required this.wishGoals,
    required this.ledger,
    required this.messages,
    this.journalEntries = const [],
    this.communityPosts = const [],
    this.diningTableNotes = const [],
    this.familyGoals = const [],
    this.routineRequests = const [],
    this.calendarEvents = const [],
    this.reportedPostIds = const {},
    this.blockedAuthorIds = const {},
  });

  FamilyMember get activeMember => members.firstWhere(
        (m) => m.id == activeMemberId,
        orElse: () => members.first,
      );

  EratAppState copyWith({
    FamilySpace? family,
    List<FamilyMember>? members,
    String? activeMemberId,
    List<BondingActivity>? activities,
    List<WishGoal>? wishGoals,
    List<LedgerEntry>? ledger,
    List<ChatMessage>? messages,
    List<JournalEntry>? journalEntries,
    List<CommunityKnowledgePost>? communityPosts,
    List<DiningTableNote>? diningTableNotes,
    List<FamilyRewardGoal>? familyGoals,
    List<RoutineApprovalRequest>? routineRequests,
    List<FamilyCalendarEvent>? calendarEvents,
    Set<String>? reportedPostIds,
    Set<String>? blockedAuthorIds,
  }) {
    return EratAppState(
      family: family ?? this.family,
      members: members ?? this.members,
      activeMemberId: activeMemberId ?? this.activeMemberId,
      activities: activities ?? this.activities,
      wishGoals: wishGoals ?? this.wishGoals,
      ledger: ledger ?? this.ledger,
      messages: messages ?? this.messages,
      journalEntries: journalEntries ?? this.journalEntries,
      communityPosts: communityPosts ?? this.communityPosts,
      diningTableNotes: diningTableNotes ?? this.diningTableNotes,
      familyGoals: familyGoals ?? this.familyGoals,
      routineRequests: routineRequests ?? this.routineRequests,
      calendarEvents: calendarEvents ?? this.calendarEvents,
      reportedPostIds: reportedPostIds ?? this.reportedPostIds,
      blockedAuthorIds: blockedAuthorIds ?? this.blockedAuthorIds,
    );
  }
}

class EratController extends StateNotifier<EratAppState> {
  final bool isFirebaseReady;

  EratController({required this.isFirebaseReady}) : super(_initialSeedState()) {
    _hydrateSavedFamily();
  }

  Future<void> _hydrateSavedFamily() async {
    // 1. Hydrate local saved family settings & dining notes first (instant restore for Demo & offline)
    await _loadFamilyCacheLocally(state.family.id);
    await _loadDiningNotesCacheLocally(state.family.id);
    // 2. Sync with Cloud Firestore if connected
    if (isFirebaseReady) {
      await _initFirestore();
    }
  }

  File? _diningNotesCacheFile(String familyId) {
    if (kIsWeb) return null;
    try {
      return File('${Directory.systemTemp.path}/erat_notes_$familyId.json');
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveDiningNotesCacheLocally(
    String familyId,
    List<DiningTableNote> notes,
  ) async {
    final file = _diningNotesCacheFile(familyId);
    if (file == null) return;
    try {
      // Cache only this family's private notes (never overwrite public notes)
      final privateNotes = notes.where((n) => !n.isPublic).toList();
      final payload = jsonEncode(
        privateNotes
            .map((n) => {
                  'id': n.id,
                  'textMs': n.textMs,
                  'textEn': n.textEn,
                  'authorName': n.authorName,
                  'createdAt': n.createdAt.toIso8601String(),
                })
            .toList(),
      );
      await file.writeAsString(payload, flush: true);
    } catch (e) {
      debugPrint('⚠️ Local dining notes save error: $e');
    }
  }

  Future<void> _loadDiningNotesCacheLocally(String familyId) async {
    final file = _diningNotesCacheFile(familyId);
    if (file == null) return;
    try {
      if (!await file.exists()) return;
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw) as List<dynamic>;
      final privateNotes = decoded.map((item) {
        final m = item as Map<String, dynamic>;
        return DiningTableNote(
          id: (m['id'] as String?) ??
              'note_${DateTime.now().millisecondsSinceEpoch}',
          textMs: (m['textMs'] as String?) ?? '',
          textEn: (m['textEn'] as String?) ?? '',
          authorName: (m['authorName'] as String?) ?? 'Family',
          isPublic: false,
          createdAt: DateTime.tryParse((m['createdAt'] as String?) ?? '') ??
              DateTime.now(),
        );
      }).where((n) => n.textEn.isNotEmpty || n.textMs.isNotEmpty).toList();
      if (privateNotes.isNotEmpty) {
        final publicNotes =
            state.diningTableNotes.where((n) => n.isPublic).toList();
        state = state.copyWith(
          diningTableNotes: [...privateNotes, ...publicNotes],
        );
      }
    } catch (e) {
      debugPrint('⚠️ Local dining notes load error: $e');
    }
  }

  File? _familyCacheFile(String familyId) {
    if (kIsWeb) return null;
    try {
      return File('${Directory.systemTemp.path}/erat_family_$familyId.json');
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveFamilyCacheLocally(FamilySpace family) async {
    final file = _familyCacheFile(family.id);
    if (file == null) return;
    try {
      final payload = jsonEncode({
        'name': family.name,
        'familyGoalTitleMs': family.familyGoalTitleMs,
        'familyGoalTitleEn': family.familyGoalTitleEn,
        'familyGoalTargetStars': family.familyGoalTargetStars,
        'familyGoalCurrentStars': family.familyGoalCurrentStars,
        'photoPath': family.photoPath,
      });
      await file.writeAsString(payload, flush: true);
    } catch (e) {
      debugPrint('⚠️ Local family cache save error: $e');
    }
  }

  Future<void> _loadFamilyCacheLocally(String familyId) async {
    final file = _familyCacheFile(familyId);
    if (file == null) return;
    try {
      if (!await file.exists()) return;
      final raw = await file.readAsString();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      state = state.copyWith(
        family: state.family.copyWith(
          name: (data['name'] as String?) ?? state.family.name,
          familyGoalTitleMs: (data['familyGoalTitleMs'] as String?) ??
              state.family.familyGoalTitleMs,
          familyGoalTitleEn: (data['familyGoalTitleEn'] as String?) ??
              state.family.familyGoalTitleEn,
          familyGoalTargetStars:
              (data['familyGoalTargetStars'] as num?)?.toInt() ??
                  state.family.familyGoalTargetStars,
          familyGoalCurrentStars:
              (data['familyGoalCurrentStars'] as num?)?.toInt() ??
                  state.family.familyGoalCurrentStars,
          photoPath: data['photoPath'] as String?,
          clearPhoto: data.containsKey('photoPath') && data['photoPath'] == null,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Local family cache load error: $e');
    }
  }

  /// True ONLY for real authenticated family accounts — Demo Mode (`fam_erat_01`)
  /// is strictly sandboxed locally and NEVER reads/writes Cloud Firestore.
  bool get _canSyncToFirestore =>
      isFirebaseReady &&
      Firebase.apps.isNotEmpty &&
      state.family.id != 'fam_erat_01' &&
      FirebaseAuth.instance.currentUser != null;

  /// Enter isolated Demo Mode: signs out any real Firebase session and resets
  /// to a clean local demo family (`fam_erat_01`) so real & demo data never mix.
  Future<void> enterDemoMode() async {
    if (Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    state = _initialSeedState();
  }

  /// Initialize and sync with Cloud Firestore (ONLY for real signed-in families)
  Future<void> _initFirestore() async {
    if (!_canSyncToFirestore) return;
    try {
      final familyDoc = FirebaseFirestore.instance
          .collection('families')
          .doc(state.family.id);

      // 1. Ensure family record exists in Firestore & hydrate saved settings
      final familySnap = await familyDoc.get();
      if (!familySnap.exists) {
        await familyDoc.set({
          'id': state.family.id,
          'name': state.family.name,
          'inviteCode': state.family.inviteCode,
          'familyGoalTitleMs': state.family.familyGoalTitleMs,
          'familyGoalTitleEn': state.family.familyGoalTitleEn,
          'familyGoalTargetStars': state.family.familyGoalTargetStars,
          'familyGoalCurrentStars': state.family.familyGoalCurrentStars,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        final fData = familySnap.data();
        if (fData != null) {
          state = state.copyWith(
            family: state.family.copyWith(
              name: (fData['name'] as String?) ?? state.family.name,
              familyGoalTitleMs: (fData['familyGoalTitleMs'] as String?) ??
                  state.family.familyGoalTitleMs,
              familyGoalTitleEn: (fData['familyGoalTitleEn'] as String?) ??
                  state.family.familyGoalTitleEn,
              familyGoalTargetStars:
                  (fData['familyGoalTargetStars'] as num?)?.toInt() ??
                      state.family.familyGoalTargetStars,
              familyGoalCurrentStars:
                  (fData['familyGoalCurrentStars'] as num?)?.toInt() ??
                      state.family.familyGoalCurrentStars,
              photoPath: (fData['photoPath'] as String?) ?? state.family.photoPath,
            ),
          );
        }
      }

      // 2. Fetch or seed members in /families/{familyId}/members
      final membersCol = familyDoc.collection('members');
      final membersSnap = await membersCol.get();

      if (membersSnap.docs.isEmpty) {
        // Auto-seed to Firestore if family is newly registered
        for (final m in state.members) {
          await membersCol.doc(m.id).set({
            'id': m.id,
            'familyId': state.family.id,
            'name': m.name,
            'avatarEmoji': m.avatarEmoji,
            'role': m.role.name,
            'birthMonth': m.birthMonth,
            'birthYear': m.birthYear,
            'pin': m.pin,
            'points': m.points,
            'stars': m.stars,
            'streakDays': m.streakDays,
            'customPhotoPath': m.customPhotoPath,
            'tagline': m.tagline,
            'privacyLevel': m.privacyLevel.name,
          });
        }
      } else {
        // Load live members from Cloud Firestore
        final liveMembers = membersSnap.docs.map((doc) {
          final data = doc.data();
          final roleName = data['role'] as String? ?? 'child';
          final role = MemberRole.values.firstWhere(
            (r) => r.name == roleName,
            orElse: () => MemberRole.child,
          );
          final privacyName = data['privacyLevel'] as String? ?? 'family';
          final privacy = PrivacyLevel.values.firstWhere(
            (p) => p.name == privacyName,
            orElse: () => PrivacyLevel.family,
          );

          return FamilyMember(
            id: doc.id,
            familyId: (data['familyId'] as String?) ?? state.family.id,
            name: (data['name'] as String?) ?? 'Member',
            avatarEmoji: (data['avatarEmoji'] as String?) ?? '👤',
            role: role,
            birthMonth: (data['birthMonth'] as num?)?.toInt() ?? 1,
            birthYear: (data['birthYear'] as num?)?.toInt() ?? 2015,
            pin: data['pin'] as String?,
            points: (data['points'] as num?)?.toInt() ?? 0,
            stars: (data['stars'] as num?)?.toInt() ?? 0,
            streakDays: (data['streakDays'] as num?)?.toInt() ?? 0,
            customPhotoPath: data['customPhotoPath'] as String?,
            tagline: data['tagline'] as String?,
            privacyLevel: privacy,
          );
        }).toList();

        if (liveMembers.isNotEmpty) {
          state = state.copyWith(members: liveMembers);
        }
      }

      // 3. 3-Tier Privacy Fetch:
      //    (a) Public developer-curated notes from /public_dining_notes (READ-ONLY)
      //    (b) Isolated family-private notes from /families/{familyId}/dining_notes
      List<DiningTableNote> publicNotes =
          state.diningTableNotes.where((n) => n.isPublic).toList();
      try {
        final publicSnap = await FirebaseFirestore.instance
            .collection('public_dining_notes')
            .orderBy('createdAt', descending: false)
            .get();
        if (publicSnap.docs.isNotEmpty) {
          final fetchedPublic = publicSnap.docs.map((doc) {
            final data = doc.data();
            final ts = data['createdAt'];
            return DiningTableNote(
              id: 'pub_${doc.id}',
              textMs: (data['textMs'] as String?) ??
                  (data['textEn'] as String?) ??
                  '',
              textEn: (data['textEn'] as String?) ??
                  (data['textMs'] as String?) ??
                  '',
              authorName: (data['authorName'] as String?) ?? 'ERAT',
              isPublic: true,
              createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
            );
          }).where((n) => n.textEn.isNotEmpty || n.textMs.isNotEmpty).toList();
          if (fetchedPublic.isNotEmpty) {
            publicNotes = fetchedPublic;
          }
        }
      } catch (e) {
        debugPrint('ℹ️ Public dining notes fallback to built-in seed: $e');
      }

      List<DiningTableNote> familyNotes =
          state.diningTableNotes.where((n) => !n.isPublic).toList();
      try {
        final notesCol = familyDoc.collection('dining_notes');
        final notesSnap =
            await notesCol.orderBy('createdAt', descending: false).get();
        if (notesSnap.docs.isNotEmpty) {
          familyNotes = notesSnap.docs.map((doc) {
            final data = doc.data();
            final ts = data['createdAt'];
            return DiningTableNote(
              id: doc.id,
              textMs: (data['textMs'] as String?) ?? '',
              textEn: (data['textEn'] as String?) ?? '',
              authorName: (data['authorName'] as String?) ?? 'Family',
              isPublic: false,
              createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
            );
          }).where((n) => n.textEn.isNotEmpty || n.textMs.isNotEmpty).toList();
        }
      } catch (e) {
        debugPrint('ℹ️ Family dining notes fallback to local cache: $e');
      }

      final mergedNotes = [...familyNotes, ...publicNotes];
      if (mergedNotes.isNotEmpty) {
        state = state.copyWith(diningTableNotes: mergedNotes);
        await _saveDiningNotesCacheLocally(state.family.id, mergedNotes);
      }

      // 4. Hydrate Wish Goals, Routine Requests, Activities, Messages, Ledger,
      //    Private Journal & Parent Community Posts from Cloud Firestore
      await _hydrateAllCollectionsFromFirestore(familyDoc);
    } catch (_) {
      // Offline fallback maintains current state
    }
  }

  Future<void> _hydrateAllCollectionsFromFirestore(
    DocumentReference<Map<String, dynamic>> familyDoc,
  ) async {
    // 4a. Wish Goals
    try {
      final snap = await familyDoc.collection('wish_goals').get();
      if (snap.docs.isNotEmpty) {
        final loaded = snap.docs.map((doc) {
          final d = doc.data();
          final statusStr = (d['status'] as String?) ?? 'active';
          final basisStr = (d['basis'] as String?) ?? 'weekly';
          return WishGoal(
            id: doc.id,
            memberId: (d['memberId'] as String?) ?? state.activeMemberId,
            memberName: (d['memberName'] as String?) ?? 'Member',
            titleMs: (d['titleMs'] as String?) ?? '',
            titleEn: (d['titleEn'] as String?) ?? '',
            iconEmoji: (d['iconEmoji'] as String?) ?? '🎁',
            customImagePath: d['customImagePath'] as String?,
            focusActivity: d['focusActivity'] as String?,
            targetPoints: (d['targetPoints'] as num?)?.toInt() ?? 50,
            currentPoints: (d['currentPoints'] as num?)?.toInt() ?? 0,
            status: WishGoalStatus.values.firstWhere(
              (s) => s.name == statusStr,
              orElse: () => WishGoalStatus.active,
            ),
            approvedByName: d['approvedByName'] as String?,
            basis: WishGoalBasis.values.firstWhere(
              (b) => b.name == basisStr,
              orElse: () => WishGoalBasis.weekly,
            ),
          );
        }).toList();
        state = state.copyWith(wishGoals: loaded);
      }
    } catch (_) {}

    // 4b. Routine Approval Requests
    try {
      final snap = await familyDoc.collection('routine_requests').get();
      if (snap.docs.isNotEmpty) {
        final loaded = snap.docs.map((doc) {
          final d = doc.data();
          final statusStr = (d['status'] as String?) ?? 'pendingApproval';
          final reqTs = d['requestedAt'];
          final appTs = d['approvedAt'];
          return RoutineApprovalRequest(
            id: doc.id,
            memberId: (d['memberId'] as String?) ?? '',
            memberName: (d['memberName'] as String?) ?? 'Member',
            memberAvatar: (d['memberAvatar'] as String?) ?? '🌟',
            routineId: (d['routineId'] as String?) ?? '',
            routineTitleMs: (d['routineTitleMs'] as String?) ?? '',
            routineTitleEn: (d['routineTitleEn'] as String?) ?? '',
            timeLabel: (d['timeLabel'] as String?) ?? '',
            stars: (d['stars'] as num?)?.toInt() ?? 2,
            status: RoutineStatus.values.firstWhere(
              (s) => s.name == statusStr,
              orElse: () => RoutineStatus.pendingApproval,
            ),
            approvedByName: d['approvedByName'] as String?,
            requestedAt: reqTs is Timestamp ? reqTs.toDate() : DateTime.now(),
            approvedAt: appTs is Timestamp ? appTs.toDate() : null,
          );
        }).toList();
        state = state.copyWith(routineRequests: loaded);
      }
    } catch (_) {}

    // 4c. Family Chat Messages
    try {
      final snap = await familyDoc
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .limit(100)
          .get();
      if (snap.docs.isNotEmpty) {
        final loaded = snap.docs.map((doc) {
          final d = doc.data();
          final ts = d['createdAt'];
          return ChatMessage(
            id: doc.id,
            senderId: (d['senderId'] as String?) ?? '',
            senderName: (d['senderName'] as String?) ?? 'Family',
            senderAvatar: (d['senderAvatar'] as String?) ?? '👤',
            channel: (d['channel'] as String?) ?? 'family_group',
            content: (d['content'] as String?) ?? '',
            isSticker: (d['isSticker'] as bool?) ?? false,
            isAudioVoiceNote: (d['isAudioVoiceNote'] as bool?) ?? false,
            audioDuration: d['audioDuration'] as String?,
            audioUrl: d['audioUrl'] as String?,
            createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
          );
        }).toList();
        state = state.copyWith(messages: loaded);
      }
    } catch (_) {}

    // 4d. Private Journal Entries (for active member)
    try {
      final snap = await familyDoc
          .collection('members')
          .doc(state.activeMemberId)
          .collection('private_journal')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      if (snap.docs.isNotEmpty) {
        final loaded = snap.docs.map((doc) {
          final d = doc.data();
          final ts = d['createdAt'];
          return JournalEntry(
            id: doc.id,
            memberId: (d['memberId'] as String?) ?? state.activeMemberId,
            memberName: (d['memberName'] as String?) ?? state.activeMember.name,
            moodEmoji: (d['moodEmoji'] as String?) ?? '😊',
            title: (d['title'] as String?) ?? '',
            content: (d['content'] as String?) ?? '',
            isVoiceEntry: (d['isVoiceEntry'] as bool?) ?? false,
            voiceDuration: d['voiceDuration'] as String?,
            audioUrl: d['audioUrl'] as String?,
            isSharedWithParents: (d['isSharedWithParents'] as bool?) ?? false,
            createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
          );
        }).toList();
        final otherMembersEntries = state.journalEntries
            .where((e) => e.memberId != state.activeMemberId)
            .toList();
        state = state.copyWith(
          journalEntries: [...loaded, ...otherMembersEntries],
        );
      }
    } catch (_) {}

    // 4e. Parent Community Posts (Global across all Parent IDs)
    try {
      final snap = await FirebaseFirestore.instance
          .collection('parent_community_posts')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      if (snap.docs.isNotEmpty) {
        final loaded = snap.docs.map((doc) {
          final d = doc.data();
          final ts = d['createdAt'];
          final rawComments = (d['comments'] as List<dynamic>?) ?? const [];
          final parsedComments = rawComments.whereType<Map<String, dynamic>>().map((c) {
            final cTs = c['createdAt'];
            return CommunityComment(
              id: (c['id'] as String?) ?? '',
              authorId: (c['authorId'] as String?) ?? '',
              authorName: (c['authorName'] as String?) ?? 'Parent',
              authorAvatar: (c['authorAvatar'] as String?) ?? '👩',
              content: (c['content'] as String?) ?? '',
              createdAt: cTs is Timestamp
                  ? cTs.toDate()
                  : (DateTime.tryParse((cTs as String?) ?? '') ?? DateTime.now()),
            );
          }).toList();
          return CommunityKnowledgePost(
            id: doc.id,
            authorId: (d['authorId'] as String?) ?? '',
            authorName: (d['authorName'] as String?) ?? 'Parent',
            authorRole: (d['authorRole'] as String?) ?? 'ERAT Parent',
            authorAvatar: (d['authorAvatar'] as String?) ?? '👩',
            countryCode: (d['countryCode'] as String?) ?? 'MY',
            countryName: (d['countryName'] as String?) ?? 'Malaysia 🇲🇾',
            language: (d['language'] as String?) ?? 'en',
            isSharedForKids: (d['isSharedForKids'] as bool?) ?? false,
            isInternational: (d['isInternational'] as bool?) ?? false,
            title: (d['title'] as String?) ?? '',
            content: (d['content'] as String?) ?? '',
            tag: (d['tag'] as String?) ?? 'Parenting',
            likes: (d['likes'] as num?)?.toInt() ?? 0,
            replies: (d['replies'] as num?)?.toInt() ?? parsedComments.length,
            upvotedByIds: ((d['upvotedByIds'] as List<dynamic>?) ?? const [])
                .map((e) => e.toString())
                .toList(),
            comments: parsedComments,
            createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
          );
        }).toList();
        state = state.copyWith(communityPosts: loaded);
      }
    } catch (_) {}

    // 4g. Shared Family Calendar Events
    try {
      final snap = await familyDoc
          .collection('calendar_events')
          .orderBy('eventDate', descending: false)
          .get();
      if (snap.docs.isNotEmpty) {
        final loaded = snap.docs.map((doc) {
          final d = doc.data();
          final evTs = d['eventDate'];
          final crTs = d['createdAt'];
          return FamilyCalendarEvent(
            id: doc.id,
            title: (d['title'] as String?) ?? '',
            description: d['description'] as String?,
            emoji: (d['emoji'] as String?) ?? '🎉',
            eventDate: evTs is Timestamp ? evTs.toDate() : DateTime.now(),
            timeLabel: d['timeLabel'] as String?,
            createdById: (d['createdById'] as String?) ?? '',
            createdByName: (d['createdByName'] as String?) ?? 'Family',
            participantIds: ((d['participantIds'] as List<dynamic>?) ?? const [])
                .map((e) => e.toString())
                .toList(),
            createdAt: crTs is Timestamp ? crTs.toDate() : DateTime.now(),
          );
        }).toList();
        state = state.copyWith(calendarEvents: loaded);
      }
    } catch (_) {}

    // 4h. Family Activities / Quests
    try {
      final snap = await familyDoc.collection('activities').get();
      if (snap.docs.isNotEmpty) {
        final loaded = snap.docs.map((doc) {
          final d = doc.data();
          final catStr = (d['category'] as String?) ?? 'goodHabit';
          final modeStr = (d['participationMode'] as String?) ?? 'anyone';
          final schedTs = d['scheduledDate'];
          return BondingActivity(
            id: doc.id,
            titleMs: (d['titleMs'] as String?) ?? '',
            titleEn: (d['titleEn'] as String?) ?? '',
            descMs: (d['descMs'] as String?) ?? '',
            descEn: (d['descEn'] as String?) ?? '',
            iconEmoji: (d['iconEmoji'] as String?) ?? '⭐',
            customImagePath: d['customImagePath'] as String?,
            category: ActivityCategory.values.firstWhere(
              (c) => c.name == catStr,
              orElse: () => ActivityCategory.goodHabit,
            ),
            participationMode: ParticipationMode.values.firstWhere(
              (p) => p.name == modeStr,
              orElse: () => ParticipationMode.anyone,
            ),
            durationMinutes: (d['durationMinutes'] as num?)?.toInt() ?? 10,
            points: (d['points'] as num?)?.toInt() ?? 20,
            stars: (d['stars'] as num?)?.toInt() ?? 2,
            minAge: (d['minAge'] as num?)?.toInt() ?? 1,
            maxAge: (d['maxAge'] as num?)?.toInt() ?? 99,
            requiresParentVerification:
                (d['requiresParentVerification'] as bool?) ?? true,
            completedByMemberIds:
                ((d['completedByMemberIds'] as List<dynamic>?) ?? const [])
                    .map((e) => e.toString())
                    .toList(),
            pendingVerificationMemberIds:
                ((d['pendingVerificationMemberIds'] as List<dynamic>?) ??
                        const [])
                    .map((e) => e.toString())
                    .toList(),
            isPrivateNote: (d['isPrivateNote'] as bool?) ?? false,
            scheduledDate: schedTs is Timestamp ? schedTs.toDate() : null,
          );
        }).toList();
        state = state.copyWith(activities: loaded);
      }
    } catch (_) {}
  }

  static EratAppState _initialSeedState() {
    final now = DateTime.now();
    // Seed members across all 5 age bands + Owner Parent so user can experience the full ERAT blueprint
    final members = [
      FamilyMember(
        id: 'parent_owner',
        name: 'Sarah (Mom)',
        avatarEmoji: '👩🏻‍💼',
        role: MemberRole.owner,
        birthMonth: 5,
        birthYear: now.year - 36,
        pin: '1234',
        privacyLevel: PrivacyLevel.family,
        points: 0,
        stars: 0,
        streakDays: 0,
        milestones: const [],
      ),
      FamilyMember(
        id: 'child_explorer',
        name: 'Emmi',
        avatarEmoji: '👧🏻',
        role: MemberRole.child,
        birthMonth: 6,
        birthYear: now.year - 4, // 4 yrs -> Little Explorer (1-4)
        pin: '1234',
        privacyLevel: PrivacyLevel.family,
        points: 0,
        stars: 0,
        streakDays: 0,
        milestones: const [],
      ),
      FamilyMember(
        id: 'child_builder',
        name: 'Alex',
        avatarEmoji: '👦🏻',
        role: MemberRole.child,
        birthMonth: 3,
        birthYear: now.year - 8, // 8 yrs -> Happy Habit Builder (5-9)
        pin: '1234',
        privacyLevel: PrivacyLevel.family,
        points: 0,
        stars: 0,
        streakDays: 0,
        milestones: const [],
      ),
      FamilyMember(
        id: 'child_achiever',
        name: 'Adam',
        avatarEmoji: '🚀',
        role: MemberRole.child,
        birthMonth: 8,
        birthYear: now.year - 11, // 11 yrs -> Goal Achiever (10-12)
        pin: '1111',
        privacyLevel: PrivacyLevel.family,
        points: 0,
        stars: 0,
        streakDays: 0,
        milestones: const [],
      ),
      FamilyMember(
        id: 'teen_goal',
        name: 'Hana',
        avatarEmoji: '🎧',
        role: MemberRole.teen,
        birthMonth: 2,
        birthYear: now.year - 15, // 15 yrs -> My Life, My Goals (13-17)
        pin: '2222',
        privacyLevel: PrivacyLevel.selected,
        points: 0,
        stars: 0,
        streakDays: 0,
        milestones: const [],
      ),
      FamilyMember(
        id: 'adult_bond',
        name: 'Daniel',
        avatarEmoji: '🎓',
        role: MemberRole.adult,
        birthMonth: 9,
        birthYear: now.year - 20, // 20 yrs -> Lifelong Family Bond (18+)
        pin: '3333',
        privacyLevel: PrivacyLevel.family,
        points: 0,
        stars: 0,
        streakDays: 0,
        milestones: const [],
      ),
    ];

    final activities = const <BondingActivity>[];
    final wishGoals = const <WishGoal>[];
    final ledger = const <LedgerEntry>[];
    final messages = const <ChatMessage>[];
    final journalEntries = const <JournalEntry>[];

    final communityPosts = [
      // Parent-Only Community Discussions (strictly parent-to-parent, never shown to kids)
      CommunityKnowledgePost(
        id: 'post_p_1',
        authorId: 'parent_farah',
        authorName: 'Farah M.',
        authorRole: 'Mom of 2 (4y & 8y)',
        authorAvatar: '👩🏻',
        countryCode: 'MY',
        countryName: 'Malaysia 🇲🇾',
        language: 'en',
        isSharedForKids: false,
        isInternational: false,
        title: 'How we finally got our 4yo & 8yo to tidy up toys without yelling',
        content:
            'Fellow parents — turning cleanup into a 3-minute song challenge completely changed our evenings. Instead of repeating myself five times, I play one song and we race to put toys back together. Curious what routines work for your kids?',
        tag: 'Kids & Habits',
        likes: 38,
        replies: 2,
        comments: [
          CommunityComment(
            id: 'cmt_seed_1',
            authorId: 'parent_david',
            authorName: 'David T.',
            authorAvatar: '👨🏻‍💻',
            content:
                'Doing it together for the first 2 minutes makes a huge difference! My 6yo copies whatever I start.',
            createdAt: now.subtract(const Duration(hours: 1, minutes: 20)),
          ),
          CommunityComment(
            id: 'cmt_seed_2',
            authorId: 'parent_nurul',
            authorName: 'Dr. Nurul H.',
            authorAvatar: '👩🏻‍🏫',
            content:
                'Love this! Visual checklists and playful timers work so well because young kids respond to rhythm better than lectures.',
            createdAt: now.subtract(const Duration(minutes: 45)),
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      CommunityKnowledgePost(
        id: 'post_p_2',
        authorId: 'parent_nurul',
        authorName: 'Dr. Nurul H.',
        authorRole: 'Child Psychologist & Mom',
        authorAvatar: '👩🏻‍🏫',
        countryCode: 'MY',
        countryName: 'Malaysia 🇲🇾',
        language: 'en',
        isSharedForKids: false,
        isInternational: false,
        title: 'Parents: What helps when your child melts down after school?',
        content:
            'After-school restraint collapse is so real! Before asking about homework or chores, giving our kids 15 minutes of quiet snack time + warm eye contact lowers cortisol dramatically. Sharing in case another parent needs this reminder today.',
        tag: 'Parenting',
        likes: 64,
        replies: 1,
        comments: [
          CommunityComment(
            id: 'cmt_seed_3',
            authorId: 'parent_farah',
            authorName: 'Farah M.',
            authorAvatar: '👩🏻',
            content:
                'Needed this reminder! Waiting 20 minutes before asking about schoolwork stopped 90% of our afternoon arguments.',
            createdAt: now.subtract(const Duration(hours: 3)),
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      CommunityKnowledgePost(
        id: 'post_p_3',
        authorId: 'parent_aisyah',
        authorName: 'Aisyah K.',
        authorRole: 'Mom of 3 (6y, 11y, 15y)',
        authorAvatar: '🧕🏻',
        countryCode: 'MY',
        countryName: 'Malaysia 🇲🇾',
        language: 'en',
        isSharedForKids: false,
        isInternational: false,
        title: 'Keeping a 15-year-old talking to us without feeling interrogated',
        content:
            'Parents of teens — what worked for us was switching from direct questions at dinner to 10-minute car rides or late-night tea chats. When I listen first without jumping straight into advice, she actually opens up about school and friends.',
        tag: 'Bonding',
        likes: 52,
        replies: 0,
        createdAt: now.subtract(const Duration(hours: 10)),
      ),
      CommunityKnowledgePost(
        id: 'post_p_4',
        authorId: 'parent_david',
        authorName: 'David Tan',
        authorRole: 'Father of 3 (Singapore 🇸🇬)',
        authorAvatar: '👨🏻‍💻',
        countryCode: 'SG',
        countryName: 'Singapore 🇸🇬',
        language: 'en',
        isSharedForKids: false,
        isInternational: true,
        title: 'Ask Parents: How do you handle phones at the dinner table?',
        content:
            'We started a "phones in the kitchen basket at 7:30 PM" rule — including Mom and Dad! The hardest part was actually us parents sticking to it, but our kids respect the rule way more when they see us modeling it too.',
        tag: 'Ask Parents',
        likes: 47,
        replies: 0,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      CommunityKnowledgePost(
        id: 'post_p_5',
        authorId: 'parent_emily',
        authorName: 'Emily Carter',
        authorRole: 'Mom & Family Educator',
        authorAvatar: '👩🏼',
        countryCode: 'GLOBAL',
        countryName: 'International 🌍',
        language: 'en',
        isSharedForKids: false,
        isInternational: true,
        title: 'Modeling sincere apologies to our kids teaches real adab & humility',
        content:
            'I lost my patience this morning during the school rush and raised my voice. Tonight I sat with my 8yo and apologized sincerely. He hugged me and said "It\'s okay Mom, I\'ll try to get my shoes faster too." Repairing matters more than being perfect.',
        tag: 'Adab & Ethics',
        likes: 89,
        replies: 0,
        createdAt: now.subtract(const Duration(days: 1, hours: 4)),
      ),
    ];

    return EratAppState(
      family: FamilySpace(
        id: 'fam_erat_01',
        name: 'Happy Family',
        inviteCode: 'ERAT-48H-9281',
        inviteExpiresAt: now.add(const Duration(hours: 48)),
        familyGoalTitleMs: 'Riadah Hujung Minggu',
        familyGoalTitleEn: 'Weekend Family Outing',
        familyGoalTargetStars: 100,
        familyGoalCurrentStars: 0,
      ),
      members: members,
      activeMemberId: 'parent_owner',
      activities: activities,
      wishGoals: wishGoals,
      ledger: ledger,
      messages: messages,
      journalEntries: journalEntries,
      communityPosts: communityPosts,
      calendarEvents: const [],
      diningTableNotes: [
        DiningTableNote(
          id: 'pub_note_1',
          textMs: 'Kerjasama kecil hari ini membina kenangan terindah bersama.',
          textEn: 'Small efforts today build cherished family memories.',
          authorName: 'ERAT',
          isPublic: true,
          createdAt: now.subtract(const Duration(days: 6)),
        ),
        DiningTableNote(
          id: 'pub_note_2',
          textMs: 'Kata-kata lembut di rumah membuat semua rasa disayangi.',
          textEn: 'Kind words at home make everyone feel safe and loved.',
          authorName: 'ERAT',
          isPublic: true,
          createdAt: now.subtract(const Duration(days: 5)),
        ),
        DiningTableNote(
          id: 'pub_note_3',
          textMs: 'Berbual 10 minit malam ini lebih bermakna daripada skrin.',
          textEn: 'A 10-minute chat tonight means more than hours on a screen.',
          authorName: 'ERAT',
          isPublic: true,
          createdAt: now.subtract(const Duration(days: 4)),
        ),
        DiningTableNote(
          id: 'pub_note_4',
          textMs: 'Terima kasih kerana membantu mengemas rumah hari ini!',
          textEn: 'Thank you for helping keep our home cozy today!',
          authorName: 'ERAT',
          isPublic: true,
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        DiningTableNote(
          id: 'pub_note_5',
          textMs: 'Setiap bintang yang dikumpul mengeratkan lagi keluarga kita.',
          textEn: 'Every star earned together brings our family closer.',
          authorName: 'ERAT',
          isPublic: true,
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        DiningTableNote(
          id: 'pub_note_6',
          textMs: 'Jom kongsi satu perkara gembira hari ini waktu makan malam.',
          textEn: 'Share one happy moment from today over dinner tonight.',
          authorName: 'ERAT',
          isPublic: true,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ],
      familyGoals: [
        FamilyRewardGoal(
          id: 'fgoal_active_1',
          titleMs: 'Riadah Hujung Minggu',
          titleEn: 'Weekend Family Outing',
          targetStars: 100,
          currentStars: 78,
          imagePath: 'assets/images/family_goal_cozy.jpg',
          status: FamilyGoalStatus.active,
          createdAt: now.subtract(const Duration(days: 8)),
        ),
        FamilyRewardGoal(
          id: 'fgoal_ready_1',
          titleMs: 'Malam Wayang & Bertih Jagung',
          titleEn: 'Family Movie & Popcorn Night',
          targetStars: 40,
          currentStars: 40,
          status: FamilyGoalStatus.readyToClaim,
          createdAt: now.subtract(const Duration(days: 12)),
        ),
        FamilyRewardGoal(
          id: 'fgoal_claimed_1',
          titleMs: 'Jalan-Jalan Aiskrim Petang',
          titleEn: 'Evening Ice Cream Walk',
          targetStars: 30,
          currentStars: 30,
          status: FamilyGoalStatus.claimed,
          createdAt: now.subtract(const Duration(days: 20)),
          claimedAt: now.subtract(const Duration(days: 5)),
        ),
      ],
    );
  }

  /// Add a personal journal entry for the active member (especially children)
  void addJournalEntry({
    required String title,
    required String content,
    required String moodEmoji,
    bool isVoiceEntry = false,
    String? voiceDuration,
    String? audioUrl,
    bool isSharedWithParents = false,
  }) {
    final member = state.activeMember;
    final entry = JournalEntry(
      id: 'journal_${DateTime.now().millisecondsSinceEpoch}',
      memberId: member.id,
      memberName: member.name,
      moodEmoji: moodEmoji,
      title: title.trim().isEmpty ? 'Catatan Harian ${member.name}' : title.trim(),
      content: content.trim(),
      isVoiceEntry: isVoiceEntry,
      voiceDuration: voiceDuration,
      audioUrl: audioUrl,
      isSharedWithParents: isSharedWithParents,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(journalEntries: [entry, ...state.journalEntries]);
    _syncJournalEntryToFirestore(entry);
  }

  /// Delete a personal journal entry belonging to the active member
  void deleteJournalEntry(String entryId) {
    final target = state.journalEntries.where((e) => e.id == entryId).toList();
    state = state.copyWith(
      journalEntries:
          state.journalEntries.where((e) => e.id != entryId).toList(),
    );
    if (target.isNotEmpty) {
      _deleteJournalEntryFromFirestore(target.first.memberId, entryId);
    }
  }

  /// Add a new community / knowledge post authored by parent
  void addCommunityPost({
    required String title,
    required String content,
    required String tag,
    required String countryCode,
    required String countryName,
    required String language,
    bool isSharedForKids = false,
    bool isInternational = false,
  }) {
    final member = state.activeMember;
    final post = CommunityKnowledgePost(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      authorId: member.id,
      authorName: member.name,
      authorRole: member.isParentOrGuardian ? 'ERAT Parent' : 'Family Member',
      authorAvatar: member.avatarEmoji,
      countryCode: countryCode,
      countryName: countryName,
      language: language,
      isSharedForKids: isSharedForKids,
      isInternational: isInternational,
      title: title.trim(),
      content: content.trim(),
      tag: tag,
      likes: 1,
      replies: 0,
      upvotedByIds: [member.id],
      comments: const [],
      createdAt: DateTime.now(),
    );
    state = state.copyWith(communityPosts: [post, ...state.communityPosts]);
    _syncCommunityPostToFirestore(post);
  }

  /// Toggle upvote on a community post (Reddit-style)
  void toggleLikePost(String postId) {
    final uid = state.activeMember.id;
    CommunityKnowledgePost? changed;
    final updated = state.communityPosts.map((p) {
      if (p.id != postId) return p;
      final alreadyUpvoted = p.upvotedByIds.contains(uid);
      final nextUpvotes = alreadyUpvoted
          ? p.upvotedByIds.where((id) => id != uid).toList()
          : [...p.upvotedByIds, uid];
      final nextLikes =
          alreadyUpvoted ? (p.likes > 0 ? p.likes - 1 : 0) : p.likes + 1;
      changed = p.copyWith(likes: nextLikes, upvotedByIds: nextUpvotes);
      return changed!;
    }).toList();
    state = state.copyWith(communityPosts: updated);
    if (changed != null) _syncCommunityPostToFirestore(changed!);
  }

  /// Add a comment/reply to a Parent Community post
  void addCommunityComment({
    required String postId,
    required String content,
  }) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return;
    final member = state.activeMember;
    final comment = CommunityComment(
      id: 'cmt_${DateTime.now().millisecondsSinceEpoch}',
      authorId: member.id,
      authorName: member.name,
      authorAvatar: member.avatarEmoji,
      content: trimmed,
      createdAt: DateTime.now(),
    );
    CommunityKnowledgePost? changed;
    final updated = state.communityPosts.map((p) {
      if (p.id != postId) return p;
      changed = p.copyWith(
        replies: p.replies + 1,
        comments: [...p.comments, comment],
      );
      return changed!;
    }).toList();
    state = state.copyWith(communityPosts: updated);
    if (changed != null) _syncCommunityPostToFirestore(changed!);
  }

  /// Delete own post from Parent Community
  void deleteCommunityPost(String postId) {
    state = state.copyWith(
      communityPosts:
          state.communityPosts.where((p) => p.id != postId).toList(),
    );
    _deleteCommunityPostFromFirestore(postId);
  }

  /// Report a post (App Store Guideline 1.2 UGC compliance)
  void reportCommunityPost(String postId) {
    state = state.copyWith(
      reportedPostIds: {...state.reportedPostIds, postId},
    );
  }

  /// Block a community author (App Store Guideline 1.2 UGC compliance)
  void blockCommunityAuthor(String authorKey) {
    state = state.copyWith(
      blockedAuthorIds: {...state.blockedAuthorIds, authorKey},
    );
  }

  /// Switch active profile (after PIN verification if required)
  void switchProfile(String memberId) {
    state = state.copyWith(activeMemberId: memberId);
  }

  /// Update family space name (FR-02) and sync to Cloud Firestore
  void updateFamilyName(String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    state = state.copyWith(
      family: state.family.copyWith(name: trimmed),
    );
    _syncFamilyToFirestore(state.family);
  }

  /// Update Family Settings (Family Name, Star Goal Title, Target Stars, Family Photo) and persist to Cloud Firestore
  Future<void> updateFamilySettings({
    String? familyName,
    String? goalTitle,
    int? goalTargetStars,
    String? photoPath,
    bool clearPhoto = false,
  }) async {
    final cleanName = familyName?.trim();
    final cleanGoal = goalTitle?.trim();
    final updatedFamily = state.family.copyWith(
      name: (cleanName != null && cleanName.isNotEmpty)
          ? cleanName
          : state.family.name,
      familyGoalTitleMs: (cleanGoal != null && cleanGoal.isNotEmpty)
          ? cleanGoal
          : state.family.familyGoalTitleMs,
      familyGoalTitleEn: (cleanGoal != null && cleanGoal.isNotEmpty)
          ? cleanGoal
          : state.family.familyGoalTitleEn,
      familyGoalTargetStars: (goalTargetStars != null && goalTargetStars > 0)
          ? goalTargetStars
          : state.family.familyGoalTargetStars,
      photoPath: photoPath,
      clearPhoto: clearPhoto,
    );
    state = state.copyWith(family: updatedFamily);
    await _saveFamilyCacheLocally(updatedFamily);
    await _syncFamilyToFirestore(updatedFamily);
  }

  /// Add a private Dining Table Note strictly to this family (/families/{familyId}/dining_notes)
  Future<void> addDiningTableNote(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final note = DiningTableNote(
      id: 'note_${DateTime.now().millisecondsSinceEpoch}',
      textMs: clean,
      textEn: clean,
      authorName: state.activeMember.name,
      isPublic: false,
      createdAt: DateTime.now(),
    );
    final updatedNotes = [note, ...state.diningTableNotes];
    state = state.copyWith(diningTableNotes: updatedNotes);
    await _saveDiningNotesCacheLocally(state.family.id, updatedNotes);

    if (!isFirebaseReady || Firebase.apps.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('families')
          .doc(state.family.id)
          .collection('dining_notes')
          .doc(note.id)
          .set({
        'id': note.id,
        'textMs': note.textMs,
        'textEn': note.textEn,
        'authorName': note.authorName,
        'createdAt': Timestamp.fromDate(note.createdAt),
      });
    } catch (e) {
      debugPrint('⚠️ Firestore add dining note error: $e');
    }
  }

  /// Delete a private Family Dining Table Note (Public ERAT notes are read-only)
  Future<void> deleteDiningTableNote(String noteId) async {
    final target = state.diningTableNotes
        .where((n) => n.id == noteId)
        .cast<DiningTableNote?>()
        .firstWhere((_) => true, orElse: () => null);
    if (target == null || target.isPublic) return; // Public notes are read-only
    final updatedNotes =
        state.diningTableNotes.where((n) => n.id != noteId).toList();
    state = state.copyWith(diningTableNotes: updatedNotes);
    await _saveDiningNotesCacheLocally(state.family.id, updatedNotes);

    if (!isFirebaseReady || Firebase.apps.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('families')
          .doc(state.family.id)
          .collection('dining_notes')
          .doc(noteId)
          .delete();
    } catch (e) {
      debugPrint('⚠️ Firestore delete dining note error: $e');
    }
  }

  /// Register a new Firebase Auth user and persist User + Family + Owner Member in Cloud Firestore
  Future<void> registerUserAndFamily({
    required String uid,
    required String email,
    required String displayName,
    required String familyName,
  }) async {
    final now = DateTime.now();
    final safePrefix = uid.length >= 8 ? uid.substring(0, 8) : uid;
    final familyId = 'fam_$safePrefix';
    final rand = 1000 + Random().nextInt(8999);
    final inviteCode = 'ERAT-48H-$rand';
    final cleanName = displayName.trim().isEmpty
        ? email.split('@').first
        : displayName.trim();
    final cleanFamilyName =
        familyName.trim().isEmpty ? '$cleanName Family' : familyName.trim();

    final newFamily = FamilySpace(
      id: familyId,
      name: cleanFamilyName,
      inviteCode: inviteCode,
      inviteExpiresAt: now.add(const Duration(hours: 48)),
      familyGoalTitleMs: state.family.familyGoalTitleMs,
      familyGoalTitleEn: state.family.familyGoalTitleEn,
      familyGoalTargetStars: state.family.familyGoalTargetStars,
      familyGoalCurrentStars: 0,
    );

    final ownerMember = FamilyMember(
      id: 'owner_$safePrefix',
      familyId: familyId,
      name: cleanName,
      avatarEmoji: '👩🏻‍💼',
      role: MemberRole.owner,
      birthMonth: 1,
      birthYear: now.year - 32,
      pin: '1234',
      privacyLevel: PrivacyLevel.family,
      points: 0,
      stars: 0,
      streakDays: 1,
      milestones: const ['First Week'],
    );

    // Start brand-new real family account with a clean slate (NO demo child data!)
    final publicNotesOnly =
        state.diningTableNotes.where((n) => n.isPublic).toList();
    state = state.copyWith(
      family: newFamily,
      members: [ownerMember],
      activeMemberId: ownerMember.id,
      activities: const [],
      wishGoals: const [],
      ledger: const [],
      messages: const [],
      journalEntries: const [],
      routineRequests: const [],
      calendarEvents: const [],
      diningTableNotes: publicNotesOnly,
    );

    if (!isFirebaseReady || Firebase.apps.isEmpty) return;

    final db = FirebaseFirestore.instance;
    final familyRef = db.collection('families').doc(familyId);

    // 1. Save family document in /families/{familyId}
    await familyRef.set({
      'id': newFamily.id,
      'name': newFamily.name,
      'ownerUid': uid,
      'inviteCode': newFamily.inviteCode,
      'inviteExpiresAt': Timestamp.fromDate(newFamily.inviteExpiresAt),
      'familyGoalTitleMs': newFamily.familyGoalTitleMs,
      'familyGoalTitleEn': newFamily.familyGoalTitleEn,
      'familyGoalTargetStars': newFamily.familyGoalTargetStars,
      'familyGoalCurrentStars': newFamily.familyGoalCurrentStars,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2. Save user document in /users/{uid}
    await db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email.trim().toLowerCase(),
      'displayName': cleanName,
      'familyId': familyId,
      'memberId': ownerMember.id,
      'role': ownerMember.role.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. Save owner member in /families/{familyId}/members/{memberId}
    await _syncMemberToFirestore(ownerMember);
  }

  /// Load authenticated user and their family space + members from Cloud Firestore
  Future<bool> loadUserAndFamilyFromFirestore({
    required String uid,
    required String email,
    String? fallbackDisplayName,
  }) async {
    if (!isFirebaseReady || Firebase.apps.isEmpty) return false;

    final db = FirebaseFirestore.instance;
    final userDoc = await db.collection('users').doc(uid).get();

    if (!userDoc.exists) {
      // Existing Firebase Auth user without a Firestore profile yet — provision one cleanly
      await registerUserAndFamily(
        uid: uid,
        email: email,
        displayName: (fallbackDisplayName != null &&
                fallbackDisplayName.trim().isNotEmpty)
            ? fallbackDisplayName
            : email.split('@').first,
        familyName: '${email.split('@').first} Family',
      );
      return false; // Let them review/customize Family Setup in Step 2
    }

    final userData = userDoc.data() ?? {};
    final familyId = userData['familyId'] as String?;
    final linkedMemberId = userData['memberId'] as String?;

    if (familyId == null || familyId.isEmpty) {
      return false;
    }

    final familyRef = db.collection('families').doc(familyId);
    final familySnap = await familyRef.get();
    if (!familySnap.exists) {
      return false;
    }

    final fData = familySnap.data() ?? {};
    final expiresRaw = fData['inviteExpiresAt'];
    final expiresAt = expiresRaw is Timestamp
        ? expiresRaw.toDate()
        : DateTime.now().add(const Duration(hours: 48));

    final loadedFamily = FamilySpace(
      id: familySnap.id,
      name: (fData['name'] as String?) ?? state.family.name,
      inviteCode: (fData['inviteCode'] as String?) ?? state.family.inviteCode,
      inviteExpiresAt: expiresAt,
      familyGoalTitleMs: (fData['familyGoalTitleMs'] as String?) ??
          state.family.familyGoalTitleMs,
      familyGoalTitleEn: (fData['familyGoalTitleEn'] as String?) ??
          state.family.familyGoalTitleEn,
      familyGoalTargetStars:
          (fData['familyGoalTargetStars'] as num?)?.toInt() ??
              state.family.familyGoalTargetStars,
      familyGoalCurrentStars:
          (fData['familyGoalCurrentStars'] as num?)?.toInt() ?? 0,
      photoPath: fData['photoPath'] as String?,
    );

    final membersSnap = await familyRef.collection('members').get();
    final loadedMembers = membersSnap.docs.map((doc) {
      final data = doc.data();
      final roleName = data['role'] as String? ?? 'child';
      final role = MemberRole.values.firstWhere(
        (r) => r.name == roleName,
        orElse: () => MemberRole.child,
      );
      final privacyName = data['privacyLevel'] as String? ?? 'family';
      final privacy = PrivacyLevel.values.firstWhere(
        (p) => p.name == privacyName,
        orElse: () => PrivacyLevel.family,
      );
      return FamilyMember(
        id: doc.id,
        familyId: (data['familyId'] as String?) ?? loadedFamily.id,
        name: (data['name'] as String?) ?? 'Member',
        avatarEmoji: (data['avatarEmoji'] as String?) ?? '👤',
        role: role,
        birthMonth: (data['birthMonth'] as num?)?.toInt() ?? 1,
        birthYear: (data['birthYear'] as num?)?.toInt() ?? 2015,
        pin: data['pin'] as String?,
        points: (data['points'] as num?)?.toInt() ?? 0,
        stars: (data['stars'] as num?)?.toInt() ?? 0,
        streakDays: (data['streakDays'] as num?)?.toInt() ?? 1,
        customPhotoPath: data['customPhotoPath'] as String?,
        tagline: data['tagline'] as String?,
        privacyLevel: privacy,
      );
    }).toList();

    final effectiveMembers = loadedMembers.isNotEmpty
        ? loadedMembers
        : state.members;
    final activeId = (linkedMemberId != null &&
            effectiveMembers.any((m) => m.id == linkedMemberId))
        ? linkedMemberId
        : effectiveMembers.first.id;

    // Clear demo seed data before hydrating this real family's own Firestore collections
    final publicNotesOnly =
        state.diningTableNotes.where((n) => n.isPublic).toList();
    state = state.copyWith(
      family: loadedFamily,
      members: effectiveMembers,
      activeMemberId: activeId,
      activities: const [],
      wishGoals: const [],
      ledger: const [],
      messages: const [],
      journalEntries: const [],
      routineRequests: const [],
      calendarEvents: const [],
      diningTableNotes: publicNotesOnly,
    );
    await _hydrateAllCollectionsFromFirestore(familyRef);
    return true;
  }

  /// Join an existing family space in Cloud Firestore using an invite code
  Future<bool> joinFamilyByInviteCode({
    required String uid,
    required String email,
    required String displayName,
    required String inviteCode,
  }) async {
    final code = inviteCode.trim().toUpperCase();
    if (code.isEmpty || !isFirebaseReady || Firebase.apps.isEmpty) {
      return false;
    }

    final db = FirebaseFirestore.instance;
    final query = await db
        .collection('families')
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return false;

    final familyDoc = query.docs.first;
    final familyId = familyDoc.id;
    final safePrefix = uid.length >= 8 ? uid.substring(0, 8) : uid;
    final memberId = 'member_$safePrefix';
    final cleanName = displayName.trim().isEmpty
        ? email.split('@').first
        : displayName.trim();

    final newMember = FamilyMember(
      id: memberId,
      familyId: familyId,
      name: cleanName,
      avatarEmoji: '👨🏻‍💼',
      role: MemberRole.coparent,
      birthMonth: 1,
      birthYear: DateTime.now().year - 32,
      pin: '1234',
      privacyLevel: PrivacyLevel.family,
      points: 0,
      stars: 0,
      streakDays: 1,
      milestones: const ['First Week'],
    );

    await db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email.trim().toLowerCase(),
      'displayName': cleanName,
      'familyId': familyId,
      'memberId': memberId,
      'role': newMember.role.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await familyDoc.reference.collection('members').doc(memberId).set({
      'id': newMember.id,
      'familyId': familyId,
      'name': newMember.name,
      'avatarEmoji': newMember.avatarEmoji,
      'role': newMember.role.name,
      'birthMonth': newMember.birthMonth,
      'birthYear': newMember.birthYear,
      'pin': newMember.pin,
      'points': newMember.points,
      'stars': newMember.stars,
      'streakDays': newMember.streakDays,
      'privacyLevel': newMember.privacyLevel.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return loadUserAndFamilyFromFirestore(
      uid: uid,
      email: email,
      fallbackDisplayName: cleanName,
    );
  }

  Future<void> _syncFamilyToFirestore(FamilySpace family) async {
    if (!_canSyncToFirestore) return;
    try {
      await FirebaseFirestore.instance
          .collection('families')
          .doc(family.id)
          .set({
        'id': family.id,
        'name': family.name,
        'inviteCode': family.inviteCode,
        'inviteExpiresAt': Timestamp.fromDate(family.inviteExpiresAt),
        'familyGoalTitleMs': family.familyGoalTitleMs,
        'familyGoalTitleEn': family.familyGoalTitleEn,
        'familyGoalTargetStars': family.familyGoalTargetStars,
        'familyGoalCurrentStars': family.familyGoalCurrentStars,
        'photoPath': family.photoPath,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ Firestore sync family error: $e');
    }
  }

  /// Complete or request verification for an activity (FR-11, FR-13, FR-15)
  void completeActivity(String activityId) {
    final member = state.activeMember;
    final idx = state.activities.indexWhere((a) => a.id == activityId);
    if (idx == -1) return;

    final activity = state.activities[idx];
    if (activity.completedByMemberIds.contains(member.id)) return;

    // If non-guardian child and activity requires parent verification:
    if (activity.requiresParentVerification && !member.isParentOrGuardian) {
      if (activity.pendingVerificationMemberIds.contains(member.id)) return;
      final updatedAct = activity.copyWith(
        pendingVerificationMemberIds: [
          ...activity.pendingVerificationMemberIds,
          member.id,
        ],
      );
      final newActivities = [...state.activities];
      newActivities[idx] = updatedAct;
      state = state.copyWith(activities: newActivities);
      _syncActivityToFirestore(updatedAct);
      return;
    }

    _awardActivityCompletion(activity, member);
  }

  /// Parent approves a pending child activity verification
  void approvePendingActivity(String activityId, String childMemberId) {
    final idx = state.activities.indexWhere((a) => a.id == activityId);
    if (idx == -1) return;
    final activity = state.activities[idx];
    final child = state.members.firstWhere((m) => m.id == childMemberId);
    _awardActivityCompletion(activity, child);
  }

  /// Parent gently declines a pending child activity so the child can try again
  void declinePendingActivity(String activityId, String childMemberId) {
    BondingActivity? updatedTarget;
    final updatedActivities = state.activities.map((a) {
      if (a.id != activityId) return a;
      updatedTarget = a.copyWith(
        pendingVerificationMemberIds: a.pendingVerificationMemberIds
            .where((id) => id != childMemberId)
            .toList(),
      );
      return updatedTarget!;
    }).toList();
    state = state.copyWith(activities: updatedActivities);
    if (updatedTarget != null) {
      _syncActivityToFirestore(updatedTarget!);
    }
  }

  /// Parent awards spontaneous praise / bonus stars to a child for good adab or kindness
  void awardBonusStarsToChild({
    required String memberId,
    required int stars,
    required String reasonMs,
    required String reasonEn,
  }) {
    final points = stars * 10;
    FamilyMember? target;
    final updatedMembers = state.members.map((m) {
      if (m.id != memberId) return m;
      target = m.copyWith(
        stars: m.stars + stars,
        points: m.points + points,
      );
      _syncMemberToFirestore(target!);
      return target!;
    }).toList();

    if (target == null) return;

    final entry = LedgerEntry(
      id: 'bonus_${DateTime.now().millisecondsSinceEpoch}',
      memberId: target!.id,
      memberName: target!.name,
      memberAvatar: target!.avatarEmoji,
      reasonMs: '$reasonMs (Pujian ${state.activeMember.name})',
      reasonEn: '$reasonEn (Praised by ${state.activeMember.name})',
      pointsEarned: points,
      starsEarned: stars,
      timestamp: DateTime.now(),
    );

    final updatedFamily = state.family.copyWith(
      familyGoalCurrentStars: state.family.familyGoalCurrentStars + stars,
    );

    state = state.copyWith(
      members: updatedMembers,
      family: updatedFamily,
      ledger: [entry, ...state.ledger],
    );
    _syncLedgerToFirestoreIfAvailable(entry);
  }

  void _awardActivityCompletion(BondingActivity activity, FamilyMember earner) {
    final actIdx = state.activities.indexWhere((a) => a.id == activity.id);
    if (actIdx == -1) return;

    final updatedActivity = activity.copyWith(
      completedByMemberIds: [
        ...activity.completedByMemberIds,
        earner.id,
      ],
      pendingVerificationMemberIds: activity.pendingVerificationMemberIds
          .where((id) => id != earner.id)
          .toList(),
    );

    final newActivities = [...state.activities];
    newActivities[actIdx] = updatedActivity;

    // Update member points & stars (ONLY for children/teens/adults, NOT parents! Parents contribute to Family Stars)
    final newMembers = state.members.map((m) {
      if (m.id != earner.id) return m;
      if (m.isParentOrGuardian) {
        return m.copyWith(streakDays: m.streakDays + 1);
      }
      final newPoints = m.points + activity.points;
      final newStars = m.stars + activity.stars;
      final newMilestones = {...m.milestones};
      if (newStars >= 10) newMilestones.add('10 Good Habits');
      if (activity.category == ActivityCategory.bonding10Min ||
          activity.category == ActivityCategory.familyChallenge) {
        newMilestones.add('Team Spirit');
      }
      return m.copyWith(
        points: newPoints,
        stars: newStars,
        streakDays: m.streakDays + 1,
        milestones: newMilestones.toList(),
      );
    }).toList();

    // Update active general Wish Goals for this member (skip focus-activity goals)
    final updatedGoalsToSync = <WishGoal>[];
    final newGoals = state.wishGoals.map((g) {
      if (g.memberId == earner.id &&
          g.status == WishGoalStatus.active &&
          !g.hasFocusActivity) {
        final updatedPts = g.currentPoints + activity.stars;
        final updated = g.copyWith(
          currentPoints: updatedPts,
          status: updatedPts >= g.targetPoints
              ? WishGoalStatus.achieved
              : WishGoalStatus.active,
        );
        updatedGoalsToSync.add(updated);
        return updated;
      }
      return g;
    }).toList();

    // Append-only ledger entry
    final entry = LedgerEntry(
      id: 'led_${DateTime.now().millisecondsSinceEpoch}',
      memberId: earner.id,
      memberName: earner.name,
      memberAvatar: earner.avatarEmoji,
      reasonMs: activity.titleMs,
      reasonEn: activity.titleEn,
      pointsEarned: activity.points,
      starsEarned: activity.stars,
      timestamp: DateTime.now(),
    );

    // Update family total stars
    final updatedFamily = state.family.copyWith(
      familyGoalCurrentStars:
          state.family.familyGoalCurrentStars + activity.stars,
    );

    state = state.copyWith(
      family: updatedFamily,
      members: newMembers,
      activities: newActivities,
      wishGoals: newGoals,
      ledger: [entry, ...state.ledger],
    );

    _syncActivityToFirestore(updatedActivity);
    _syncLedgerToFirestoreIfAvailable(entry);
    for (final g in updatedGoalsToSync) {
      _syncWishGoalToFirestore(g);
    }
  }

  /// Add stars to active member and family when completing personal routine or quest
  void addStarsToActiveMember({required int stars, required String reason}) {
    final earner = state.activeMember;
    final newMembers = state.members.map((m) {
      if (m.id != earner.id) return m;
      final newStars = m.stars + stars;
      final newPoints = m.points + (stars * 10);
      final newMilestones = {...m.milestones};
      if (newStars >= 10) newMilestones.add('10 Good Habits');
      return m.copyWith(
        stars: newStars,
        points: newPoints,
        streakDays: m.streakDays + 1,
        milestones: newMilestones.toList(),
      );
    }).toList();

    final updatedFamily = state.family.copyWith(
      familyGoalCurrentStars: state.family.familyGoalCurrentStars + stars,
    );

    final entry = LedgerEntry(
      id: 'led_${DateTime.now().millisecondsSinceEpoch}',
      memberId: earner.id,
      memberName: earner.name,
      memberAvatar: earner.avatarEmoji,
      reasonMs: reason,
      reasonEn: reason,
      pointsEarned: stars * 10,
      starsEarned: stars,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      family: updatedFamily,
      members: newMembers,
      ledger: [entry, ...state.ledger],
    );

    _syncLedgerToFirestoreIfAvailable(entry);
  }

  /// Returns current routine status for a given member & routine block.
  RoutineStatus routineStatusFor(String memberId, String routineId) {
    final reqId = '${memberId}_$routineId';
    for (final r in state.routineRequests) {
      if (r.id == reqId) return r.status;
    }
    return RoutineStatus.todo;
  }

  /// Returns the routine request record if present.
  RoutineApprovalRequest? routineRequestFor(String memberId, String routineId) {
    final reqId = '${memberId}_$routineId';
    for (final r in state.routineRequests) {
      if (r.id == reqId) return r;
    }
    return null;
  }

  /// Submit a personal daily routine block.
  /// - Children (< 13 yrs, non-parent): creates a Pending Parent Approval request
  ///   that appears immediately on Parent's Home interface (and syncs to Firestore).
  /// - Teens/Adults (13+) & Parents: completes directly and awards stars once per day.
  /// Returns true if completed immediately, false if sent for parent approval.
  bool submitPersonalRoutine({
    required FamilyMember member,
    required String routineId,
    required String titleMs,
    required String titleEn,
    required String timeLabel,
    int stars = 2,
  }) {
    final existing = routineRequestFor(member.id, routineId);
    if (existing != null &&
        (existing.status == RoutineStatus.completed ||
            existing.status == RoutineStatus.pendingApproval)) {
      return existing.status == RoutineStatus.completed;
    }

    final reqId = '${member.id}_$routineId';
    final needsParentApproval = !member.isParentOrGuardian && member.ageYears < 13;

    if (needsParentApproval) {
      final pendingReq = RoutineApprovalRequest(
        id: reqId,
        memberId: member.id,
        memberName: member.name,
        memberAvatar: member.avatarEmoji,
        routineId: routineId,
        routineTitleMs: titleMs,
        routineTitleEn: titleEn,
        timeLabel: timeLabel,
        stars: stars,
        status: RoutineStatus.pendingApproval,
        requestedAt: DateTime.now(),
      );
      final updatedList = [
        pendingReq,
        ...state.routineRequests.where((r) => r.id != reqId),
      ];
      state = state.copyWith(routineRequests: updatedList);
      _syncRoutineRequestToFirestore(pendingReq);
      return false;
    }

    // Independent / Parent completion
    final completedReq = RoutineApprovalRequest(
      id: reqId,
      memberId: member.id,
      memberName: member.name,
      memberAvatar: member.avatarEmoji,
      routineId: routineId,
      routineTitleMs: titleMs,
      routineTitleEn: titleEn,
      timeLabel: timeLabel,
      stars: stars,
      status: RoutineStatus.completed,
      approvedByName: member.name,
      requestedAt: DateTime.now(),
      approvedAt: DateTime.now(),
    );
    _completeRoutineAndAwardStars(completedReq);
    return true;
  }

  /// Parent approves a pending child routine request (from Parent's Home OR quick Parent PIN).
  void approveRoutineRequest({
    required String requestId,
    required String approverName,
  }) {
    final idx = state.routineRequests.indexWhere((r) => r.id == requestId);
    if (idx == -1) return;
    final req = state.routineRequests[idx];
    if (req.status == RoutineStatus.completed) return;

    final approvedReq = req.copyWith(
      status: RoutineStatus.completed,
      approvedByName: approverName,
      approvedAt: DateTime.now(),
    );
    _completeRoutineAndAwardStars(approvedReq);
  }

  /// Parent declines a pending routine request so the child can try again.
  void declineRoutineRequest(String requestId) {
    final updatedList =
        state.routineRequests.where((r) => r.id != requestId).toList();
    state = state.copyWith(routineRequests: updatedList);

    if (!isFirebaseReady || Firebase.apps.isEmpty) return;
    FirebaseFirestore.instance
        .collection('families')
        .doc(state.family.id)
        .collection('routine_requests')
        .doc(requestId)
        .delete()
        .catchError((_) {});
  }

  void _completeRoutineAndAwardStars(RoutineApprovalRequest completedReq) {
    FamilyMember? updatedEarner;
    final newMembers = state.members.map((m) {
      if (m.id != completedReq.memberId) return m;
      final newStars = m.stars + completedReq.stars;
      final newPoints = m.points + (completedReq.stars * 10);
      final newMilestones = {...m.milestones};
      if (newStars >= 10) newMilestones.add('10 Good Habits');
      updatedEarner = m.copyWith(
        stars: newStars,
        points: newPoints,
        streakDays: m.streakDays + 1,
        milestones: newMilestones.toList(),
      );
      return updatedEarner!;
    }).toList();

    final updatedFamily = state.family.copyWith(
      familyGoalCurrentStars:
          state.family.familyGoalCurrentStars + completedReq.stars,
    );

    final entry = LedgerEntry(
      id: 'led_${DateTime.now().millisecondsSinceEpoch}',
      memberId: completedReq.memberId,
      memberName: completedReq.memberName,
      memberAvatar: completedReq.memberAvatar,
      reasonMs: completedReq.approvedByName != null &&
              completedReq.approvedByName != completedReq.memberName
          ? '${completedReq.routineTitleMs} (Disahkan oleh ${completedReq.approvedByName})'
          : completedReq.routineTitleMs,
      reasonEn: completedReq.approvedByName != null &&
              completedReq.approvedByName != completedReq.memberName
          ? '${completedReq.routineTitleEn} (Verified by ${completedReq.approvedByName})'
          : completedReq.routineTitleEn,
      pointsEarned: completedReq.stars * 10,
      starsEarned: completedReq.stars,
      timestamp: DateTime.now(),
    );

    final updatedReqs = [
      completedReq,
      ...state.routineRequests.where((r) => r.id != completedReq.id),
    ];

    // Update matching Wish Goals:
    // - If this request is a focus-activity practice (routineId = 'focus_goal_<goalId>'),
    //   increment ONLY that specific WishGoal by +1 practice.
    // - Otherwise, increment general (non-focus) active WishGoals for this member by +stars.
    final updatedGoalsToSync = <WishGoal>[];
    final isFocusPractice = completedReq.routineId.startsWith('focus_goal_');
    final targetGoalId = isFocusPractice
        ? completedReq.routineId.substring('focus_goal_'.length)
        : null;

    final updatedGoals = state.wishGoals.map((g) {
      if (isFocusPractice) {
        if (g.id == targetGoalId && g.status == WishGoalStatus.active) {
          final nextCount = g.currentPoints + 1;
          final updated = g.copyWith(
            currentPoints: nextCount,
            status: nextCount >= g.targetPoints
                ? WishGoalStatus.achieved
                : WishGoalStatus.active,
          );
          updatedGoalsToSync.add(updated);
          return updated;
        }
        return g;
      } else {
        if (g.memberId == completedReq.memberId &&
            g.status == WishGoalStatus.active &&
            !g.hasFocusActivity) {
          final nextStars = g.currentPoints + completedReq.stars;
          final updated = g.copyWith(
            currentPoints: nextStars,
            status: nextStars >= g.targetPoints
                ? WishGoalStatus.achieved
                : WishGoalStatus.active,
          );
          updatedGoalsToSync.add(updated);
          return updated;
        }
        return g;
      }
    }).toList();

    state = state.copyWith(
      family: updatedFamily,
      members: newMembers,
      wishGoals: updatedGoals,
      ledger: [entry, ...state.ledger],
      routineRequests: updatedReqs,
    );

    _syncRoutineRequestToFirestore(completedReq);
    _syncLedgerToFirestoreIfAvailable(entry);
    _syncFamilyToFirestore(updatedFamily);
    if (updatedEarner != null) {
      _syncMemberToFirestore(updatedEarner!);
    }
    for (final g in updatedGoalsToSync) {
      _syncWishGoalToFirestore(g);
    }
  }

  Future<void> _syncRoutineRequestToFirestore(RoutineApprovalRequest req) async {
    if (!_canSyncToFirestore) return;
    try {
      await FirebaseFirestore.instance
          .collection('families')
          .doc(state.family.id)
          .collection('routine_requests')
          .doc(req.id)
          .set({
        'id': req.id,
        'memberId': req.memberId,
        'memberName': req.memberName,
        'memberAvatar': req.memberAvatar,
        'routineId': req.routineId,
        'routineTitleMs': req.routineTitleMs,
        'routineTitleEn': req.routineTitleEn,
        'timeLabel': req.timeLabel,
        'stars': req.stars,
        'status': req.status.name,
        'approvedByName': req.approvedByName,
        'requestedAt': Timestamp.fromDate(req.requestedAt),
        'approvedAt':
            req.approvedAt != null ? Timestamp.fromDate(req.approvedAt!) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Offline or rules pending; local state remains intact.
    }
  }

  /// Award points and stars for a shared family/dining table challenge to multiple participating members
  void awardFamilyChallengeParticipation({
    required String challengeTitle,
    required List<String> participatingMemberIds,
    required int pointsPerMember,
    required int familyStars,
  }) {
    if (participatingMemberIds.isEmpty) return;

    final updatedMembers = state.members.map((m) {
      if (!participatingMemberIds.contains(m.id)) return m;
      final addedPoints = m.isParentOrGuardian ? 0 : pointsPerMember;
      final addedStars = familyStars;
      final updatedMilestones = {...m.milestones, 'Team Spirit'};
      final updatedM = m.copyWith(
        points: m.points + addedPoints,
        stars: m.stars + addedStars,
        streakDays: m.streakDays + 1,
        milestones: updatedMilestones.toList(),
      );
      _syncMemberToFirestore(updatedM);
      return updatedM;
    }).toList();

    // Update active general wish goals for participating members (skip focus-activity goals)
    final updatedGoals = state.wishGoals.map((g) {
      if (participatingMemberIds.contains(g.memberId) &&
          g.status == WishGoalStatus.active &&
          !g.hasFocusActivity) {
        final newPts = g.currentPoints + familyStars;
        final updated = g.copyWith(
          currentPoints: newPts,
          status: newPts >= g.targetPoints
              ? WishGoalStatus.achieved
              : WishGoalStatus.active,
        );
        _syncWishGoalToFirestore(updated);
        return updated;
      }
      return g;
    }).toList();

    // Update family total star pool
    final updatedFamily = state.family.copyWith(
      familyGoalCurrentStars: state.family.familyGoalCurrentStars + familyStars,
    );

    // Append ledger entry for each participating member
    final newLedgers = participatingMemberIds.map((memId) {
      final m = state.members.firstWhere((x) => x.id == memId);
      final entry = LedgerEntry(
        id: 'led_${DateTime.now().millisecondsSinceEpoch}_${m.id}',
        memberId: m.id,
        memberName: m.name,
        memberAvatar: m.avatarEmoji,
        reasonMs: challengeTitle,
        reasonEn: challengeTitle,
        pointsEarned: m.isParentOrGuardian ? 0 : pointsPerMember,
        starsEarned: familyStars,
        timestamp: DateTime.now(),
      );
      _syncLedgerToFirestoreIfAvailable(entry);
      return entry;
    }).toList();

    state = state.copyWith(
      family: updatedFamily,
      members: updatedMembers,
      wishGoals: updatedGoals,
      ledger: [...newLedgers, ...state.ledger],
    );
  }

  /// Add a new shared Family Reward Goal (with target stars & optional reward image)
  void addFamilyRewardGoal({
    required String title,
    required int targetStars,
    String? imagePath,
    bool makeActive = true,
  }) {
    final clean = title.trim();
    if (clean.isEmpty || targetStars <= 0) return;

    final newGoal = FamilyRewardGoal(
      id: 'fgoal_${DateTime.now().millisecondsSinceEpoch}',
      titleMs: clean,
      titleEn: clean,
      targetStars: targetStars,
      currentStars: 0,
      imagePath: imagePath,
      status: FamilyGoalStatus.active,
      createdAt: DateTime.now(),
    );

    final updatedGoals = makeActive
        ? [newGoal, ...state.familyGoals]
        : [...state.familyGoals, newGoal];

    final updatedFamily = makeActive
        ? state.family.copyWith(
            familyGoalTitleMs: newGoal.titleMs,
            familyGoalTitleEn: newGoal.titleEn,
            familyGoalTargetStars: newGoal.targetStars,
            familyGoalCurrentStars: newGoal.currentStars,
          )
        : state.family;

    state = state.copyWith(
      familyGoals: updatedGoals,
      family: updatedFamily,
    );
    _saveFamilyCacheLocally(updatedFamily);
    _syncFamilyToFirestore(updatedFamily);
  }

  /// Claim a reached Family Reward Goal (verified by Parent PIN) & switch primary goal to next active quest
  void claimFamilyRewardGoal(String goalId) {
    final idx = state.familyGoals.indexWhere((g) => g.id == goalId);
    if (idx == -1) return;
    final target = state.familyGoals[idx];
    if (target.status == FamilyGoalStatus.claimed) return;

    final updatedGoals = state.familyGoals.map((g) {
      if (g.id != goalId) return g;
      return g.copyWith(
        status: FamilyGoalStatus.claimed,
        claimedAt: DateTime.now(),
      );
    }).toList();

    final nextActive = updatedGoals
        .where((g) => g.status == FamilyGoalStatus.active)
        .cast<FamilyRewardGoal?>()
        .firstWhere((_) => true, orElse: () => null);

    final updatedFamily = nextActive != null
        ? state.family.copyWith(
            familyGoalTitleMs: nextActive.titleMs,
            familyGoalTitleEn: nextActive.titleEn,
            familyGoalTargetStars: nextActive.targetStars,
            familyGoalCurrentStars: nextActive.currentStars,
          )
        : state.family.copyWith(familyGoalCurrentStars: 0);

    state = state.copyWith(
      familyGoals: updatedGoals,
      family: updatedFamily,
    );
    _saveFamilyCacheLocally(updatedFamily);
    _syncFamilyToFirestore(updatedFamily);
  }

  /// Helper: add earned family stars to the primary active FamilyRewardGoal (auto-flips to readyToClaim when reached)
  List<FamilyRewardGoal> _applyStarsToActiveFamilyGoal(int addedStars) {
    if (addedStars <= 0 || state.familyGoals.isEmpty) return state.familyGoals;
    final activeIdx = state.familyGoals.indexWhere(
      (g) => g.status == FamilyGoalStatus.active,
    );
    if (activeIdx == -1) return state.familyGoals;

    final current = state.familyGoals[activeIdx];
    final nextStars = current.currentStars + addedStars;
    final reached = nextStars >= current.targetStars;
    final updated = current.copyWith(
      currentStars: reached ? current.targetStars : nextStars,
      status: reached ? FamilyGoalStatus.readyToClaim : FamilyGoalStatus.active,
    );
    final nextList = [...state.familyGoals];
    nextList[activeIdx] = updated;
    return nextList;
  }

  /// Step 1: Request verification from another family member before stars & points are awarded
  void requestActivityVerification({
    required String activityId,
    required String memberId,
  }) {
    final actIdx = state.activities.indexWhere((a) => a.id == activityId);
    if (actIdx == -1) return;
    final activity = state.activities[actIdx];
    if (activity.completedByMemberIds.contains(memberId) ||
        activity.pendingVerificationMemberIds.contains(memberId)) {
      return;
    }

    final updatedActivity = activity.copyWith(
      pendingVerificationMemberIds: [
        ...activity.pendingVerificationMemberIds,
        memberId,
      ],
    );
    final updatedActivities = [...state.activities];
    updatedActivities[actIdx] = updatedActivity;
    state = state.copyWith(activities: updatedActivities);
  }

  /// Step 2: Another family member verifies the pending request -> awards stars & points
  void approveActivityVerification({
    required String activityId,
    required String memberId,
    required String verifiedByMemberId,
  }) {
    if (memberId == verifiedByMemberId) return; // Cannot self-verify
    completeFamilyTaskForMember(
      activityId: activityId,
      memberId: memberId,
    );
  }

  /// Complete a family task/activity by a specific member chosen from the "Who done it?" modal
  void completeFamilyTaskForMember({
    required String activityId,
    required String memberId,
  }) {
    final actIdx = state.activities.indexWhere((a) => a.id == activityId);
    if (actIdx == -1) return;
    final activity = state.activities[actIdx];
    final member = state.members.firstWhere(
      (m) => m.id == memberId,
      orElse: () => state.members.first,
    );

    // If member already completed this activity, don't double award
    if (activity.completedByMemberIds.contains(memberId)) return;

    final updatedAct = activity.copyWith(
      completedByMemberIds: [...activity.completedByMemberIds, memberId],
      pendingVerificationMemberIds: activity.pendingVerificationMemberIds
          .where((id) => id != memberId)
          .toList(),
    );
    final newActivities = [...state.activities];
    newActivities[actIdx] = updatedAct;

    // Update member's points and stars
    final updatedMembers = state.members.map((m) {
      if (m.id != memberId) return m;
      final addedPoints = m.isParentOrGuardian ? 0 : activity.points;
      final addedStars = activity.stars;
      final updatedMilestones = {...m.milestones};
      if (m.stars + addedStars >= 10) updatedMilestones.add('10 Good Habits');
      final updatedM = m.copyWith(
        points: m.points + addedPoints,
        stars: m.stars + addedStars,
        streakDays: m.streakDays + 1,
        milestones: updatedMilestones.toList(),
      );
      _syncMemberToFirestore(updatedM);
      return updatedM;
    }).toList();

    // Update general wish goals for this member (skip focus-activity goals)
    final updatedGoals = state.wishGoals.map((g) {
      if (g.memberId == memberId &&
          g.status == WishGoalStatus.active &&
          !g.hasFocusActivity) {
        final newPts = g.currentPoints + activity.stars;
        final updated = g.copyWith(
          currentPoints: newPts,
          status: newPts >= g.targetPoints
              ? WishGoalStatus.achieved
              : WishGoalStatus.active,
        );
        _syncWishGoalToFirestore(updated);
        return updated;
      }
      return g;
    }).toList();

    // Update family total stars & active FamilyRewardGoal
    final updatedFamilyGoals = _applyStarsToActiveFamilyGoal(activity.stars);
    final updatedFamily = state.family.copyWith(
      familyGoalCurrentStars:
          state.family.familyGoalCurrentStars + activity.stars,
    );

    // Append ledger
    final entry = LedgerEntry(
      id: 'led_${DateTime.now().millisecondsSinceEpoch}',
      memberId: member.id,
      memberName: member.name,
      memberAvatar: member.avatarEmoji,
      reasonMs: activity.titleMs,
      reasonEn: activity.titleEn,
      pointsEarned: member.isParentOrGuardian ? 0 : activity.points,
      starsEarned: activity.stars,
      timestamp: DateTime.now(),
    );
    _syncLedgerToFirestoreIfAvailable(entry);

    state = state.copyWith(
      family: updatedFamily,
      members: updatedMembers,
      activities: newActivities,
      wishGoals: updatedGoals,
      familyGoals: updatedFamilyGoals,
      ledger: [entry, ...state.ledger],
    );
  }

  /// Add a new Bonding Activity or Habit (FR-10) and sync to Cloud Firestore
  void addActivity({
    required String titleMs,
    required String titleEn,
    required String descMs,
    required String descEn,
    required String iconEmoji,
    String? customImagePath,
    required ActivityCategory category,
    ParticipationMode participationMode = ParticipationMode.anyone,
    required int durationMinutes,
    required int points,
    required int stars,
    required bool requiresParentVerification,
    List<String> pendingVerificationMemberIds = const [],
    DateTime? scheduledDate,
  }) {
    final newAct = BondingActivity(
      id: 'act_${DateTime.now().millisecondsSinceEpoch}',
      titleMs: titleMs,
      titleEn: titleEn.isEmpty ? titleMs : titleEn,
      descMs: descMs,
      descEn: descEn.isEmpty ? descMs : descEn,
      iconEmoji: iconEmoji,
      customImagePath: customImagePath,
      category: category,
      participationMode: participationMode,
      durationMinutes: durationMinutes,
      points: points,
      stars: stars,
      requiresParentVerification: requiresParentVerification,
      pendingVerificationMemberIds: pendingVerificationMemberIds,
      scheduledDate: scheduledDate,
    );
    state = state.copyWith(activities: [newAct, ...state.activities]);
    _syncActivityToFirestore(newAct);
  }

  Future<void> _syncActivityToFirestore(BondingActivity act) async {
    if (!_canSyncToFirestore) return;
    try {
      await FirebaseFirestore.instance
          .collection('families')
          .doc(state.family.id)
          .collection('activities')
          .doc(act.id)
          .set({
        'id': act.id,
        'titleMs': act.titleMs,
        'titleEn': act.titleEn,
        'descMs': act.descMs,
        'descEn': act.descEn,
        'iconEmoji': act.iconEmoji,
        'customImagePath': act.customImagePath,
        'category': act.category.name,
        'participationMode': act.participationMode.name,
        'durationMinutes': act.durationMinutes,
        'points': act.points,
        'stars': act.stars,
        'minAge': act.minAge,
        'maxAge': act.maxAge,
        'requiresParentVerification': act.requiresParentVerification,
        'completedByMemberIds': act.completedByMemberIds,
        'pendingVerificationMemberIds': act.pendingVerificationMemberIds,
        'isPrivateNote': act.isPrivateNote,
        'scheduledDate': act.scheduledDate != null
            ? Timestamp.fromDate(act.scheduledDate!)
            : null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Offline or local fallback
    }
  }

  /// Add a new Family Member (Child without email, Teen, Adult, or Co-Parent/Guardian - FR-03)
  void addFamilyMember({
    required String name,
    required String avatarEmoji,
    String? customPhotoPath,
    String? tagline,
    required MemberRole role,
    required int birthMonth,
    required int birthYear,
    String? pin,
  }) {
    final newMember = FamilyMember(
      id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
      familyId: state.family.id,
      name: name,
      avatarEmoji: avatarEmoji,
      customPhotoPath: (customPhotoPath != null && customPhotoPath.trim().isNotEmpty)
          ? customPhotoPath.trim()
          : null,
      tagline: (tagline != null && tagline.trim().isNotEmpty)
          ? tagline.trim()
          : null,
      role: role,
      birthMonth: birthMonth,
      birthYear: birthYear,
      pin: (pin != null && pin.trim().isNotEmpty) ? pin.trim() : null,
      milestones: (role == MemberRole.owner ||
              role == MemberRole.coparent ||
              role == MemberRole.caregiver)
          ? const []
          : const ['First Week'],
    );
    state = state.copyWith(members: [...state.members, newMember]);
    _syncMemberToFirestore(newMember);
  }

  /// Update Teen/Adult Privacy Level or Interaction Mode (FR-42)
  void updateMemberPrivacy(String memberId, PrivacyLevel level) {
    final updated = state.members.map((m) {
      if (m.id != memberId) return m;
      final updatedM = m.copyWith(privacyLevel: level);
      _syncMemberToFirestore(updatedM);
      return updatedM;
    }).toList();
    state = state.copyWith(members: updated);
  }

  /// Update Member Profile Photo (Custom Image)
  void updateMemberPhoto(String memberId, String photoPath) {
    final updated = state.members.map((m) {
      if (m.id != memberId) return m;
      final updatedM = m.copyWith(customPhotoPath: photoPath);
      _syncMemberToFirestore(updatedM);
      return updatedM;
    }).toList();
    state = state.copyWith(members: updated);
  }

  /// Update Member Profile details (avatar, custom photo, name, DOB, tagline)
  void updateMemberProfile({
    required String memberId,
    String? name,
    String? avatarEmoji,
    String? customPhotoPath,
    bool clearCustomPhoto = false,
    int? birthMonth,
    int? birthYear,
    String? tagline,
    bool clearTagline = false,
  }) {
    final updated = state.members.map((m) {
      if (m.id != memberId) return m;
      final updatedM = m.copyWith(
        name: name,
        avatarEmoji: avatarEmoji,
        customPhotoPath: customPhotoPath,
        clearCustomPhoto: clearCustomPhoto,
        birthMonth: birthMonth,
        birthYear: birthYear,
        tagline: tagline,
        clearTagline: clearTagline,
      );
      _syncMemberToFirestore(updatedM);
      return updatedM;
    }).toList();
    state = state.copyWith(members: updated);
  }

  /// Set, update, or clear a member's 4-digit PIN
  void updateMemberPin({
    required String memberId,
    required String? newPin,
  }) {
    final updated = state.members.map((m) {
      if (m.id != memberId) return m;
      final updatedM = m.copyWith(
        pin: newPin,
        clearPin: newPin == null || newPin.isEmpty,
      );
      _syncMemberToFirestore(updatedM);
      return updatedM;
    }).toList();
    state = state.copyWith(members: updated);
  }

  /// Create a new Wish Goal with optional custom picture & optional Focus Activity (FR-30)
  void addWishGoal({
    required String titleMs,
    required String iconEmoji,
    required int targetPoints,
    String? customImagePath,
    String? focusActivity,
    String? targetMemberId,
    WishGoalBasis basis = WishGoalBasis.weekly,
  }) {
    final creator = state.activeMember;
    final ownerMember = targetMemberId != null
        ? state.members.firstWhere(
            (m) => m.id == targetMemberId,
            orElse: () => creator,
          )
        : creator;
    final cleanedFocus = focusActivity?.trim();
    final goal = WishGoal(
      id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
      memberId: ownerMember.id,
      memberName: ownerMember.name,
      titleMs: titleMs,
      titleEn: titleMs,
      iconEmoji: iconEmoji,
      customImagePath: customImagePath,
      focusActivity:
          (cleanedFocus != null && cleanedFocus.isNotEmpty) ? cleanedFocus : null,
      targetPoints: targetPoints,
      currentPoints: 0,
      status: creator.isParentOrGuardian
          ? WishGoalStatus.active
          : WishGoalStatus.pendingApproval,
      approvedByName: creator.isParentOrGuardian ? creator.name : null,
      basis: basis,
    );
    state = state.copyWith(wishGoals: [goal, ...state.wishGoals]);
    _syncWishGoalToFirestore(goal);
  }

  /// Child submits +1 practice for a Focus Activity Wish Goal (goes to Parent's Pending Approvals).
  void submitFocusGoalPractice({required String goalId}) {
    final idx = state.wishGoals.indexWhere((g) => g.id == goalId);
    if (idx == -1) return;
    final goal = state.wishGoals[idx];
    if (!goal.hasFocusActivity) return;

    final child = state.members.firstWhere(
      (m) => m.id == goal.memberId,
      orElse: () => state.activeMember,
    );
    final nextNum = (goal.currentPoints + 1).clamp(1, goal.targetPoints);
    final req = RoutineApprovalRequest(
      id: 'req_focus_${goal.id}_${DateTime.now().millisecondsSinceEpoch}',
      memberId: child.id,
      memberName: child.name,
      memberAvatar: child.avatarEmoji,
      routineId: 'focus_goal_${goal.id}',
      routineTitleMs:
          '${goal.focusActivity!} (Latihan $nextNum/${goal.targetPoints})',
      routineTitleEn:
          '${goal.focusActivity!} (Practice $nextNum/${goal.targetPoints})',
      timeLabel: 'Milestone Focus',
      stars: 1,
      status: RoutineStatus.pendingApproval,
      requestedAt: DateTime.now(),
    );

    state = state.copyWith(
      routineRequests: [req, ...state.routineRequests],
    );
    _syncRoutineRequestToFirestore(req);
  }

  /// Parent directly logs & verifies +1 completed practice for a Focus Activity Wish Goal.
  void logFocusGoalPracticeByParent({required String goalId}) {
    final idx = state.wishGoals.indexWhere((g) => g.id == goalId);
    if (idx == -1) return;
    final goal = state.wishGoals[idx];
    if (!goal.hasFocusActivity || goal.currentPoints >= goal.targetPoints) return;

    final parent = state.activeMember;
    final child = state.members.firstWhere(
      (m) => m.id == goal.memberId,
      orElse: () => parent,
    );
    final nextNum = (goal.currentPoints + 1).clamp(1, goal.targetPoints);
    final completedReq = RoutineApprovalRequest(
      id: 'req_focus_${goal.id}_${DateTime.now().millisecondsSinceEpoch}',
      memberId: child.id,
      memberName: child.name,
      memberAvatar: child.avatarEmoji,
      routineId: 'focus_goal_${goal.id}',
      routineTitleMs:
          '${goal.focusActivity!} (Latihan $nextNum/${goal.targetPoints})',
      routineTitleEn:
          '${goal.focusActivity!} (Practice $nextNum/${goal.targetPoints})',
      timeLabel: 'Milestone Focus',
      stars: 1,
      status: RoutineStatus.completed,
      approvedByName: parent.name,
      requestedAt: DateTime.now(),
      approvedAt: DateTime.now(),
    );
    _completeRoutineAndAwardStars(completedReq);
  }

  /// Redeem an achieved WishGoal and sync to Cloud Firestore (/families/{familyId}/wish_goals)
  void redeemWishGoal(String goalId) {
    WishGoal? redeemed;
    final updated = state.wishGoals.map((g) {
      if (g.id != goalId) return g;
      redeemed = g.copyWith(status: WishGoalStatus.achieved);
      return redeemed!;
    }).toList();
    state = state.copyWith(wishGoals: updated);
    if (redeemed != null) {
      _syncWishGoalToFirestore(redeemed!);
    }
  }

  /// Parent approves a child's Wish Goal (FR-30)
  void approveWishGoal(String goalId) {
    final parent = state.activeMember;
    WishGoal? approved;
    final updated = state.wishGoals.map((g) {
      if (g.id != goalId) return g;
      approved = g.copyWith(
        status: g.currentPoints >= g.targetPoints
            ? WishGoalStatus.achieved
            : WishGoalStatus.active,
        approvedByName: parent.name,
      );
      return approved!;
    }).toList();
    state = state.copyWith(wishGoals: updated);
    if (approved != null) _syncWishGoalToFirestore(approved!);
  }

  /// Parent declines a child's suggested Wish Goal
  void declineWishGoal(String goalId) {
    state = state.copyWith(
      wishGoals: state.wishGoals.where((g) => g.id != goalId).toList(),
    );
    if (isFirebaseReady && Firebase.apps.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('families')
          .doc(state.family.id)
          .collection('wish_goals')
          .doc(goalId)
          .delete()
          .catchError((_) {});
    }
  }

  /// Regenerate 48-hour one-time invite code (FR-05)
  void regenerateInviteCode() {
    final rand = 1000 + Random().nextInt(8999);
    state = state.copyWith(
      family: state.family.copyWith(
        inviteCode: 'ERAT-48H-$rand',
        inviteExpiresAt: DateTime.now().add(const Duration(hours: 48)),
      ),
    );
  }

  /// Send a message, voice note or sticker in Family / Parent-Child / Sibling Chat (FR-20)
  void sendMessage({
    required String channel,
    required String content,
    bool isSticker = false,
    bool isAudioVoiceNote = false,
    String? audioDuration,
    String? audioUrl,
  }) {
    if (content.trim().isEmpty) return;
    final sender = state.activeMember;
    final msg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: sender.id,
      senderName: sender.name,
      senderAvatar: sender.avatarEmoji,
      channel: channel,
      content: content.trim(),
      isSticker: isSticker,
      isAudioVoiceNote: isAudioVoiceNote,
      audioDuration: audioDuration,
      audioUrl: audioUrl,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, msg]);
    _syncMessageToFirestore(msg);
  }

  Future<void> _syncMessageToFirestore(ChatMessage msg) async {
    if (!_canSyncToFirestore) return;
    try {
      await FirebaseFirestore.instance
          .collection('families')
          .doc(state.family.id)
          .collection('messages')
          .doc(msg.id)
          .set({
        'id': msg.id,
        'senderId': msg.senderId,
        'senderName': msg.senderName,
        'senderAvatar': msg.senderAvatar,
        'channel': msg.channel,
        'content': msg.content,
        'isSticker': msg.isSticker,
        'isAudioVoiceNote': msg.isAudioVoiceNote,
        'audioDuration': msg.audioDuration,
        'audioUrl': msg.audioUrl,
        'createdAt': Timestamp.fromDate(msg.createdAt),
      });
    } catch (_) {
      // Offline fallback
    }
  }

  Future<void> _syncJournalEntryToFirestore(JournalEntry entry) async {
    if (!_canSyncToFirestore) return;
    try {
      await FirebaseFirestore.instance
          .collection('families')
          .doc(state.family.id)
          .collection('members')
          .doc(entry.memberId)
          .collection('private_journal')
          .doc(entry.id)
          .set({
        'id': entry.id,
        'memberId': entry.memberId,
        'memberName': entry.memberName,
        'moodEmoji': entry.moodEmoji,
        'title': entry.title,
        'content': entry.content,
        'isVoiceEntry': entry.isVoiceEntry,
        'voiceDuration': entry.voiceDuration,
        'audioUrl': entry.audioUrl,
        'isSharedWithParents': entry.isSharedWithParents,
        'createdAt': Timestamp.fromDate(entry.createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Offline fallback
    }
  }

  Future<void> _deleteJournalEntryFromFirestore(
    String memberId,
    String entryId,
  ) async {
    if (!_canSyncToFirestore) return;
    try {
      await FirebaseFirestore.instance
          .collection('families')
          .doc(state.family.id)
          .collection('members')
          .doc(memberId)
          .collection('private_journal')
          .doc(entryId)
          .delete();
    } catch (_) {}
  }

  Future<void> _syncCommunityPostToFirestore(
    CommunityKnowledgePost post,
  ) async {
    if (!_canSyncToFirestore) return;
    try {
      await FirebaseFirestore.instance
          .collection('parent_community_posts')
          .doc(post.id)
          .set({
        'id': post.id,
        'authorId': post.authorId,
        'authorName': post.authorName,
        'authorRole': post.authorRole,
        'authorAvatar': post.authorAvatar,
        'countryCode': post.countryCode,
        'countryName': post.countryName,
        'language': post.language,
        'isSharedForKids': post.isSharedForKids,
        'isInternational': post.isInternational,
        'title': post.title,
        'content': post.content,
        'tag': post.tag,
        'likes': post.likes,
        'replies': post.replies,
        'upvotedByIds': post.upvotedByIds,
        'comments': post.comments
            .map((c) => {
                  'id': c.id,
                  'authorId': c.authorId,
                  'authorName': c.authorName,
                  'authorAvatar': c.authorAvatar,
                  'content': c.content,
                  'createdAt': c.createdAt.toIso8601String(),
                })
            .toList(),
        'createdAt': Timestamp.fromDate(post.createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Offline fallback
    }
  }

  Future<void> _deleteCommunityPostFromFirestore(String postId) async {
    if (!_canSyncToFirestore) return;
    try {
      await FirebaseFirestore.instance
          .collection('parent_community_posts')
          .doc(postId)
          .delete();
    } catch (_) {}
  }

  Future<void> _syncLedgerToFirestoreIfAvailable(LedgerEntry entry) async {
    if (!_canSyncToFirestore) return;
    try {
      await FirebaseFirestore.instance
          .collection('families')
          .doc(state.family.id)
          .collection('ledger')
          .doc(entry.id)
          .set({
        'memberId': entry.memberId,
        'memberName': entry.memberName,
        'reasonMs': entry.reasonMs,
        'reasonEn': entry.reasonEn,
        'pointsEarned': entry.pointsEarned,
        'starsEarned': entry.starsEarned,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Offline or rules pending; local state remains intact.
    }
  }

  Future<void> _syncMemberToFirestore(FamilyMember member) async {
    if (!_canSyncToFirestore) return;
    try {
      await FirebaseFirestore.instance
          .collection('families')
          .doc(state.family.id)
          .collection('members')
          .doc(member.id)
          .set({
        'id': member.id,
        'familyId': state.family.id,
        'name': member.name,
        'avatarEmoji': member.avatarEmoji,
        'role': member.role.name,
        'birthMonth': member.birthMonth,
        'birthYear': member.birthYear,
        'pin': member.pin,
        'points': member.points,
        'stars': member.stars,
        'streakDays': member.streakDays,
        'customPhotoPath': member.customPhotoPath,
        'tagline': member.tagline,
        'privacyLevel': member.privacyLevel.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Offline or local fallback
    }
  }

  Future<void> _syncWishGoalToFirestore(WishGoal goal) async {
    if (!_canSyncToFirestore) return;
    try {
      await FirebaseFirestore.instance
          .collection('families')
          .doc(state.family.id)
          .collection('wish_goals')
          .doc(goal.id)
          .set({
        'id': goal.id,
        'memberId': goal.memberId,
        'memberName': goal.memberName,
        'titleMs': goal.titleMs,
        'titleEn': goal.titleEn,
        'iconEmoji': goal.iconEmoji,
        'customImagePath': goal.customImagePath,
        'focusActivity': goal.focusActivity,
        'targetPoints': goal.targetPoints,
        'currentPoints': goal.currentPoints,
        'status': goal.status.name,
        'approvedByName': goal.approvedByName,
        'basis': goal.basis.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Offline or local fallback
    }
  }

  /// Add a shared Family Calendar Event and sync to Cloud Firestore (/families/{familyId}/calendar_events)
  void addCalendarEvent({
    required String title,
    String? description,
    String emoji = '🎉',
    required DateTime eventDate,
    String? timeLabel,
    List<String> participantIds = const [],
  }) {
    final creator = state.activeMember;
    final event = FamilyCalendarEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      emoji: emoji,
      eventDate: eventDate,
      timeLabel: timeLabel,
      createdById: creator.id,
      createdByName: creator.name,
      participantIds: participantIds,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      calendarEvents: [event, ...state.calendarEvents],
    );
    _syncCalendarEventToFirestore(event);
  }

  /// Delete a Family Calendar Event locally and in Cloud Firestore
  void deleteCalendarEvent(String eventId) {
    state = state.copyWith(
      calendarEvents:
          state.calendarEvents.where((e) => e.id != eventId).toList(),
    );
    if (!_canSyncToFirestore) return;
    FirebaseFirestore.instance
        .collection('families')
        .doc(state.family.id)
        .collection('calendar_events')
        .doc(eventId)
        .delete()
        .catchError((_) {});
  }

  Future<void> _syncCalendarEventToFirestore(FamilyCalendarEvent event) async {
    if (!_canSyncToFirestore) return;
    try {
      await FirebaseFirestore.instance
          .collection('families')
          .doc(state.family.id)
          .collection('calendar_events')
          .doc(event.id)
          .set({
        'id': event.id,
        'title': event.title,
        'description': event.description,
        'emoji': event.emoji,
        'eventDate': Timestamp.fromDate(event.eventDate),
        'timeLabel': event.timeLabel,
        'createdById': event.createdById,
        'createdByName': event.createdByName,
        'participantIds': event.participantIds,
        'createdAt': Timestamp.fromDate(event.createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Offline or local fallback
    }
  }
}

final eratControllerProvider =
    StateNotifierProvider<EratController, EratAppState>((ref) {
  final isConnected = ref.watch(firebaseConnectedProvider);
  return EratController(isFirebaseReady: isConnected);
});

