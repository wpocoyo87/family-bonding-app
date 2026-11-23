import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/models/erat_models.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/theme/erat_palette.dart';
import '../../calling/presentation/family_call_screen.dart';

class FamilyChatTab extends ConsumerStatefulWidget {
  const FamilyChatTab({super.key});

  @override
  ConsumerState<FamilyChatTab> createState() => _FamilyChatTabState();
}

class _FamilyChatTabState extends ConsumerState<FamilyChatTab> {
  // 0 = Messages, 1 = AI Companion, 2 = Challenges
  int _subTab = 0;
  String? _activeThreadId; // null = WhatsApp Chat List, 'family', 'sibling', 'alex', 'hana', 'lumi'
  String _chatFilter = 'all'; // 'all', 'family', 'direct', 'secrets'
  bool _isWalkieTalkieMode = false; // Kids 4-6 Push-to-Talk Mode
  bool _isPushToTalkRecording = false; // Active holding state
  String? _playingVoiceMsgId; // Track currently playing voice message
  String _challengeScope = 'For You';
  String _selectedChildForAi = 'Emmi';
  bool _joinedHeroChallenge = false;
  bool _showAiAnalysis = false;

  final Map<String, double> _challengeProgress = {
    'clean_room': 0.60,
    'read_together': 0.80,
    'brush_sparkle': 0.40,
    'family_picnic': 0.78,
    'sibling_helper': 0.50,
  };

  final TextEditingController _msgCtrl = TextEditingController();
  final TextEditingController _aiReplyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final active = ref.read(eratControllerProvider).activeMember;
      if (active.ageYears <= 6) {
        if (mounted) setState(() => _isWalkieTalkieMode = true);
      }
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _aiReplyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final worldTheme = ref.watch(selectedWorldThemeProvider);

    // If inside a WhatsApp conversation room, display the full WhatsApp Room directly!
    if (_subTab == 0 && _activeThreadId != null) {
      return _buildWhatsAppRoom(strings, worldTheme);
    }

    final screenTitle = switch (_subTab) {
      0 => 'Family WhatsApp 💬',
      1 => strings.tr('AI Family Companion', 'AI Family Companion'),
      _ => strings.tr('Challenges', 'Challenges'),
    };

    return Column(
      children: [
        // Top Header Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 16, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Text(
                  screenTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: EratPalette.textDark,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Add',
                onPressed: () {
                  if (_subTab == 2) {
                    _showAddChallengeSheet(context, strings);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Starting new family message thread...'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                icon: const Icon(
                  Icons.add_rounded,
                  size: 26,
                  color: EratPalette.textDark,
                ),
              ),
            ],
          ),
        ),

        // Clean Segmented Switcher
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 2, 22, 10),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: EratPalette.lavenderBorder),
            ),
            child: Row(
              children: [
                _SegmentTabItem(
                  label: '💬 Messages',
                  isSelected: _subTab == 0,
                  accentColor: worldTheme.accentColor,
                  onTap: () => setState(() => _subTab = 0),
                ),
                _SegmentTabItem(
                  label: '🧚🏻 AI Companion',
                  isSelected: _subTab == 1,
                  accentColor: worldTheme.accentColor,
                  onTap: () => setState(() => _subTab = 1),
                ),
                _SegmentTabItem(
                  label: '🏆 Challenges',
                  isSelected: _subTab == 2,
                  accentColor: worldTheme.accentColor,
                  onTap: () => setState(() => _subTab = 2),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: switch (_subTab) {
            0 => _buildFamilyChatView(strings, worldTheme),
            1 => _buildAiCompanionView(strings, worldTheme),
            _ => _buildChallengesView(strings, worldTheme),
          },
        ),
      ],
    );
  }

  /// Mockup Screen 5: "Challenges" (For You / Family / Sibling + 3D Kindness Challenge Card + Active Challenges + Shared Family Goal)
  Widget _buildChallengesView(AppStrings strings, EratWorldTheme worldTheme) {
    final appState = ref.watch(eratControllerProvider);
    final scopes = ['For You', 'Family', 'Sibling'];

    final challengesByScope = switch (_challengeScope) {
      'Family' => [
          (
            id: 'family_picnic',
            title: 'Gadget-Free Family Dinner',
            subtitle: 'Earn +3 Family Stars 🏡',
            assetPath: 'assets/images/family_hero.jpg',
            bgColor: const Color(0xFFEAF4FF),
          ),
          (
            id: 'read_together',
            title: 'Weekend Storytime Together',
            subtitle: 'Earn 60 points • +2 Stars',
            assetPath: 'assets/images/habit_study_read.jpg',
            bgColor: const Color(0xFFF3F0FF),
          ),
        ],
      'Sibling' => [
          (
            id: 'sibling_helper',
            title: 'Share Toys & Help Sibling',
            subtitle: 'Earn 50 points • Team Badge',
            assetPath: 'assets/images/challenge_kindness.jpg',
            bgColor: const Color(0xFFFFF0F6),
          ),
          (
            id: 'clean_room',
            title: 'Tidy Up Bedroom Together',
            subtitle: 'Earn 50 points',
            assetPath: 'assets/images/challenge_clean_room.jpg',
            bgColor: EratPalette.warmCream,
          ),
        ],
      _ => [
          (
            id: 'clean_room',
            title: 'Clean Your Room',
            subtitle: 'Earn 50 points',
            assetPath: 'assets/images/challenge_clean_room.jpg',
            bgColor: EratPalette.warmCream,
          ),
          (
            id: 'read_together',
            title: 'Read & Study 15 Mins',
            subtitle: 'Earn 50 points',
            assetPath: 'assets/images/habit_study_read.jpg',
            bgColor: const Color(0xFFEAF4FF),
          ),
          (
            id: 'brush_sparkle',
            title: 'Morning & Night Brush Teeth',
            subtitle: 'Earn 75 coins',
            assetPath: 'assets/images/habit_brush_teeth.jpg',
            bgColor: const Color(0xFFF3F0FF),
          ),
        ],
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
      children: [
        // Scope Pills: For You | Family | Sibling (Matching Mockup Screen 5)
        Row(
          children: scopes.map((sc) {
            final active = sc == _challengeScope;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => setState(() => _challengeScope = sc),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? worldTheme.accentColor : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: EratPalette.lavenderBorder),
                      boxShadow: active ? EratPalette.softShadow : null,
                    ),
                    child: Text(
                      sc,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: active ? Colors.white : EratPalette.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // CARD 1: Purple Gradient "Kindness Challenge" Hero Card with 3D Illustration (No clipped emoji!)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: EratPalette.kindnessCardGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: EratPalette.primaryPurple.withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('👑', style: TextStyle(fontSize: 24)),
                        const SizedBox(height: 6),
                        Text(
                          _challengeScope == 'Family'
                              ? 'Weekend Family Bonding'
                              : _challengeScope == 'Sibling'
                                  ? 'Secret Sibling Kindness'
                                  : 'Kindness Challenge',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _challengeScope == 'Family'
                              ? 'Complete 3 activities together as a family this week!'
                              : _challengeScope == 'Sibling'
                                  ? 'Leave a cheerful note or help your brother/sister today!'
                                  : 'Do one kind thing for another family member!',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/images/challenge_kindness.jpg',
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: Colors.white70,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '6 days left',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: EratPalette.primaryPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () {
                      setState(() => _joinedHeroChallenge = !_joinedHeroChallenge);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: EratPalette.primaryPurple,
                          content: Text(
                            _joinedHeroChallenge
                                ? '💖 Joined! Complete one kind act today for +3 Family Stars!'
                                : 'Challenge status updated.',
                          ),
                        ),
                      );
                    },
                    child: Text(
                      _joinedHeroChallenge ? 'Joined ✓' : 'Join',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // SECTION 2: Active Challenges Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Challenges',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: EratPalette.textDark,
              ),
            ),
            GestureDetector(
              onTap: () => _showAddChallengeSheet(context, strings),
              child: Text(
                '+ Add New',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: worldTheme.accentColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Active Challenge Cards with 3D Illustrations & Interactive Progress
        ...challengesByScope.map((ch) {
          final progress = _challengeProgress[ch.id] ?? 0.6;
          final pct = (progress * 100).round();

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  final next = (progress + 0.20).clamp(0.0, 1.0);
                  _challengeProgress[ch.id] = next;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: worldTheme.accentColor,
                    content: Text(
                      '✨ Progress updated for "${ch.title}"!',
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ch.bgColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: EratPalette.softShadow,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        ch.assetPath,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  ch.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: EratPalette.textDark,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: EratPalette.textMuted,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ch.subtitle,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: EratPalette.textMuted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 8,
                                    backgroundColor: Colors.white,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      worldTheme.accentColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '$pct%',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: EratPalette.textDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 8),

        // CARD 3: Shared Family Goal & Members Connection Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: EratPalette.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '🏡 Shared Family Goal',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: EratPalette.textDark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: worldTheme.softTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '⭐ ${appState.family.familyGoalCurrentStars} / ${appState.family.familyGoalTargetStars}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: worldTheme.accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                appState.family.familyGoalTitleEn,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: EratPalette.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: appState.members.map((m) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: worldTheme.softTint,
                            child: Text(
                              m.avatarEmoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.name.split(' ').first,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: EratPalette.textDark,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Dynamic AI Family Companion (Reads Behaviour Data + Chat Context per Individual Child)
  Widget _buildAiCompanionView(AppStrings strings, EratWorldTheme worldTheme) {
    final appState = ref.watch(eratControllerProvider);
    final activeMember = appState.activeMember;

    // IF ACTIVE MEMBER IS A CHILD: Show Child's Personal AI Buddy View
    if (!activeMember.isParentOrGuardian) {
      return _buildChildAiBuddyView(activeMember, worldTheme);
    }

    // IF ACTIVE MEMBER IS A PARENT: Show Parent Guidance Hub (Data-driven Insights + Roleplay)
    final childrenProfiles = [
      (
        id: 'child_1',
        name: 'Emmi (4y)',
        shortName: 'Emmi',
        emoji: '👧🏻',
        age: 4,
        questsDone: 3,
        totalQuests: 4,
        streak: 4,
        stars: 45,
        recentChatSnippet: "M-mommy... I can't find Teddy. I need Teddy to sleep... I can't sleep without him. Can you help me find him?",
        chatSentiment: 'Anxious / Bedtime Vulnerability',
        behaviourInsight: 'High energy during playtime, needs predictable calming routine before sleep.',
        aiTip: 'Connection before correction. Emmi needs emotional co-regulation when tired. Validate her fear first before problem-solving.',
        scenarioPrompt: 'Your child has lost their favorite toy just before bedtime and is feeling anxious. Think about how you can support them to help them feel safe.',
        childLine: "M-mommy... I can't find Teddy. I need Teddy to sleep... I can't sleep without him. Can you help me find him?",
        parentLine: "Don't worry, sweetheart. We'll find Teddy together. I'm right here with you.",
        analysis: 'Great empathy! You validated Emmi\'s bedtime anxiety warmly instead of rushing her, helping her nervous system calm down before sleep.'
      ),
      (
        id: 'child_2',
        name: 'Alex (8y)',
        shortName: 'Alex',
        emoji: '👦🏻',
        age: 8,
        questsDone: 4,
        totalQuests: 5,
        streak: 6,
        stars: 95,
        recentChatSnippet: 'Mom! Look, I brushed my teeth and made my bed all by myself today without reminder!',
        chatSentiment: 'Pride / Eager for Recognition',
        behaviourInsight: 'Strong intrinsic motivation this week. Responds exceptionally well to specific, non-monetary praise.',
        aiTip: 'Acknowledge his initiative, not just the task. Celebrate that he did it "without reminder" to reinforce self-discipline.',
        scenarioPrompt: 'Alex completed multiple daily quests autonomously and is proud. Reinforce his growth mindset.',
        childLine: 'Mom! Look, I brushed my teeth and made my bed all by myself today!',
        parentLine: 'High five, Alex! I noticed how neat your bed looks and love that you did it on your own! Want to choose tonight\'s dinner game?',
        analysis: 'Awesome positive reinforcement! Praising specific effort ("how neat your bed looks") and autonomy builds lasting intrinsic motivation.'
      ),
      (
        id: 'child_3',
        name: 'Adam (11y)',
        shortName: 'Adam',
        emoji: '🚀',
        age: 11,
        questsDone: 2,
        totalQuests: 4,
        streak: 3,
        stars: 120,
        recentChatSnippet: 'My science model is taking way longer than I thought, I might not finish tonight :(',
        chatSentiment: 'Frustrated / Overwhelmed',
        behaviourInsight: 'Tends to resist direct commands when stressed. Prefers collaborative problem solving on equal footing.',
        aiTip: 'Offer supportive co-play. Give him autonomy by asking "Do you want help brainstorming or just a snack break?" rather than taking over.',
        scenarioPrompt: 'Adam is facing academic frustration with his school project. Support without lecturing.',
        childLine: 'My science model is taking longer than I thought, I might not finish tonight.',
        parentLine: 'Want to brainstorm the trickiest part together for 10 minutes after dinner? Or take a quick stretch first?',
        analysis: 'Supportive co-play approach! Offering collaboration while leaving Adam in charge of the choice respects his growing pre-teen independence.'
      ),
      (
        id: 'child_4',
        name: 'Hana (15y)',
        shortName: 'Hana',
        emoji: '🎧',
        age: 15,
        questsDone: 3,
        totalQuests: 3,
        streak: 8,
        stars: 185,
        recentChatSnippet: 'I have a lot of revision this week for trials, feeling a bit tired and drained.',
        chatSentiment: 'Fatigued / Seeking Low-pressure Presence',
        behaviourInsight: 'Values private space and autonomy. Most receptive to non-intrusive acts of service and quiet support.',
        aiTip: 'Low-pressure warmth. Drop off a warm drink or snack with a brief affirming note without demanding a long conversation.',
        scenarioPrompt: 'Hana is studying for exams and feeling overwhelmed. Show unconditional support without invading boundaries.',
        childLine: 'I have a lot of exam revision this week, feeling a bit tired.',
        parentLine: 'Made your favorite hot chocolate—left it by your desk. No rush on anything tonight, proud of you always 💛',
        analysis: 'Exceptional parenting! Low-pressure warmth allows teens to feel deeply loved without the burden of performing or answering questions.'
      ),
    ];

    final currentChild = childrenProfiles.firstWhere(
      (c) => c.shortName == _selectedChildForAi,
      orElse: () => childrenProfiles[0],
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
      children: [
        // CARD 1: Mascot Header & Child Selector Pill Grid
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF8FF),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: EratPalette.softShadow,
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/images/mascot_companion.jpg',
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'AI Family Companion',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: EratPalette.textDark,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Personalized Guidance Powered by Behaviour & Chat Data',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: EratPalette.textMuted,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: childrenProfiles.map((c) {
                  final selected = _selectedChildForAi == c.shortName;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedChildForAi = c.shortName;
                      _showAiAnalysis = false;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? worldTheme.accentColor : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: EratPalette.softShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(c.emoji, style: const TextStyle(fontSize: 15)),
                          const SizedBox(width: 6),
                          Text(
                            c.name,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: selected
                                  ? Colors.white
                                  : EratPalette.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // CARD 2: REAL BEHAVIOUR & CHAT INTELLIGENCE CARD
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: EratPalette.lavenderBorder),
            boxShadow: EratPalette.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: worldTheme.softTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.analytics_rounded, size: 18, color: EratPalette.primaryPurple),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${currentChild.shortName}\'s Behaviour & Chat Data',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: EratPalette.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Behaviour Metrics Grid
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F8FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Quests Today', style: TextStyle(fontSize: 10.5, color: EratPalette.textMuted, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('${currentChild.questsDone}/${currentChild.totalQuests} Done', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1976D2))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9EE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Active Streak', style: TextStyle(fontSize: 10.5, color: EratPalette.textMuted, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('🔥 ${currentChild.streak} Days', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFF57C00))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F3FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Stars', style: TextStyle(fontSize: 10.5, color: EratPalette.textMuted, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('⭐ ${currentChild.stars}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: EratPalette.primaryPurple)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Chat Context Snippet (Read from Messenger)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9FD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEDE8F5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('💬', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        const Text(
                          'Latest Family Chat Sentiment:',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: EratPalette.textDark,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFE9FD),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            currentChild.chatSentiment,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: EratPalette.primaryPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '"${currentChild.recentChatSnippet}"',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: EratPalette.textDark,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // AI Advice summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentChild.aiTip,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF166534),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // CARD 3: Interactive Roleplay & Practice Conversation
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: EratPalette.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🎭', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  const Text(
                    'Practice Your Response',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: EratPalette.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // AI Coach Scenario Prompt
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/images/mascot_companion.jpg',
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F7FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        currentChild.scenarioPrompt,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: EratPalette.textDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Child Message Bubble
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: EratPalette.softLavender,
                    child: Text(currentChild.emoji),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9E6FF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        currentChild.childLine,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: EratPalette.textDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Parent Response Bubble
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        currentChild.parentLine,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: EratPalette.textDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(0xFFEAF4FF),
                    child: Text('👩🏻‍💼'),
                  ),
                ],
              ),

              if (_showAiAnalysis) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: EratPalette.warmCream,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: EratPalette.warmCreamBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          currentChild.analysis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: EratPalette.textDark,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              EratPrimaryPillButton(
                label: _showAiAnalysis
                    ? 'Reset Scenario'
                    : 'Analyze Conversation ✨',
                onPressed: () {
                  setState(() => _showAiAnalysis = !_showAiAnalysis);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// CHILD INDIVIDUAL AI BUDDY VIEW (For Emmi, Alex, Adam, Hana)
  Widget _buildChildAiBuddyView(FamilyMember activeMember, EratWorldTheme worldTheme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      children: [
        // Friendly Mascot Hero Greeting
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                worldTheme.accentColor.withValues(alpha: 0.15),
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: EratPalette.softShadow,
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/images/mascot_companion.jpg',
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Hi ${activeMember.name}! 🌟',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: EratPalette.textDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'I\'m Lumi, your personal ERAT Buddy! How are you feeling today?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: EratPalette.textMuted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),

              // Child Mood Check-in
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMoodPill('😄 Happy', () => _showBuddyToast('Yay! Keep shining bright! ⭐')),
                  _buildMoodPill('😴 Tired', () => _showBuddyToast('Rest up, superstar! You worked hard today 🌙')),
                  _buildMoodPill('🚀 Ready', () => _showBuddyToast('Let\'s conquer your daily quests! 🎮')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick Buddy Chat Bubble
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: EratPalette.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🧚🏻', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    'Lumi\'s Daily Cheer for You',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: worldTheme.accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F6FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'You\'ve got ${activeMember.streakDays} days streak going! Complete your quests in the Quests tab to harvest stars for Pizza Night! 🍕',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: EratPalette.textDark,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Quick questions for Lumi:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: EratPalette.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickActionChip('📖 Bedtime Story'),
                  _buildQuickActionChip('🧩 Fun Riddle'),
                  _buildQuickActionChip('💬 Message Mom'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoodPill(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: EratPalette.textDark),
        ),
      ),
    );
  }

  Widget _buildQuickActionChip(String label) {
    return ActionChip(
      label: Text(label),
      backgroundColor: const Color(0xFFF3E8FF),
      labelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: EratPalette.primaryPurple,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () => _showBuddyToast('Lumi: Thinking of something fun for you! ✨'),
    );
  }

  void _showBuddyToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// WhatsApp Messenger View: Conversations List (when no thread selected)
  Widget _buildFamilyChatView(AppStrings strings, EratWorldTheme worldTheme) {
    final appState = ref.watch(eratControllerProvider);
    final activeMember = appState.activeMember;

    final threads = [
      (
        id: 'family',
        name: '👨‍👩‍👧‍👦 Family Living Room',
        avatarAsset: 'assets/images/family_hero.jpg',
        avatarEmoji: '🏡',
        subtitle: 'Daniel: Heading home early today, happy to help with dinner ☕✨',
        time: '3:42 PM',
        unreadCount: 2,
        isPrivate: false,
        onlineStatus: 'Sarah, Ahmad, Alex, Hana, Daniel...',
      ),
      (
        id: 'sibling',
        name: '🤫 Sibling Secret Channel',
        avatarAsset: 'assets/images/challenge_clean_room.jpg',
        avatarEmoji: '🤫',
        subtitle: 'Hana: Perfect! I\'ll prepare the mini cake later at 5:00 PM 🎂✨',
        time: '3:14 PM',
        unreadCount: 1,
        isPrivate: true,
        onlineStatus: 'Hana, Adam, Alex (Encrypted)',
      ),
      (
        id: 'alex',
        name: '👦🏻 Alex (8y)',
        avatarAsset: 'assets/images/habit_brush_teeth.jpg',
        avatarEmoji: '👦🏻',
        subtitle: 'Alex: 🌟 Yay! I finished making my bed and brushing my teeth!',
        time: '1:30 PM',
        unreadCount: 0,
        isPrivate: false,
        onlineStatus: 'online',
      ),
      (
        id: 'hana',
        name: '🎧 Hana (15y)',
        avatarAsset: 'assets/images/habit_study_read.jpg',
        avatarEmoji: '🎧',
        subtitle: 'Sarah: Made your favorite hot chocolate—left it by your desk 💛',
        time: '12:05 PM',
        unreadCount: 0,
        isPrivate: false,
        onlineStatus: 'online',
      ),
      (
        id: 'lumi',
        name: '🧚🏻 Lumi AI Companion',
        avatarAsset: 'assets/images/mascot_companion.jpg',
        avatarEmoji: '🧚🏻',
        subtitle: 'Lumi: Emmi felt anxious before bedtime. Try a 10m cuddle.',
        time: '10:15 AM',
        unreadCount: 0,
        isPrivate: false,
        onlineStatus: 'Always Active AI',
      ),
    ];

    final filteredThreads = threads.where((t) {
      if (_chatFilter == 'family') return t.id == 'family';
      if (_chatFilter == 'direct') return t.id == 'alex' || t.id == 'hana';
      if (_chatFilter == 'secrets') return t.isPrivate;
      return true;
    }).toList();

    return Column(
      children: [
        // WhatsApp Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Search family chats or messages...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Quick Walkie-Talkie Banner for Kids 4-6 Years Old
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: InkWell(
            onTap: () {
              setState(() {
                _activeThreadId = 'family';
                _isWalkieTalkieMode = true;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDCFCE7), Color(0xFFBBF7D0)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF86EFAC)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.radio_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📻 Mod Walkie-Talkie Kanak-Kanak',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF14532D),
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Khas untuk anak 4-6 tahun: Tekan & tahan untuk bercakap tanpa perlu menaip!',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF16A34A)),
                ],
              ),
            ),
          ),
        ),

        // Quick WhatsApp Filter Chips (All, Family, 1-on-1, Secrets)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChatFilterChip('all', 'All Chats (5)', worldTheme),
                const SizedBox(width: 8),
                _buildChatFilterChip('family', '👨‍👩‍👧‍👦 Family Room', worldTheme),
                const SizedBox(width: 8),
                _buildChatFilterChip('direct', '💬 1-on-1', worldTheme),
                const SizedBox(width: 8),
                _buildChatFilterChip('secrets', '🔒 Sibling Secrets', worldTheme),
              ],
            ),
          ),
        ),

        // WhatsApp Conversation Threads List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: filteredThreads.length,
            separatorBuilder: (ctx, idx) => const Divider(
              height: 1,
              indent: 72,
              color: Color(0xFFF1F5F9),
            ),
            itemBuilder: (ctx, i) {
              final thread = filteredThreads[i];
              return InkWell(
                onTap: () {
                  if (thread.isPrivate) {
                    final isUnlocked = ref.read(isPrivateSpaceUnlockedProvider);
                    if (!isUnlocked) {
                      _showUnlockPrivateDialog(context, activeMember);
                      return;
                    }
                  }
                  setState(() => _activeThreadId = thread.id);
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Row(
                    children: [
                      // Avatar with Online dot / Lock badge
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              thread.avatarAsset,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 52,
                                height: 52,
                                color: EratPalette.softLavender,
                                alignment: Alignment.center,
                                child: Text(thread.avatarEmoji, style: const TextStyle(fontSize: 26)),
                              ),
                            ),
                          ),
                          if (thread.isPrivate)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD946EF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.lock_rounded, size: 10, color: Colors.white),
                              ),
                            )
                          else
                            Positioned(
                              bottom: 1,
                              right: 1,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Thread Name & Message Snippet
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    thread.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: EratPalette.textDark,
                                    ),
                                  ),
                                ),
                                Text(
                                  thread.time,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: thread.unreadCount > 0 ? FontWeight.w800 : FontWeight.w600,
                                    color: thread.unreadCount > 0
                                        ? worldTheme.accentColor
                                        : EratPalette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (thread.unreadCount == 0) ...[
                                  const Icon(Icons.done_all_rounded, size: 16, color: Color(0xFF38BDF8)),
                                  const SizedBox(width: 4),
                                ],
                                Expanded(
                                  child: Text(
                                    thread.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: thread.unreadCount > 0
                                          ? EratPalette.textDark
                                          : EratPalette.textMuted,
                                      fontWeight: thread.unreadCount > 0 ? FontWeight.w700 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (thread.unreadCount > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: worldTheme.accentColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${thread.unreadCount}',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatFilterChip(String key, String label, EratWorldTheme worldTheme) {
    final isSelected = _chatFilter == key;
    return InkWell(
      onTap: () => setState(() => _chatFilter = key),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? worldTheme.accentColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? worldTheme.accentColor : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : EratPalette.textDark,
          ),
        ),
      ),
    );
  }

  /// FULL-FLEDGED WHATSAPP CONVERSATION ROOM VIEW
  Widget _buildWhatsAppRoom(AppStrings strings, EratWorldTheme worldTheme) {
    final appState = ref.watch(eratControllerProvider);
    final activeMember = appState.activeMember;

    // Determine current thread details
    final (title, subtitle, avatarPath, avatarEmoji, isGroup) = switch (_activeThreadId) {
      'sibling' => (
          '🤫 Sibling Secret Channel',
          'Hana, Adam, Alex (🔒 PIN Protected)',
          'assets/images/challenge_clean_room.jpg',
          '🤫',
          true,
        ),
      'alex' => (
          '👦🏻 Alex (8y)',
          'online',
          'assets/images/habit_brush_teeth.jpg',
          '👦🏻',
          false,
        ),
      'hana' => (
          '🎧 Hana (15y)',
          'online',
          'assets/images/habit_study_read.jpg',
          '🎧',
          false,
        ),
      'lumi' => (
          '🧚🏻 Lumi AI Companion',
          'Always Active AI Buddy',
          'assets/images/mascot_companion.jpg',
          '🧚🏻',
          false,
        ),
      _ => (
          '👨‍👩‍👧‍👦 Family Living Room',
          'Sarah, Ahmad, Alex, Hana, Daniel...',
          'assets/images/family_hero.jpg',
          '🏡',
          true,
        ),
    };

    final channelName = switch (_activeThreadId) {
      'sibling' => 'private_sibling',
      'alex' => 'direct_alex',
      'hana' => 'direct_hana',
      'lumi' => 'direct_lumi',
      _ => 'family',
    };

    final threadMessages = appState.messages
        .where((m) =>
            m.channel == channelName ||
            (channelName == 'family' && m.channel == 'family'))
        .toList();

    return Container(
      color: const Color(0xFFECE5DD), // Classic WhatsApp wallpaper tint
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // WHATSAPP APP BAR
            Container(
              padding: const EdgeInsets.fromLTRB(4, 6, 8, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: EratPalette.textDark, size: 24),
                    onPressed: () => setState(() => _activeThreadId = null),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      avatarPath,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 40,
                        height: 40,
                        color: EratPalette.softLavender,
                        alignment: Alignment.center,
                        child: Text(avatarEmoji, style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: EratPalette.textDark,
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Walkie-Talkie Mode Toggle Button in WhatsApp Bar
                  InkWell(
                    onTap: () {
                      setState(() => _isWalkieTalkieMode = !_isWalkieTalkieMode);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: _isWalkieTalkieMode
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF6366F1),
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            _isWalkieTalkieMode
                                ? '📻 Mod Walkie-Talkie Kanak-Kanak Aktif! (Push-to-Talk)'
                                : '⌨️ Mod Papan Kekunci Biasa Aktif.',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isWalkieTalkieMode
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _isWalkieTalkieMode
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFCBD5E1),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isWalkieTalkieMode
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_outlined,
                            size: 15,
                            color: _isWalkieTalkieMode
                                ? const Color(0xFF15803D)
                                : const Color(0xFF475569),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isWalkieTalkieMode ? '📻 Walkie-Talkie' : '📻 Walkie',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: _isWalkieTalkieMode
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call_rounded, color: Color(0xFF475569), size: 22),
                    tooltip: 'Panggilan Suara VoIP',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => FamilyCallScreen(
                            isVideoCall: false,
                            participantName: title,
                            participantAvatarAsset: avatarPath,
                            participantAvatarEmoji: avatarEmoji,
                            channelName: channelName,
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.videocam_rounded, color: Color(0xFF475569), size: 24),
                    tooltip: 'Panggilan Video HD',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => FamilyCallScreen(
                            isVideoCall: true,
                            participantName: title,
                            participantAvatarAsset: avatarPath,
                            participantAvatarEmoji: avatarEmoji,
                            channelName: channelName,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // CHAT MESSAGES CANVAS (WhatsApp Style)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                children: [
                  // WhatsApp Date Bubble
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'TODAY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),

                  // Messages Bubbles
                  ...threadMessages.map((msg) {
                    final isMe = msg.senderId == activeMember.id;
                    final isPlaying = _playingVoiceMsgId == msg.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment:
                            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe && isGroup) ...[
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.white,
                              child: Text(msg.senderAvatar, style: const TextStyle(fontSize: 14)),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.78,
                              ),
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? const Color(0xFFE7FFDB) // WhatsApp Sent Green / Soft Tint
                                    : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe && isGroup) ...[
                                    Text(
                                      msg.senderName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF9333EA),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                  ],

                                  // Check if it's an audio voice note (Walkie-Talkie message)
                                  if (msg.isAudioVoiceNote) ...[
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              if (_playingVoiceMsgId == msg.id) {
                                                _playingVoiceMsgId = null;
                                              } else {
                                                _playingVoiceMsgId = msg.id;
                                              }
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(24),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: isPlaying
                                                  ? const Color(0xFFEF4444)
                                                  : const Color(0xFF16A34A),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              isPlaying
                                                  ? Icons.pause_rounded
                                                  : Icons.play_arrow_rounded,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Animated Soundwave Simulation
                                              Row(
                                                children: [6, 12, 18, 10, 22, 16, 8, 24, 18, 14, 20, 12, 16, 8, 14]
                                                    .map((h) {
                                                  return Container(
                                                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                                    width: 3,
                                                    height: isPlaying
                                                        ? (h * 1.15).clamp(4.0, 26.0)
                                                        : h.toDouble(),
                                                    decoration: BoxDecoration(
                                                      color: isPlaying
                                                          ? const Color(0xFF16A34A)
                                                          : const Color(0xFF64748B),
                                                      borderRadius: BorderRadius.circular(2),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    msg.audioDuration ?? '0:05',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: Color(0xFF64748B),
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.mic_rounded,
                                                        size: 11,
                                                        color: isPlaying
                                                            ? const Color(0xFFEF4444)
                                                            : const Color(0xFF16A34A),
                                                      ),
                                                      const SizedBox(width: 2),
                                                      Text(
                                                        isPlaying ? 'Playing...' : 'Walkie-Talkie',
                                                        style: TextStyle(
                                                          fontSize: 9.5,
                                                          fontWeight: FontWeight.w800,
                                                          color: isPlaying
                                                              ? const Color(0xFFEF4444)
                                                              : const Color(0xFF16A34A),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (msg.content.isNotEmpty) ...[
                                      const SizedBox(height: 5),
                                      Text(
                                        msg.content,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontStyle: FontStyle.italic,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  ] else ...[
                                    Text(
                                      msg.content,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: Color(0xFF1E293B),
                                        height: 1.35,
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 3),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.done_all_rounded,
                                          size: 14,
                                          color: Color(0xFF38BDF8), // Blue double ticks
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            // WHATSAPP BOTTOM BAR (Toggles between Standard Keyboard vs Walkie-Talkie Station)
            if (_isWalkieTalkieMode)
              _buildWalkieTalkieBottomBar(channelName, activeMember, worldTheme)
            else
              _buildStandardWhatsAppBottomBar(channelName, worldTheme),
          ],
        ),
      ),
    );
  }

  /// Giant Tactile Walkie-Talkie & Voiced Sticker Deck for Kids (4-6y)
  Widget _buildWalkieTalkieBottomBar(
    String channelName,
    FamilyMember activeMember,
    EratWorldTheme worldTheme,
  ) {
    final quickAudioPrompts = [
      (emoji: '🧸', label: 'Dah Kemas Mainan!', voice: '🎙️ Ibu, adik dah siap kemas mainan! 🧸', dur: '0:03'),
      (emoji: '🪥', label: 'Gigi Dah Bersih!', voice: '🎙️ Tengok gigi adik dah berkilat! 🪥✨', dur: '0:03'),
      (emoji: '❤️', label: 'Sayang Ibu & Ayah!', voice: '🎙️ Adik sayang Ibu & Ayah sangat-sangat! ❤️', dur: '0:04'),
      (emoji: '🍕', label: 'Lapar / Nak Makan!', voice: '🎙️ Perut adik berbunyi, jom makan pizza! 🍕', dur: '0:03'),
      (emoji: '📖', label: 'Jom Cerita Buku!', voice: '🎙️ Ibu, jom baca buku cerita sebelum tidur! 📖⭐', dur: '0:04'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mode header + Switch to keyboard button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.radio_button_checked_rounded, color: Color(0xFF16A34A), size: 14),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '📻 Walkie-Talkie Kanak-Kanak',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _isWalkieTalkieMode = false),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.keyboard_outlined, size: 14, color: Color(0xFF475569)),
                      SizedBox(width: 4),
                      Text(
                        'Papan Kekunci',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quick 1-Tap Audio Stickers (For 4-6 year olds who cannot read/write fluently)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: quickAudioPrompts.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      ref.read(eratControllerProvider.notifier).sendMessage(
                            channel: channelName,
                            content: p.voice,
                            isAudioVoiceNote: true,
                            audioDuration: p.dur,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF16A34A),
                          content: Text('📻 Dihantar: "${p.label}" ke Walkie-Talkie!'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Text(p.emoji, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            p.label,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.volume_up_rounded, size: 14, color: Color(0xFF16A34A)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Giant Tactile Push-to-Talk (Hold to Speak) Button
          GestureDetector(
            onTapDown: (_) {
              setState(() => _isPushToTalkRecording = true);
            },
            onTapUp: (_) {
              setState(() => _isPushToTalkRecording = false);
              ref.read(eratControllerProvider.notifier).sendMessage(
                    channel: channelName,
                    content: '🎙️ Mesej Suara Walkie-Talkie (${activeMember.name})',
                    isAudioVoiceNote: true,
                    audioDuration: '0:05',
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('📻 Mesej suara ${activeMember.name} dihantar! 📡'),
                    ],
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            onTapCancel: () {
              setState(() => _isPushToTalkRecording = false);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: _isPushToTalkRecording
                    ? const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (_isPushToTalkRecording
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981))
                        .withValues(alpha: 0.35),
                    blurRadius: _isPushToTalkRecording ? 18 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isPushToTalkRecording
                        ? Icons.fiber_manual_record_rounded
                        : Icons.mic_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isPushToTalkRecording
                        ? '🔴 SEDANG MERAKAM SUARA... (LEPASKAN)'
                        : '🎙️ TEKAN & TAHAN UNTUK BERCAKAP 📻',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Standard WhatsApp Text Input Bar
  Widget _buildStandardWhatsAppBottomBar(String channelName, EratWorldTheme worldTheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 14),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined, color: Color(0xFF64748B), size: 22),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('😊 Sticker & Emoji panel ready!'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded, color: Color(0xFF64748B), size: 22),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📎 Share photo, quest badge, or audio note'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF64748B), size: 21),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('📷 Camera ready to capture moment'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 23,
            backgroundColor: worldTheme.accentColor,
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: () {
                if (_msgCtrl.text.trim().isEmpty) {
                  // Switch to Walkie-Talkie if no text
                  setState(() => _isWalkieTalkieMode = true);
                  return;
                }
                ref.read(eratControllerProvider.notifier).sendMessage(
                      channel: channelName,
                      content: _msgCtrl.text,
                    );
                _msgCtrl.clear();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showUnlockPrivateDialog(BuildContext context, FamilyMember activeMember) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('🔒 Sibling Secret PIN'),
        content: Text(
          'This confidential channel is locked to protect sibling surprises and teen personal space.\n\nUse Demo PIN: ${activeMember.pin ?? "1234"} to unlock.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(isPrivateSpaceUnlockedProvider.notifier).state = true;
              Navigator.pop(ctx);
              setState(() => _activeThreadId = 'sibling');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔓 Sibling Channel Unlocked!'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text('Unlock with PIN'),
          ),
        ],
      ),
    );
  }

  void _showAddChallengeSheet(BuildContext context, AppStrings strings) {
    final titleCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Family Challenge',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: EratPalette.textDark,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  hintText: 'E.g., Weekend Board Game Night',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              EratPrimaryPillButton(
                label: 'Save Challenge',
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) return;
                  ref.read(eratControllerProvider.notifier).addActivity(
                        titleMs: titleCtrl.text.trim(),
                        titleEn: titleCtrl.text.trim(),
                        descMs: 'Family Challenge',
                        descEn: 'Family Challenge',
                        iconEmoji: '🏆',
                        category: ActivityCategory.familyChallenge,
                        durationMinutes: 15,
                        points: 50,
                        stars: 3,
                        requiresParentVerification: false,
                      );
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SegmentTabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _SegmentTabItem({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : EratPalette.textDark,
            ),
          ),
        ),
      ),
    );
  }
}
