import 'package:erat_app/core/models/erat_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgeBand & Chronological Age Calculation Tests', () {
    test('Calculates Little Explorer for age 3-4', () {
      final now = DateTime.now();
      final member = FamilyMember(
        id: 'child_1',
        familyId: 'fam_1',
        name: 'Adik',
        avatarEmoji: '🧸',
        role: MemberRole.child,
        birthMonth: now.month,
        birthYear: now.year - 3,
        privacyLevel: PrivacyLevel.family,
      );

      expect(member.ageYears, 3);
      expect(member.ageBand, AgeBand.littleExplorer);
    });

    test('Calculates Happy Habit Builder / Junior Adventurer for age 7', () {
      final now = DateTime.now();
      final member = FamilyMember(
        id: 'child_2',
        familyId: 'fam_1',
        name: 'Ahmad',
        avatarEmoji: '🚀',
        role: MemberRole.child,
        birthMonth: now.month,
        birthYear: now.year - 7,
        privacyLevel: PrivacyLevel.family,
      );

      expect(member.ageYears, 7);
      expect(member.ageBand, AgeBand.happyHabitBuilder);
    });

    test('Calculates Goal Achiever / Young Cadet for age 11', () {
      final now = DateTime.now();
      final member = FamilyMember(
        id: 'child_3',
        familyId: 'fam_1',
        name: 'Siti',
        avatarEmoji: '🎨',
        role: MemberRole.child,
        birthMonth: now.month,
        birthYear: now.year - 11,
        privacyLevel: PrivacyLevel.family,
      );

      expect(member.ageYears, 11);
      expect(member.ageBand, AgeBand.goalAchiever);
    });

    test('Calculates My Life My Goals / Senior Pathfinder for age 15', () {
      final now = DateTime.now();
      final member = FamilyMember(
        id: 'child_4',
        familyId: 'fam_1',
        name: 'Faiz',
        avatarEmoji: '🎧',
        role: MemberRole.teen,
        birthMonth: now.month,
        birthYear: now.year - 15,
        privacyLevel: PrivacyLevel.privateSpace,
      );

      expect(member.ageYears, 15);
      expect(member.ageBand, AgeBand.myLifeMyGoals);
    });

    test('Calculates Lifelong Family Bond for age 18+', () {
      final now = DateTime.now();
      final member = FamilyMember(
        id: 'parent_1',
        familyId: 'fam_1',
        name: 'Ibu',
        avatarEmoji: '🌸',
        role: MemberRole.owner,
        birthMonth: now.month,
        birthYear: now.year - 38,
        privacyLevel: PrivacyLevel.family,
      );

      expect(member.ageYears, 38);
      expect(member.ageBand, AgeBand.lifelongFamilyBond);
    });

    test('Handles birth month birthday-boundary edge cases correctly', () {
      final now = DateTime.now();
      // If birthday is next month, age should still be year - 1
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final birthYear = now.month == 12 ? now.year - 9 : now.year - 10;
      final member = FamilyMember(
        id: 'edge_case',
        familyId: 'fam_1',
        name: 'Tester',
        avatarEmoji: '⭐',
        role: MemberRole.child,
        birthMonth: nextMonth,
        birthYear: birthYear,
        privacyLevel: PrivacyLevel.family,
      );

      expect(member.ageYears, 9);
      expect(member.ageBand, AgeBand.happyHabitBuilder);
    });
  });

  group('WishGoal & Milestone Progress Logic Tests', () {
    test('Calculates progress percentage accurately', () {
      final goal = WishGoal(
        id: 'goal_1',
        memberId: 'child_1',
        memberName: 'Adik',
        titleMs: 'Basikal Baru',
        titleEn: 'New Bicycle',
        iconEmoji: '🚲',
        targetPoints: 100,
        currentPoints: 40,
        status: WishGoalStatus.active,
        basis: WishGoalBasis.monthly,
      );

      expect(goal.progress, 0.4);
      expect(goal.status, WishGoalStatus.active);
    });

    test('Clamps progress to 1.0 when points exceed target', () {
      final goal = WishGoal(
        id: 'goal_2',
        memberId: 'child_1',
        memberName: 'Adik',
        titleMs: 'Mainan Lego',
        titleEn: 'Lego Toy',
        iconEmoji: '🧱',
        targetPoints: 50,
        currentPoints: 65,
        status: WishGoalStatus.achieved,
        basis: WishGoalBasis.monthly,
      );

      expect(goal.progress, 1.0);
      expect(goal.status, WishGoalStatus.achieved);
    });

    test('Detects custom focusActivity requirement properly', () {
      final focusGoal = WishGoal(
        id: 'goal_3',
        memberId: 'child_1',
        memberName: 'Adik',
        titleMs: 'Hafazan Surah Lazim',
        titleEn: 'Surah Memorization',
        iconEmoji: '📖',
        targetPoints: 20,
        currentPoints: 5,
        status: WishGoalStatus.active,
        basis: WishGoalBasis.weekly,
        focusActivity: 'Baca & Semak Bersama Ibu',
      );

      expect(focusGoal.hasFocusActivity, true);
      expect(focusGoal.focusActivity, 'Baca & Semak Bersama Ibu');
    });
  });
}
