import 'package:flutter/material.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/voice_search_service.dart';

class VoiceSearchOverlay extends StatefulWidget {
  final VoiceSearchService voiceSearchService;
  final Color accentColor;
  final bool isDarkMode;
  final VoidCallback onClose;

  const VoiceSearchOverlay({
    Key? key,
    required this.voiceSearchService,
    required this.accentColor,
    required this.isDarkMode,
    required this.onClose,
  }) : super(key: key);

  @override
  State<VoiceSearchOverlay> createState() => _VoiceSearchOverlayState();
}

class _VoiceSearchOverlayState extends State<VoiceSearchOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.voiceSearchService,
      builder: (context, _) {
        final state = widget.voiceSearchService.state;
        final lastWords = widget.voiceSearchService.lastWords;
        final soundLevel = widget.voiceSearchService.soundLevel;
        final errorMessage = widget.voiceSearchService.errorMessage;

        return SizedBox.expand(
          child: Material(
            color: Colors.black.withValues(alpha: 0.9),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (lastWords.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        lastWords,
                        style: AppTextStyles.titleLg(
                          isDarkMode: true,
                        ).copyWith(color: Colors.white, fontSize: 24),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else if (state == VoiceSearchState.listening)
                    Text(
                      'Listening...',
                      style: AppTextStyles.subtitle(
                        isDarkMode: true,
                      ).copyWith(color: Colors.white70, fontSize: 20),
                    )
                  else if (state == VoiceSearchState.initializing)
                    Text(
                      'Initializing...',
                      style: AppTextStyles.subtitle(
                        isDarkMode: true,
                      ).copyWith(color: Colors.white70, fontSize: 20),
                    )
                  else if (state == VoiceSearchState.error ||
                      state == VoiceSearchState.permissionDenied)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        errorMessage,
                        style: AppTextStyles.subtitle(
                          isDarkMode: true,
                        ).copyWith(color: Colors.redAccent, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 48),

                  _buildMicButton(state, soundLevel),

                  const SizedBox(height: 32),

                  if (state == VoiceSearchState.listening)
                    Text(
                      'Tap to stop',
                      style: AppTextStyles.caption(
                        isDarkMode: true,
                      ).copyWith(color: Colors.white54),
                    ),

                  if (state == VoiceSearchState.permissionDenied) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => widget.voiceSearchService.openSettings(),
                      child: Text(
                        'Open Settings',
                        style: TextStyle(
                          color: widget.accentColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 32,
                    ),
                    onPressed: () async {
                      await widget.voiceSearchService.cancelListening();
                      widget.onClose();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMicButton(VoiceSearchState state, double soundLevel) {
    final isListening = state == VoiceSearchState.listening;
    final normalizedLevel = ((soundLevel + 2) / 12).clamp(0.0, 1.0);
    final rippleSize = 80.0 + (normalizedLevel * 60.0);

    return GestureDetector(
      onTap: () async {
        if (isListening) {
          await widget.voiceSearchService.stopListening();
        }
      },
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isListening)
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: rippleSize * 2,
                height: rippleSize * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.accentColor.withValues(alpha: 0.1),
                ),
              ),
            if (isListening)
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: rippleSize * 1.5,
                height: rippleSize * 1.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.accentColor.withValues(alpha: 0.2),
                ),
              ),
            if (isListening)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.accentColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isListening ? widget.accentColor : Colors.white24,
                boxShadow: isListening
                    ? [
                        BoxShadow(
                          color: widget.accentColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 36,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
