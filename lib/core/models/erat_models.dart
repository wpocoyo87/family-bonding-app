import 'package:flutter/material.dart';

/// 5 Age Bands from ERAT Blueprint (Section 1.3)
enum AgeBand {
  littleExplorer, // 1–4 yrs (Guided)
  happyHabitBuilder, // 5–9 yrs (Guided / Co-play)
  goalAchiever, // 10–12 yrs (Co-play / Independent)
  myLifeMyGoals, // 13–17 yrs (Independent)
  lifelongFamilyBond, // 18+ yrs (Mutual)
}

enum InteractionMode {
  guided,
  coPlay,
  independent,
  mutual,
  familyHub,
}

enum MemberRole {
  owner,
  coparent,
  caregiver,
  adult,
  teen,
  child,
}

enum PrivacyLevel {
  privateSpace,
  family,
  selected,
}

enum ActivityCategory {
  bonding10Min, // Idea 10-minit bersama keluarga
  goodHabit, // Rutin & tabiat baik harian/mingguan
  familyChallenge, // Parent / Family Kindness Challenge
}

/// Defines whether an activity requires every eligible member or just 1+ helper.
enum ParticipationMode {
  everyone, // All eligible members should complete it (e.g. brush teeth, make bed)
  anyone, // 1 representative or multiple helpers together (e.g. take out trash, dishes)
}

extension AgeBandDisplay on AgeBand {
  String get shortTitle {
    switch (this) {
      case AgeBand.littleExplorer:
        return 'Simple & Visual';
      case AgeBand.happyHabitBuilder:
        return 'Fun & Playful';
      case AgeBand.goalAchiever:
        return 'Goals & Challenges';
      case AgeBand.myLifeMyGoals:
        return 'Mature & Minimal';
      case AgeBand.lifelongFamilyBond:
        return 'Family Bond';
    }
  }

  String label(bool isMs) {
    switch (this) {
      case AgeBand.littleExplorer:
        return isMs ? 'Little Explorer (1–4 thn)' : 'Little Explorer (1–4 yrs)';
      case AgeBand.happyHabitBuilder:
        return isMs
            ? 'Happy Habit Builder (5–9 thn)'
            : 'Happy Habit Builder (5–9 yrs)';
      case AgeBand.goalAchiever:
        return isMs
            ? 'Goal Achiever (10–12 thn)'
            : 'Goal Achiever (10–12 yrs)';
      case AgeBand.myLifeMyGoals:
        return isMs
            ? 'My Life, My Goals (13–17 thn)'
            : 'My Life, My Goals (13–17 yrs)';
      case AgeBand.lifelongFamilyBond:
        return isMs
            ? 'Lifelong Family Bond (18+ thn)'
            : 'Lifelong Family Bond (18+ yrs)';
    }
  }

  String description(bool isMs) {
    switch (this) {
      case AgeBand.littleExplorer:
        return isMs
            ? 'Mod Guided: Gambar besar, satu langkah mudah, dipandu ibu bapa.'
            : 'Guided Mode: Big visuals, single step, guided by parents.';
      case AgeBand.happyHabitBuilder:
        return isMs
            ? 'Mod Co-play: Stiker ceria, bintang & misi ringkas bersama.'
            : 'Co-play Mode: Fun stickers, stars & simple missions together.';
      case AgeBand.goalAchiever:
        return isMs
            ? 'Mod Co-play / Independent: Cabaran, Wish Goal & cadangan sendiri.'
            : 'Co-play / Independent: Challenges, Wish Goals & own ideas.';
      case AgeBand.myLifeMyGoals:
        return isMs
            ? 'Mod Independent: Ruang peribadi remaja & kawalan perkongsian.'
            : 'Independent Mode: Personal space & privacy sharing controls.';
      case AgeBand.lifelongFamilyBond:
        return isMs
            ? 'Mod Mutual: Hubungan dua hala, kenangan & sokongan keluarga.'
            : 'Mutual Mode: Two-way connection, memories & family support.';
    }
  }

  Color get primaryColor {
    switch (this) {
      case AgeBand.littleExplorer:
        return const Color(0xFFE67E22); // Warm sunny orange
      case AgeBand.happyHabitBuilder:
        return const Color(0xFF00897B); // Playful teal
      case AgeBand.goalAchiever:
        return const Color(0xFF5E35B1); // Vibrant violet
      case AgeBand.myLifeMyGoals:
        return const Color(0xFF1E88E5); // Sleek ocean blue
      case AgeBand.lifelongFamilyBond:
        return const Color(0xFF2E7D32); // Deep forest green
    }
  }

  Color get surfaceTint {
    switch (this) {
      case AgeBand.littleExplorer:
        return const Color(0xFFFFF3E0);
      case AgeBand.happyHabitBuilder:
        return const Color(0xFFE0F2F1);
      case AgeBand.goalAchiever:
        return const Color(0xFFEDE7F6);
      case AgeBand.myLifeMyGoals:
        return const Color(0xFFE3F2FD);
      case AgeBand.lifelongFamilyBond:
        return const Color(0xFFE8F5E9);
    }
  }

  InteractionMode get defaultMode {
    switch (this) {
      case AgeBand.littleExplorer:
        return InteractionMode.guided;
      case AgeBand.happyHabitBuilder:
        return InteractionMode.coPlay;
      case AgeBand.goalAchiever:
        return InteractionMode.coPlay;
      case AgeBand.myLifeMyGoals:
        return InteractionMode.independent;
      case AgeBand.lifelongFamilyBond:
        return InteractionMode.mutual;
    }
  }
}

class FamilyMember {
  final String id;
  final String familyId; // Links member strictly to their registered family space
  final String name;
  final String avatarEmoji;
  final String? customPhotoPath; // Custom photo/picture for user profile
  final String? tagline; // Personal short quote / title (e.g. "Little Explorer")
  final MemberRole role;
  final int birthMonth;
  final int birthYear;
  final String? pin; // Required for Parent settings & 9+ profile lock (FR-04)
  final PrivacyLevel privacyLevel;
  final InteractionMode? customMode;
  final int points;
  final int stars;
  final int streakDays;
  final List<String> milestones;

  const FamilyMember({
    required this.id,
    this.familyId = 'fam_erat_01',
    required this.name,
    required this.avatarEmoji,
    this.customPhotoPath,
    this.tagline,
    required this.role,
    required this.birthMonth,
    required this.birthYear,
    this.pin,
    this.privacyLevel = PrivacyLevel.family,
    this.customMode,
    this.points = 0,
    this.stars = 0,
    this.streakDays = 1,
    this.milestones = const [],
  });

  /// Compute exact age in years from birthMonth and birthYear (FR-03)
  int get ageYears {
    final now = DateTime.now();
    int age = now.year - birthYear;
    if (now.month < birthMonth) {
      age--;
    }
    return age < 1 ? 1 : age;
  }

  AgeBand get ageBand {
    final age = ageYears;
    if (age <= 4) return AgeBand.littleExplorer;
    if (age <= 9) return AgeBand.happyHabitBuilder;
    if (age <= 12) return AgeBand.goalAchiever;
    if (age <= 17) return AgeBand.myLifeMyGoals;
    return AgeBand.lifelongFamilyBond;
  }

  String get ageBandTitle => ageBand.label(true);

  InteractionMode get effectiveMode => customMode ?? ageBand.defaultMode;

  bool get isParentOrGuardian =>
      role == MemberRole.owner ||
      role == MemberRole.coparent ||
      role == MemberRole.caregiver;

  bool get requiresPin => isParentOrGuardian || ageYears >= 9;

  FamilyMember copyWith({
    String? familyId,
    String? name,
    String? avatarEmoji,
    String? customPhotoPath,
    bool clearCustomPhoto = false,
    String? tagline,
    bool clearTagline = false,
    MemberRole? role,
    int? birthMonth,
    int? birthYear,
    String? pin,
    bool clearPin = false,
    PrivacyLevel? privacyLevel,
    InteractionMode? customMode,
    int? points,
    int? stars,
    int? streakDays,
    List<String>? milestones,
  }) {
    return FamilyMember(
      id: id,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      customPhotoPath:
          clearCustomPhoto ? null : (customPhotoPath ?? this.customPhotoPath),
      tagline: clearTagline ? null : (tagline ?? this.tagline),
      role: role ?? this.role,
      birthMonth: birthMonth ?? this.birthMonth,
      birthYear: birthYear ?? this.birthYear,
      pin: clearPin ? null : (pin ?? this.pin),
      privacyLevel: privacyLevel ?? this.privacyLevel,
      customMode: customMode ?? this.customMode,
      points: points ?? this.points,
      stars: stars ?? this.stars,
      streakDays: streakDays ?? this.streakDays,
      milestones: milestones ?? this.milestones,
    );
  }
}

class BondingActivity {
  final String id;
  final String titleMs;
  final String titleEn;
  final String descMs;
  final String descEn;
  final String iconEmoji;
  final String? customImagePath;
  final ActivityCategory category;
  final ParticipationMode participationMode;
  final int durationMinutes;
  final int points;
  final int stars;
  final int minAge;
  final int maxAge;
  final bool requiresParentVerification;
  final List<String> completedByMemberIds;
  final List<String> pendingVerificationMemberIds;
  final bool isPrivateNote;
  /// Null means recurring Every Day; non-null means scheduled for a specific date.
  final DateTime? scheduledDate;

  const BondingActivity({
    required this.id,
    required this.titleMs,
    required this.titleEn,
    required this.descMs,
    required this.descEn,
    required this.iconEmoji,
    this.customImagePath,
    required this.category,
    this.participationMode = ParticipationMode.anyone,
    this.durationMinutes = 10,
    this.points = 10,
    this.stars = 1,
    this.minAge = 1,
    this.maxAge = 99,
    this.requiresParentVerification = false,
    this.completedByMemberIds = const [],
    this.pendingVerificationMemberIds = const [],
    this.isPrivateNote = false,
    this.scheduledDate,
  });

  bool appliesToDate(DateTime date) {
    if (scheduledDate == null) return true;
    return scheduledDate!.year == date.year &&
        scheduledDate!.month == date.month &&
        scheduledDate!.day == date.day;
  }

  String title(bool isMs) => isMs ? titleMs : titleEn;
  String description(bool isMs) => isMs ? descMs : descEn;

  /// Target members expected to complete an `everyone` activity (non-guardians in age range).
  List<FamilyMember> targetMembers(List<FamilyMember> allMembers) {
    final eligible = allMembers
        .where((m) =>
            !m.isParentOrGuardian &&
            m.ageYears >= minAge &&
            m.ageYears <= maxAge)
        .toList();
    return eligible.isEmpty ? allMembers : eligible;
  }

  /// True when the activity is considered completed according to [participationMode].
  bool isFullyCompleted(List<FamilyMember> allMembers) {
    if (participationMode == ParticipationMode.anyone) {
      return completedByMemberIds.isNotEmpty;
    }
    final targets = targetMembers(allMembers);
    return targets.isNotEmpty &&
        targets.every((m) => completedByMemberIds.contains(m.id));
  }

  BondingActivity copyWith({
    String? customImagePath,
    ParticipationMode? participationMode,
    List<String>? completedByMemberIds,
    List<String>? pendingVerificationMemberIds,
  }) {
    return BondingActivity(
      id: id,
      titleMs: titleMs,
      titleEn: titleEn,
      descMs: descMs,
      descEn: descEn,
      iconEmoji: iconEmoji,
      customImagePath: customImagePath ?? this.customImagePath,
      category: category,
      participationMode: participationMode ?? this.participationMode,
      durationMinutes: durationMinutes,
      points: points,
      stars: stars,
      minAge: minAge,
      maxAge: maxAge,
      requiresParentVerification: requiresParentVerification,
      completedByMemberIds: completedByMemberIds ?? this.completedByMemberIds,
      pendingVerificationMemberIds:
          pendingVerificationMemberIds ?? this.pendingVerificationMemberIds,
      isPrivateNote: isPrivateNote,
      scheduledDate: scheduledDate,
    );
  }
}

enum WishGoalStatus { pendingApproval, active, achieved }

enum WishGoalBasis {
  daily,
  weekly,
  monthly,
  quarterly,
  yearly;

  String get labelMs {
    switch (this) {
      case WishGoalBasis.daily:
        return 'Harian';
      case WishGoalBasis.weekly:
        return 'Mingguan';
      case WishGoalBasis.monthly:
        return 'Bulanan';
      case WishGoalBasis.quarterly:
        return 'Suku Tahun';
      case WishGoalBasis.yearly:
        return 'Tahunan';
    }
  }

  String get labelEn {
    switch (this) {
      case WishGoalBasis.daily:
        return 'Daily';
      case WishGoalBasis.weekly:
        return 'Weekly';
      case WishGoalBasis.monthly:
        return 'Monthly';
      case WishGoalBasis.quarterly:
        return 'Quarterly';
      case WishGoalBasis.yearly:
        return 'Yearly';
    }
  }

  String get emoji {
    switch (this) {
      case WishGoalBasis.daily:
        return '☀️';
      case WishGoalBasis.weekly:
        return '📅';
      case WishGoalBasis.monthly:
        return '🗓️';
      case WishGoalBasis.quarterly:
        return '🎯';
      case WishGoalBasis.yearly:
        return '🏆';
    }
  }

  String get badge => '$emoji $labelMs';
}

class WishGoal {
  final String id;
  final String memberId;
  final String memberName;
  final String titleMs;
  final String titleEn;
  final String iconEmoji;
  final String? customImagePath; // Custom photo/picture for this Wish Goal
  final String? focusActivity; // Optional focused habit/practice (e.g., "Hafal Doa Qunut")
  final int targetPoints;
  final int currentPoints;
  final WishGoalStatus status;
  final String? approvedByName;
  final WishGoalBasis basis;

  const WishGoal({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.titleMs,
    required this.titleEn,
    required this.iconEmoji,
    this.customImagePath,
    this.focusActivity,
    required this.targetPoints,
    required this.currentPoints,
    required this.status,
    this.approvedByName,
    this.basis = WishGoalBasis.weekly,
  });

  String title(bool isMs) => isMs ? titleMs : titleEn;
  bool get hasFocusActivity =>
      focusActivity != null && focusActivity!.trim().isNotEmpty;
  double get progress =>
      targetPoints <= 0 ? 1.0 : (currentPoints / targetPoints).clamp(0.0, 1.0);

  WishGoal copyWith({
    String? customImagePath,
    String? focusActivity,
    int? currentPoints,
    WishGoalStatus? status,
    String? approvedByName,
    WishGoalBasis? basis,
  }) {
    return WishGoal(
      id: id,
      memberId: memberId,
      memberName: memberName,
      titleMs: titleMs,
      titleEn: titleEn,
      iconEmoji: iconEmoji,
      customImagePath: customImagePath ?? this.customImagePath,
      focusActivity: focusActivity ?? this.focusActivity,
      targetPoints: targetPoints,
      currentPoints: currentPoints ?? this.currentPoints,
      status: status ?? this.status,
      approvedByName: approvedByName ?? this.approvedByName,
      basis: basis ?? this.basis,
    );
  }
}

class LedgerEntry {
  final String id;
  final String memberId;
  final String memberName;
  final String memberAvatar;
  final String reasonMs;
  final String reasonEn;
  final int pointsEarned;
  final int starsEarned;
  final DateTime timestamp;

  const LedgerEntry({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.memberAvatar,
    required this.reasonMs,
    required this.reasonEn,
    required this.pointsEarned,
    required this.starsEarned,
    required this.timestamp,
  });

  String reason(bool isMs) => isMs ? reasonMs : reasonEn;
}

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String channel; // 'family', 'parent_child', 'sibling'
  final String content;
  final bool isSticker;
  final bool isAudioVoiceNote;
  final String? audioDuration;
  final String? audioUrl;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.channel,
    required this.content,
    this.isSticker = false,
    this.isAudioVoiceNote = false,
    this.audioDuration,
    this.audioUrl,
    required this.createdAt,
  });
}

class FamilySpace {
  final String id;
  final String name;
  final String inviteCode;
  final DateTime inviteExpiresAt;
  final String familyGoalTitleMs;
  final String familyGoalTitleEn;
  final int familyGoalTargetStars;
  final int familyGoalCurrentStars;
  final String? photoPath;

  const FamilySpace({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.inviteExpiresAt,
    required this.familyGoalTitleMs,
    required this.familyGoalTitleEn,
    required this.familyGoalTargetStars,
    required this.familyGoalCurrentStars,
    this.photoPath,
  });

  String familyGoalTitle(bool isMs) =>
      isMs ? familyGoalTitleMs : familyGoalTitleEn;

  FamilySpace copyWith({
    String? name,
    String? inviteCode,
    DateTime? inviteExpiresAt,
    String? familyGoalTitleMs,
    String? familyGoalTitleEn,
    int? familyGoalTargetStars,
    int? familyGoalCurrentStars,
    String? photoPath,
    bool clearPhoto = false,
  }) {
    return FamilySpace(
      id: id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      inviteExpiresAt: inviteExpiresAt ?? this.inviteExpiresAt,
      familyGoalTitleMs: familyGoalTitleMs ?? this.familyGoalTitleMs,
      familyGoalTitleEn: familyGoalTitleEn ?? this.familyGoalTitleEn,
      familyGoalTargetStars:
          familyGoalTargetStars ?? this.familyGoalTargetStars,
      familyGoalCurrentStars:
          familyGoalCurrentStars ?? this.familyGoalCurrentStars,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
    );
  }
}

enum FamilyGoalStatus { active, readyToClaim, claimed }

class FamilyRewardGoal {
  final String id;
  final String titleMs;
  final String titleEn;
  final int targetStars;
  final int currentStars;
  final String? imagePath;
  final FamilyGoalStatus status;
  final DateTime createdAt;
  final DateTime? claimedAt;

  const FamilyRewardGoal({
    required this.id,
    required this.titleMs,
    required this.titleEn,
    required this.targetStars,
    required this.currentStars,
    this.imagePath,
    required this.status,
    required this.createdAt,
    this.claimedAt,
  });

  double get progress =>
      targetStars > 0 ? (currentStars / targetStars).clamp(0.0, 1.0) : 0.0;

  FamilyRewardGoal copyWith({
    String? titleMs,
    String? titleEn,
    int? targetStars,
    int? currentStars,
    String? imagePath,
    FamilyGoalStatus? status,
    DateTime? claimedAt,
  }) {
    return FamilyRewardGoal(
      id: id,
      titleMs: titleMs ?? this.titleMs,
      titleEn: titleEn ?? this.titleEn,
      targetStars: targetStars ?? this.targetStars,
      currentStars: currentStars ?? this.currentStars,
      imagePath: imagePath ?? this.imagePath,
      status: status ?? this.status,
      createdAt: createdAt,
      claimedAt: claimedAt ?? this.claimedAt,
    );
  }
}

class DiningTableNote {
  final String id;
  final String textMs;
  final String textEn;
  final String authorName;
  final bool isPublic;
  final DateTime createdAt;

  const DiningTableNote({
    required this.id,
    required this.textMs,
    required this.textEn,
    required this.authorName,
    this.isPublic = false,
    required this.createdAt,
  });
}

class JournalEntry {
  final String id;
  final String memberId;
  final String memberName;
  final String moodEmoji; // 😊, 🌟, 😴, 😢, 🚀
  final String title;
  final String content;
  final bool isVoiceEntry;
  final String? voiceDuration;
  final String? audioUrl;
  final bool isSharedWithParents;
  final DateTime createdAt;

  const JournalEntry({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.moodEmoji,
    required this.title,
    required this.content,
    this.isVoiceEntry = false,
    this.voiceDuration,
    this.audioUrl,
    this.isSharedWithParents = false,
    required this.createdAt,
  });
}

class CommunityComment {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final DateTime createdAt;

  const CommunityComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.createdAt,
  });
}

class CommunityKnowledgePost {
  final String id;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String authorAvatar;
  final String countryCode; // 'MY', 'SG', 'GLOBAL'
  final String countryName; // 'Malaysia 🇲🇾', 'Singapore 🇸🇬', 'International 🌍'
  final String language; // 'ms', 'en'
  final bool isSharedForKids; // Visible in Kids Knowledge Corner
  final bool isInternational; // True if international
  final String title;
  final String content;
  final String tag;
  final int likes;
  final int replies;
  final List<String> upvotedByIds;
  final List<CommunityComment> comments;
  final DateTime createdAt;

  const CommunityKnowledgePost({
    required this.id,
    this.authorId = '',
    required this.authorName,
    required this.authorRole,
    required this.authorAvatar,
    required this.countryCode,
    required this.countryName,
    required this.language,
    this.isSharedForKids = false,
    this.isInternational = false,
    required this.title,
    required this.content,
    required this.tag,
    this.likes = 0,
    this.replies = 0,
    this.upvotedByIds = const [],
    this.comments = const [],
    required this.createdAt,
  });

  CommunityKnowledgePost copyWith({
    int? likes,
    int? replies,
    List<String>? upvotedByIds,
    List<CommunityComment>? comments,
  }) {
    return CommunityKnowledgePost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorRole: authorRole,
      authorAvatar: authorAvatar,
      countryCode: countryCode,
      countryName: countryName,
      language: language,
      isSharedForKids: isSharedForKids,
      isInternational: isInternational,
      title: title,
      content: content,
      tag: tag,
      likes: likes ?? this.likes,
      replies: replies ?? this.replies,
      upvotedByIds: upvotedByIds ?? this.upvotedByIds,
      comments: comments ?? this.comments,
      createdAt: createdAt,
    );
  }
}

enum RoutineStatus { todo, pendingApproval, completed }

class RoutineApprovalRequest {
  final String id;
  final String memberId;
  final String memberName;
  final String memberAvatar;
  final String routineId;
  final String routineTitleMs;
  final String routineTitleEn;
  final String timeLabel;
  final int stars;
  final RoutineStatus status;
  final String? approvedByName;
  final DateTime requestedAt;
  final DateTime? approvedAt;

  const RoutineApprovalRequest({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.memberAvatar,
    required this.routineId,
    required this.routineTitleMs,
    required this.routineTitleEn,
    required this.timeLabel,
    this.stars = 2,
    required this.status,
    this.approvedByName,
    required this.requestedAt,
    this.approvedAt,
  });

  RoutineApprovalRequest copyWith({
    RoutineStatus? status,
    String? approvedByName,
    DateTime? approvedAt,
  }) {
    return RoutineApprovalRequest(
      id: id,
      memberId: memberId,
      memberName: memberName,
      memberAvatar: memberAvatar,
      routineId: routineId,
      routineTitleMs: routineTitleMs,
      routineTitleEn: routineTitleEn,
      timeLabel: timeLabel,
      stars: stars,
      status: status ?? this.status,
      approvedByName: approvedByName ?? this.approvedByName,
      requestedAt: requestedAt,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }
}

class FamilyCalendarEvent {
  final String id;
  final String title;
  final String? description;
  final String emoji;
  final DateTime eventDate;
  final String? timeLabel;
  final String createdById;
  final String createdByName;
  /// Empty list means "All Family Members".
  final List<String> participantIds;
  final DateTime createdAt;

  const FamilyCalendarEvent({
    required this.id,
    required this.title,
    this.description,
    this.emoji = '🎉',
    required this.eventDate,
    this.timeLabel,
    required this.createdById,
    required this.createdByName,
    this.participantIds = const [],
    required this.createdAt,
  });

  bool isOnDate(DateTime date) =>
      eventDate.year == date.year &&
      eventDate.month == date.month &&
      eventDate.day == date.day;
}

