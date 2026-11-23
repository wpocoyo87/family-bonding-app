import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/erat_models.dart';
import '../../../core/providers/erat_providers.dart';
import '../../../core/theme/erat_palette.dart';

class FamilyCallScreen extends ConsumerStatefulWidget {
  final bool isVideoCall;
  final String participantName;
  final String participantAvatarAsset;
  final String participantAvatarEmoji;
  final String channelName;

  const FamilyCallScreen({
    super.key,
    required this.isVideoCall,
    required this.participantName,
    required this.participantAvatarAsset,
    required this.participantAvatarEmoji,
    required this.channelName,
  });

  @override
  ConsumerState<FamilyCallScreen> createState() => _FamilyCallScreenState();
}

class _FamilyCallScreenState extends ConsumerState<FamilyCallScreen>
    with SingleTickerProviderStateMixin {
  // Call States: 'calling', 'connected', 'ended'
  String _callStatus = 'calling';
  int _secondsElapsed = 0;
  Timer? _callTimer;
  Timer? _connectTimer;

  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isCameraOff = false;
  bool _isFrontCamera = true;
  String? _selectedArFilter; // e.g. '🐱', '👑', '⭐', '❤️', '🍕'

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Simulate network ring connection (connects in 2.2 seconds)
    _connectTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          _callStatus = 'connected';
        });
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _connectTimer?.cancel();
    _callTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _endCall() {
    _callTimer?.cancel();
    _connectTimer?.cancel();
    setState(() => _callStatus = 'ended');

    final durationStr = _formatDuration(_secondsElapsed);
    final callTypeStr = widget.isVideoCall ? 'Panggilan Video' : 'Panggilan Suara';

    // Log call duration message to WhatsApp thread
    ref.read(eratControllerProvider.notifier).sendMessage(
          channel: widget.channelName,
          content: '📞 $callTypeStr Tamat ($durationStr)',
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        content: Text('🔴 $callTypeStr tamat • Tempoh: $durationStr'),
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final activeMember = ref.watch(eratControllerProvider).activeMember;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep navy call background
      body: SafeArea(
        child: Stack(
          children: [
            // 1. MAIN BACKGROUND: Video Stream View or Audio Glow View
            if (widget.isVideoCall && !_isCameraOff)
              _buildVideoCallStream()
            else
              _buildVoiceCallBackdrop(),

            // 2. AR FILTER OVERLAY FOR KIDS (e.g. Floating Cat Ears / Hearts)
            if (_selectedArFilter != null && widget.isVideoCall)
              _buildArFilterOverlay(),

            // 3. TOP BAR: Participant Name, Call Status & Live Timer
            Positioned(
              top: 16,
              left: 20,
              right: 20,
              child: _buildTopCallHeader(),
            ),

            // 4. FLOATING PiP (Picture-in-Picture) LOCAL CAMERA FOR VIDEO CALL
            if (widget.isVideoCall && _callStatus == 'connected')
              Positioned(
                top: 80,
                right: 20,
                child: _buildLocalPiPWindow(activeMember),
              ),

            // 5. KIDS AR REACTION & STICKER DECK
            if (widget.isVideoCall && _callStatus == 'connected')
              Positioned(
                bottom: 120,
                left: 16,
                right: 16,
                child: _buildKidsArStickersBar(),
              ),

            // 6. BOTTOM ACTION CONTROLS (Mute, Speaker, Camera, End Call)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: _buildBottomControls(),
            ),
          ],
        ),
      ),
    );
  }

  /// 1A. Video Call Main Stream (Simulates remote camera feed of family member)
  Widget _buildVideoCallStream() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        image: DecorationImage(
          image: AssetImage(widget.participantAvatarAsset),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.15),
            BlendMode.darken,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.65),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.75),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }

  /// 1B. Voice Call Backdrop with Pulsating Ripple Soundwave
  Widget _buildVoiceCallBackdrop() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF312E81), Color(0xFF0F172A)],
          center: Alignment.center,
          radius: 0.9,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsating Ripple Avatar Ring
            AnimatedBuilder(
              animation: _pulseController,
              builder: (ctx, child) {
                final scale = 1.0 + (_pulseController.value * 0.12);
                final glow = _pulseController.value * 0.4;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Ripple
                    Container(
                      width: 170 * scale,
                      height: 170 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF818CF8).withValues(alpha: glow),
                      ),
                    ),
                    // Inner Ripple
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                      ),
                    ),
                    // Profile Avatar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Image.asset(
                        widget.participantAvatarAsset,
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 110,
                          height: 110,
                          color: EratPalette.primaryPurple,
                          alignment: Alignment.center,
                          child: Text(
                            widget.participantAvatarEmoji,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Soundwave Visualizer Bars (Moving when connected)
            if (_callStatus == 'connected')
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [8, 18, 28, 14, 32, 22, 12, 30, 24, 16, 26, 12, 8].map((h) {
                  return AnimatedBuilder(
                    animation: _pulseController,
                    builder: (ctx, child) {
                      final wave = (h * (0.7 + _pulseController.value * 0.6)).clamp(6.0, 36.0);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: 3.5,
                        height: wave,
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  /// 2. Kids Fun AR Face Filters Overlay (Cat ears, crown, star sparkles, hearts)
  Widget _buildArFilterOverlay() {
    return Positioned(
      top: 140,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedScale(
          scale: 1.1,
          duration: const Duration(milliseconds: 200),
          child: Column(
            children: [
              Text(
                _selectedArFilter!,
                style: const TextStyle(fontSize: 88),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Stiker AR Aktif ✨',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 3. Top Call Header (Participant Name & Live Status Timer)
  Widget _buildTopCallHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _callStatus == 'connected'
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.participantName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    _callStatus == 'calling'
                        ? 'Menghubungi... 📡'
                        : widget.isVideoCall
                            ? 'Panggilan Video HD • Internet Selamat'
                            : 'Panggilan Suara VoIP • Bersambung',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Timer Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _callStatus == 'calling' ? '00:00' : _formatDuration(_secondsElapsed),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Local Camera PiP Window (Shows Child / Caller in Corner)
  Widget _buildLocalPiPWindow(FamilyMember activeMember) {
    return Container(
      width: 95,
      height: 135,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              color: const Color(0xFF334155),
              child: Center(
                child: Text(
                  activeMember.avatarEmoji,
                  style: const TextStyle(fontSize: 42),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  activeMember.name.split(' ').first,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 5. Kids AR Reactions Bar (1-Tap Stickers to make calling fun for children!)
  Widget _buildKidsArStickersBar() {
    final filters = [
      (emoji: '🐱', label: 'Kucing'),
      (emoji: '👑', label: 'Mahkota'),
      (emoji: '⭐', label: 'Bintang'),
      (emoji: '💖', label: 'Kasih'),
      (emoji: '🍕', label: 'Pizza'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Text(
            'Stiker: ',
            style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
          ),
          ...filters.map((f) {
            final isSelected = _selectedArFilter == f.emoji;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedArFilter = isSelected ? null : f.emoji;
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? EratPalette.primaryPurple
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(f.emoji, style: const TextStyle(fontSize: 20)),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 6. Bottom Controls: Mute, Speaker, Camera Flip, End Call
  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Mute Mic Button
          _buildCircleButton(
            icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            isActive: _isMuted,
            activeColor: const Color(0xFFEF4444),
            tooltip: 'Mute Mikrofon',
            onTap: () {
              setState(() => _isMuted = !_isMuted);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isMuted ? 'Mikrofon dimatikan (Muted)' : 'Mikrofon aktif'),
                  duration: const Duration(milliseconds: 800),
                ),
              );
            },
          ),

          // Speakerphone Button
          _buildCircleButton(
            icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
            isActive: _isSpeakerOn,
            activeColor: const Color(0xFF38BDF8),
            tooltip: 'Pembesar Suara',
            onTap: () {
              setState(() => _isSpeakerOn = !_isSpeakerOn);
            },
          ),

          // Video Toggle Button (Only for Video Call)
          if (widget.isVideoCall) ...[
            _buildCircleButton(
              icon: _isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
              isActive: _isCameraOff,
              activeColor: const Color(0xFFEF4444),
              tooltip: 'Tutup / Buka Kamera',
              onTap: () {
                setState(() => _isCameraOff = !_isCameraOff);
              },
            ),
            _buildCircleButton(
              icon: Icons.flip_camera_ios_rounded,
              isActive: false,
              activeColor: Colors.white,
              tooltip: 'Tukar Kamera Depan / Belakang',
              onTap: () {
                setState(() => _isFrontCamera = !_isFrontCamera);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isFrontCamera ? 'Kamera Hadapan' : 'Kamera Belakang'),
                    duration: const Duration(milliseconds: 800),
                  ),
                );
              },
            ),
          ],

          // Giant Red End Call Button
          InkWell(
            onTap: _endCall,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.5),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.call_end_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? activeColor : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? activeColor : Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

