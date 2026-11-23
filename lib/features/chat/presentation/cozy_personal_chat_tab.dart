import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/models/erat_models.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/services/media_storage_service.dart';
import '../../../core/services/voice_audio_service.dart';
import '../../../core/theme/cozy_theme.dart';

/// Cozy Minimalist Multi-Channel Family Chat Tab for Private Space
/// Supports: Family Group (with Parents), Siblings Group, and 1-on-1 Direct Chats
class CozyPersonalChatTab extends ConsumerStatefulWidget {
  const CozyPersonalChatTab({super.key});

  @override
  ConsumerState<CozyPersonalChatTab> createState() =>
      _CozyPersonalChatTabState();
}

class _CozyPersonalChatTabState extends ConsumerState<CozyPersonalChatTab> {
  static const Color _mochaPrimary = Color(0xFF6D4C41);
  static const Color _warmCocoa = Color(0xFF5A463C);
  static const Color _blushSurface = Color(0xFFF5E4DC);
  static const Color _blushBorder = Color(0xFFE5CEC2);
  static const Color _linenSurface = Color(0xFFFAF2E8);

  final _messageCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final VoiceAudioService _voiceService = VoiceAudioService();

  // Channel IDs: 'family_group', 'siblings_group', or 'dm_<memberId>'
  String _activeChannelId = 'family_group';

  String? _playingVoiceId;
  int _playSeconds = 0;
  Timer? _playTimer;

  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String? _activeRecordingFileId;

  final Map<String, List<Map<String, dynamic>>> _messagesByChannel = {
    'family_group': [
      {
        'id': 'fg_1',
        'senderMs': 'Sarah (Ibu)',
        'senderEn': 'Sarah (Mom)',
        'avatar': '🧕',
        'isMe': false,
        'textMs': 'Sayang semua, petang ni jangan lupa minum air secukupnya ya ♡',
        'textEn': 'Sweethearts, remember to drink plenty of water this afternoon ♡',
        'time': '16:15',
        'isVoice': false,
      },
      {
        'id': 'fg_2',
        'senderMs': 'Saya',
        'senderEn': 'Me',
        'avatar': '👦',
        'isMe': true,
        'textMs': 'Baik Ibu! Saya baru siap siram pokok bunga di laman tadi ✨',
        'textEn': 'Got it Mom! I just finished watering the garden plants ✨',
        'time': '16:20',
        'isVoice': false,
      },
      {
        'id': 'fg_3',
        'senderMs': 'Mark (Ayah)',
        'senderEn': 'Mark (Dad)',
        'avatar': '👨',
        'isMe': false,
        'textMs': 'Bagus sekali! Petang nanti kita baca buku sama-sama 📖',
        'textEn': 'Great job! Let’s read a book together this evening 📖',
        'time': '16:35',
        'isVoice': false,
      },
      {
        'id': 'fg_4',
        'senderMs': 'Sarah (Ibu)',
        'senderEn': 'Sarah (Mom)',
        'avatar': '🧕',
        'isMe': false,
        'textMs': 'Ibu bangga sangat dengan usaha hari ini ♡',
        'textEn': 'Mom is so proud of your effort today ♡',
        'time': '16:40',
        'isVoice': true,
        'durationSec': 14,
      },
    ],
    'siblings_group': [
      {
        'id': 'sib_1',
        'senderMs': 'Hana',
        'senderEn': 'Hana',
        'avatar': '🎧',
        'isMe': false,
        'textMs': 'Siapa nak main board game lepas siap kerja rumah malam ni? 🎲',
        'textEn': 'Who wants to play a board game after homework tonight? 🎲',
        'time': '15:40',
        'isVoice': false,
      },
      {
        'id': 'sib_2',
        'senderMs': 'Adam',
        'senderEn': 'Adam',
        'avatar': '🚀',
        'isMe': false,
        'textMs': 'Nak! Saya dah hampir siap baca buku 15 minit dah ni 📚',
        'textEn': 'Count me in! I’m almost done with my 15-min reading 📚',
        'time': '15:45',
        'isVoice': false,
      },
      {
        'id': 'sib_3',
        'senderMs': 'Saya',
        'senderEn': 'Me',
        'avatar': '👧',
        'isMe': true,
        'textMs': 'Jom! Kita kumpul bintang sama-sama untuk Pizza Night 🍕',
        'textEn': 'Yay! Let’s earn stars together for Pizza Night 🍕',
        'time': '15:52',
        'isVoice': false,
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToBottom(jump: true));
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _recordTimer?.cancel();
    _voiceService.dispose();
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _localizedMemberName(String rawName, AppStrings strings) {
    if (!strings.isMs) {
      return rawName
          .replaceAll('(Ibu)', '(Mom)')
          .replaceAll('(Ayah)', '(Dad)');
    }
    return rawName
        .replaceAll('(Mom)', '(Ibu)')
        .replaceAll('(Dad)', '(Ayah)');
  }

  bool get _isRealAccount =>
      Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;

  List<Map<String, dynamic>> _messagesForChannel(
    String channelId,
    List<FamilyMember> members,
    AppStrings strings,
  ) {
    // Real authenticated family accounts start fresh with ZERO demo Sarah/Mark messages!
    if (_isRealAccount) {
      final appState = ref.read(eratControllerProvider);
      final activeId = appState.activeMemberId;
      return appState.messages
          .where((m) => m.channel == channelId)
          .map((m) {
        final hh = m.createdAt.hour.toString().padLeft(2, '0');
        final mm = m.createdAt.minute.toString().padLeft(2, '0');
        final durSec = m.audioDuration != null
            ? (int.tryParse(m.audioDuration!.split(':').last) ?? 10)
            : 10;
        return <String, dynamic>{
          'id': m.id,
          'senderMs': m.senderName,
          'senderEn': m.senderName,
          'avatar': m.senderAvatar,
          'isMe': m.senderId == activeId,
          'textMs': m.content,
          'textEn': m.content,
          'time': '$hh:$mm',
          'isVoice': m.isAudioVoiceNote,
          'durationSec': durSec,
          'audioUrl': m.audioUrl,
        };
      }).toList();
    }

    return _messagesByChannel.putIfAbsent(channelId, () {
      if (channelId.startsWith('dm_')) {
        final targetId = channelId.substring(3);
        final target = members.where((m) => m.id == targetId).firstOrNull;
        if (target != null) {
          final isParent = target.isParentOrGuardian;
          return [
            {
              'id': 'dm_seed_$targetId',
              'senderMs': _localizedMemberName(target.name, const AppStrings(AppLanguage.ms)),
              'senderEn': _localizedMemberName(target.name, const AppStrings(AppLanguage.en)),
              'avatar': target.avatarEmoji,
              'isMe': false,
              'textMs': isParent
                  ? 'Hai sayang! Ada apa-apa yang nak kongsi hari ini? ♡'
                  : 'Hai! Macam mana misi hari ini? Jom semangat sama-sama! ✨',
              'textEn': isParent
                  ? 'Hi sweetheart! Anything you’d like to share today? ♡'
                  : 'Hey! How are your quests going today? Let’s cheer each other on! ✨',
              'time': '14:10',
              'isVoice': false,
            },
          ];
        }
      }
      return [];
    });
  }

  void _scrollToBottom({bool jump = false}) {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!mounted || !_scrollCtrl.hasClients) return;
      final target = _scrollCtrl.position.maxScrollExtent;
      if (jump) {
        _scrollCtrl.jumpTo(target);
      } else {
        _scrollCtrl.animateTo(
          target,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _selectChannel(String channelId) {
    if (_activeChannelId == channelId) return;
    HapticFeedback.selectionClick();
    setState(() {
      _activeChannelId = channelId;
    });
    _scrollToBottom(jump: true);
  }

  void _toggleVoicePlayback(
    String voiceId,
    int totalSeconds, {
    String? audioUrl,
  }) {
    HapticFeedback.selectionClick();
    if (_playingVoiceId == voiceId) {
      _playTimer?.cancel();
      _voiceService.stopPlayback();
      setState(() {
        _playingVoiceId = null;
        _playSeconds = 0;
      });
      return;
    }

    _playTimer?.cancel();
    _voiceService.play(
      audioUrl,
      onComplete: () {
        if (!mounted) return;
        _playTimer?.cancel();
        setState(() {
          _playingVoiceId = null;
          _playSeconds = 0;
        });
      },
    );
    setState(() {
      _playingVoiceId = voiceId;
      _playSeconds = 1;
    });
    _playTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_playSeconds >= totalSeconds) {
        t.cancel();
        setState(() {
          _playingVoiceId = null;
          _playSeconds = 0;
        });
      } else {
        setState(() => _playSeconds++);
      }
    });
  }

  Future<void> _toggleVoiceRecording(AppStrings strings) async {
    final appState = ref.read(eratControllerProvider);
    final activeMember = appState.activeMember;
    if (!_isRecording) {
      HapticFeedback.mediumImpact();
      final fileId = 'chat_${DateTime.now().millisecondsSinceEpoch}';
      final started = await _voiceService.startRecording(fileId);
      if (!mounted) return;
      if (!started) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.tr(
                'Sila benarkan akses mikrofon untuk merakam suara.',
                'Please allow microphone permission to record voice notes.',
              ),
            ),
            backgroundColor: _mochaPrimary,
          ),
        );
        return;
      }
      _activeRecordingFileId = fileId;
      _recordTimer?.cancel();
      setState(() {
        _isRecording = true;
        _recordSeconds = 1;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => _recordSeconds++);
      });
    } else {
      HapticFeedback.mediumImpact();
      _recordTimer?.cancel();
      final duration = _recordSeconds.clamp(1, 300);
      final fileId =
          _activeRecordingFileId ?? 'chat_${DateTime.now().millisecondsSinceEpoch}';
      _activeRecordingFileId = null;
      setState(() {
        _isRecording = false;
        _recordSeconds = 0;
      });

      final audioUrl = await _voiceService.stopAndUpload(
        familyId: appState.family.id,
        folder: 'chat',
        fileId: fileId,
      );
      if (!mounted) return;

      final list = _messagesForChannel(
        _activeChannelId,
        appState.members,
        strings,
      );
      setState(() {
        list.add({
          'id': 'v_${DateTime.now().millisecondsSinceEpoch}',
          'senderMs': activeMember.name,
          'senderEn': activeMember.name,
          'avatar': activeMember.avatarEmoji,
          'isMe': true,
          'textMs': 'Pesanan Suara',
          'textEn': 'Voice Note',
          'time': strings.tr('Baru sahaja', 'Just now'),
          'isVoice': true,
          'durationSec': duration,
          'audioUrl': audioUrl,
        });
      });
      ref.read(eratControllerProvider.notifier).sendMessage(
            channel: _activeChannelId,
            content: 'Voice Note',
            isAudioVoiceNote: true,
            audioDuration: _formatDuration(duration),
            audioUrl: audioUrl,
          );
      _scrollToBottom();
    }
  }

  void _cancelRecording() {
    HapticFeedback.selectionClick();
    _recordTimer?.cancel();
    _activeRecordingFileId = null;
    _voiceService.cancelRecording();
    setState(() {
      _isRecording = false;
      _recordSeconds = 0;
    });
  }

  void _sendMessage([String? quickText]) {
    final strings = ref.read(appStringsProvider);
    final appState = ref.read(eratControllerProvider);
    final activeMember = appState.activeMember;
    final text = (quickText ?? _messageCtrl.text).trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    final list = _messagesForChannel(
      _activeChannelId,
      appState.members,
      strings,
    );
    setState(() {
      list.add({
        'id': 'm_${DateTime.now().millisecondsSinceEpoch}',
        'senderMs': activeMember.name,
        'senderEn': activeMember.name,
        'avatar': activeMember.avatarEmoji,
        'isMe': true,
        'textMs': text,
        'textEn': text,
        'time': strings.tr('Baru sahaja', 'Just now'),
        'isVoice': false,
      });
      if (quickText == null) {
        _messageCtrl.clear();
      }
    });
    ref.read(eratControllerProvider.notifier).sendMessage(
          channel: _activeChannelId,
          content: text,
        );
    _scrollToBottom();
  }

  String _formatDuration(int sec) {
    final m = sec ~/ 60;
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _activeRoomDescription(
    List<FamilyMember> members,
    FamilyMember activeMember,
    AppStrings strings,
  ) {
    if (_activeChannelId == 'family_group') {
      return strings.tr(
        'Kumpulan Keluarga • Ibu Bapa & Anak-anak',
        'Family Group • Parents & Kids',
      );
    }
    if (_activeChannelId == 'siblings_group') {
      return (!activeMember.isParentOrGuardian && activeMember.ageYears < 13)
          ? strings.tr(
              'Ruang Adik-Beradik • Dipantau Ibu Bapa (< 13 thn)',
              'Siblings Group • Parent-Guided Safe Space (< 13y)',
            )
          : strings.tr(
              'Ruang Adik-Beradik • Kongsi cerita & semangat',
              'Siblings Group • Share stories & cheer together',
            );
    }
    if (_activeChannelId.startsWith('dm_')) {
      final targetId = _activeChannelId.substring(3);
      final target = members.where((m) => m.id == targetId).firstOrNull;
      if (target != null) {
        final name = _localizedMemberName(target.name, strings);
        return strings.tr(
          'Sembang Peribadi bersama $name',
          'Direct Personal Chat with $name',
        );
      }
    }
    return strings.tr(
      'Ruang selamat bertukar pesan, kasih & nota suara',
      'A safe space to share love, notes & voice messages',
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(eratControllerProvider);
    final strings = ref.watch(appStringsProvider);
    final activeMember = appState.activeMember;
    final otherMembers =
        appState.members.where((m) => m.id != activeMember.id).toList();

    // If switched profile matches current DM target OR parent opened siblings group, fall back to family_group
    if (_activeChannelId == 'dm_${activeMember.id}' ||
        (activeMember.isParentOrGuardian &&
            _activeChannelId == 'siblings_group')) {
      _activeChannelId = 'family_group';
    }

    final activeMessages = _messagesForChannel(
      _activeChannelId,
      appState.members,
      strings,
    );

    final quickReplies = [
      strings.tr('❤️ Sayang semua', '❤️ Love you'),
      strings.tr('👍 Baik!', '👍 Got it!'),
      strings.tr('🌟 Dah siap!', '🌟 All done!'),
      strings.tr('🙏 Terima kasih', '🙏 Thank you'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final horizontalPad = isTablet ? 28.0 : 18.0;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 760 : double.infinity,
            ),
            child: Column(
              children: [
                // 1. Compact Header + Active Room Context
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    12,
                    horizontalPad,
                    8,
                  ),
                  child: Column(
                    children: [
                      Text(
                        strings.tr('Sembang Keluarga', 'Family Chat'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: CozyTheme.textDark,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _activeRoomDescription(
                          appState.members,
                          activeMember,
                          strings,
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _warmCocoa,
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Multi-Channel Selector Strip (Family Group | Siblings | 1-on-1 Direct Members)
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                    children: [
                      _buildChannelChip(
                        channelId: 'family_group',
                        emoji: '🏠',
                        label: strings.tr('Keluarga', 'Family Group'),
                      ),
                      if (!activeMember.isParentOrGuardian) ...[
                        const SizedBox(width: 8),
                        _buildChannelChip(
                          channelId: 'siblings_group',
                          emoji: '👧👦',
                          label: strings.tr('Adik-Beradik', 'Siblings'),
                        ),
                      ],
                      const SizedBox(width: 8),
                      // Subtle vertical divider between Groups & 1-on-1 Direct Chats
                      Center(
                        child: Container(
                          width: 1,
                          height: 24,
                          color: _blushBorder,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...otherMembers.map((member) {
                        final shortName = _localizedMemberName(
                          member.name,
                          strings,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildChannelChip(
                            channelId: 'dm_${member.id}',
                            emoji: member.avatarEmoji,
                            customPhotoPath: member.customPhotoPath,
                            label: shortName,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Divider(height: 1, color: _blushBorder),

                // 3. Scrollable Message List
                Expanded(
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding: EdgeInsets.fromLTRB(
                      horizontalPad,
                      12,
                      horizontalPad,
                      20,
                    ),
                    itemCount: activeMessages.length,
                    itemBuilder: (ctx, index) {
                      return _buildMessageRow(activeMessages[index], strings);
                    },
                  ),
                ),

                // 4. Quick-Reply Chips Strip (Child-friendly 1-tap responses)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    8,
                    horizontalPad,
                    6,
                  ),
                  decoration: const BoxDecoration(
                    color: CozyTheme.background,
                    border: Border(
                      top: BorderSide(color: _blushBorder, width: 1),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: quickReplies.map((reply) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              onTap: () => _sendMessage(reply),
                              hoverColor: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 38),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _blushBorder),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  reply,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: CozyTheme.textDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // 5. Bottom Input & Voice Recording Bar (≥ 44 × 44 pt touch targets)
                Container(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    8,
                    horizontalPad,
                    12,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: _blushBorder, width: 1),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: _isRecording
                        ? _buildRecordingBar(strings)
                        : _buildInputBar(strings),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChannelChip({
    required String channelId,
    required String emoji,
    required String label,
    String? customPhotoPath,
  }) {
    final isSelected = _activeChannelId == channelId;
    return Material(
      color: isSelected ? _mochaPrimary : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => _selectChannel(channelId),
        hoverColor: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? _mochaPrimary : _blushBorder,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (customPhotoPath != null && customPhotoPath.isNotEmpty)
                ClipOval(
                  child: MediaStorageService.buildAdaptiveImage(
                    customPhotoPath,
                    width: 22,
                    height: 22,
                    fit: BoxFit.cover,
                    placeholder: Text(emoji, style: const TextStyle(fontSize: 15)),
                  ),
                )
              else
                Text(emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  color: isSelected ? Colors.white : CozyTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageRow(Map<String, dynamic> msg, AppStrings strings) {
    final id = msg['id'] as String;
    final isMe = msg['isMe'] as bool;
    final isVoice = msg['isVoice'] as bool;
    final sender = strings.tr(
      msg['senderMs'] as String,
      msg['senderEn'] as String,
    );
    final text = strings.tr(
      msg['textMs'] as String,
      msg['textEn'] as String,
    );
    final time = msg['time'] as String;
    final durationSec = (msg['durationSec'] as int?) ?? 14;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _blushSurface,
                shape: BoxShape.circle,
                border: Border.all(color: _blushBorder),
              ),
              alignment: Alignment.center,
              child: Text(
                msg['avatar'] as String,
                style: const TextStyle(fontSize: 17),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 290),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isMe ? _mochaPrimary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 6),
                  bottomRight: Radius.circular(isMe ? 6 : 20),
                ),
                border: isMe ? null : Border.all(color: _blushBorder, width: 1.1),
                boxShadow: CozyTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Text(
                      sender,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _mochaPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (isVoice)
                    _buildVoiceNotePlayer(
                      voiceId: id,
                      durationSec: durationSec,
                      isMe: isMe,
                      caption: text,
                      audioUrl: msg['audioUrl'] as String?,
                    )
                  else
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isMe ? Colors.white : CozyTheme.textDark,
                        height: 1.38,
                      ),
                    ),
                  const SizedBox(height: 5),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.85)
                          : const Color(0xFF6E5B50),
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

  Widget _buildVoiceNotePlayer({
    required String voiceId,
    required int durationSec,
    required bool isMe,
    required String caption,
    String? audioUrl,
  }) {
    final isPlaying = _playingVoiceId == voiceId;
    final progress =
        isPlaying ? (_playSeconds / durationSec).clamp(0.0, 1.0) : 0.0;
    const barHeights = [
      8.0, 16.0, 12.0, 22.0, 14.0, 20.0, 10.0,
      18.0, 14.0, 22.0, 12.0, 16.0, 9.0, 15.0,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => _toggleVoicePlayback(
                voiceId,
                durationSec,
                audioUrl: audioUrl,
              ),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isMe ? Colors.white : _mochaPrimary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 24,
                  color: isMe ? _mochaPrimary : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(barHeights.length, (i) {
                  final barPos = (i + 1) / barHeights.length;
                  final active = isPlaying && barPos <= progress;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 3.5,
                    height: barHeights[i],
                    decoration: BoxDecoration(
                      color: isMe
                          ? (active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.45))
                          : (active ? _mochaPrimary : _blushBorder),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              isPlaying
                  ? _formatDuration(_playSeconds)
                  : _formatDuration(durationSec),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isMe ? Colors.white : _mochaPrimary,
              ),
            ),
          ],
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            caption,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isMe ? Colors.white.withValues(alpha: 0.9) : _warmCocoa,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputBar(AppStrings strings) {
    return Row(
      children: [
        Material(
          color: _blushSurface,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () => _toggleVoiceRecording(strings),
            customBorder: const CircleBorder(),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _mochaPrimary.withValues(alpha: 0.35),
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.mic_rounded,
                size: 22,
                color: _mochaPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 46),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _linenSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _blushBorder),
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: _messageCtrl,
              onSubmitted: (_) => _sendMessage(),
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                fontSize: 14,
                color: CozyTheme.textDark,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: strings.tr(
                  'Tulis pesanan...',
                  'Write a message...',
                ),
                hintStyle: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF7A675D),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: _mochaPrimary,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () => _sendMessage(),
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                Icons.arrow_upward_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingBar(AppStrings strings) {
    return Row(
      children: [
        IconButton(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          tooltip: strings.tr('Batal', 'Cancel'),
          onPressed: _cancelRecording,
          style: IconButton.styleFrom(backgroundColor: _linenSurface),
          icon: const Icon(Icons.delete_outline_rounded, color: _warmCocoa),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.fiber_manual_record_rounded,
                  size: 14,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.tr(
                      'Merakam... ${_formatDuration(_recordSeconds)}',
                      'Recording... ${_formatDuration(_recordSeconds)}',
                    ),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: _mochaPrimary,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () => _toggleVoiceRecording(strings),
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                Icons.send_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
