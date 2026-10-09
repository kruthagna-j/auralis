import 'dart:async';
import 'dart:io';

import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/audio_output_service.dart';

Future<void> showAudioOutputBottomSheet(
  BuildContext context, {
  required bool isDarkMode,
  required Color accentColor,
}) async {
  final devices = await AudioOutputService.getAudioDevices();
  final currentOutput = await AudioOutputService.getCurrentOutput();

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return AudioOutputModal(
        devices: devices,
        currentOutput: currentOutput,
        accentColor: accentColor,
        isDarkMode: isDarkMode,
      );
    },
  );
}

class AudioOutputModal extends StatefulWidget {
  final List<AudioOutputDevice> devices;
  final AudioOutputDevice currentOutput;
  final Color accentColor;
  final bool isDarkMode;

  const AudioOutputModal({
    Key? key,
    required this.devices,
    required this.currentOutput,
    required this.accentColor,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<AudioOutputModal> createState() => _AudioOutputModalState();
}

class _AudioOutputModalState extends State<AudioOutputModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late List<AudioOutputDevice> _devices;
  late AudioOutputDevice _currentOutput;
  bool _switching = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _devices = widget.devices;
    _currentOutput = widget.currentOutput;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshDevices(),
    );
  }

  Future<void> _refreshDevices() async {
    if (!mounted) return;
    final devices = await AudioOutputService.getAudioDevices();
    final currentOutput = await AudioOutputService.getCurrentOutput();
    if (!mounted) return;
    setState(() {
      _devices = devices;
      _currentOutput = currentOutput;
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _switchTo(AudioOutputDevice device) async {
    if (_switching) return;

    setState(() => _switching = true);
    await AudioOutputService.openMediaOutputSwitcher();
    if (mounted) {
      setState(() => _switching = false);
      await _refreshDevices();
    }
  }

  IconData _iconForPort(String port) {
    switch (port) {
      case 'receiver':
        return Icons.phone;
      case 'speaker':
        return Icons.volume_up;
      case 'headphones':
        return Icons.headphones;
      case 'bluetooth':
        return Icons.bluetooth;
      case 'usb':
        return Icons.usb;
      case 'hdmi':
        return Icons.tv;
      case 'hearing_aid':
        return Icons.hearing;
      default:
        return Icons.device_unknown;
    }
  }

  Future<void> _openSoundSettings() async {
    if (!Platform.isAndroid) {
      Navigator.pop(context);
      return;
    }
    await AudioOutputService.openSoundSettings();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final surface = MainScreenColors.getSurfaceColor(widget.isDarkMode);
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: DraggableScrollableSheet(
          initialChildSize: 0.38,
          minChildSize: 0.25,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: widget.isDarkMode
                      ? [
                          Colors.black.withValues(alpha: 0.6),
                          surface.withValues(alpha: 0.8),
                        ]
                      : [
                          surface.withValues(alpha: 0.95),
                          Colors.white.withValues(alpha: 0.9),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 6),
                          child: Container(
                            width: 36,
                            height: 5,
                            decoration: BoxDecoration(
                              color: widget.isDarkMode
                                  ? Colors.white24
                                  : Colors.black26,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'switch_audio_output'.tr(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: MainScreenColors.getTextColor(
                                          widget.isDarkMode,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'audio_output_sheet_instruction'.tr(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: MainScreenColors.getTextColor(
                                          widget.isDarkMode,
                                        ).withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.settings,
                                  color: widget.accentColor,
                                ),
                                onPressed: _openSoundSettings,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.only(
                              bottom: 20,
                              left: 8,
                              right: 8,
                              top: 6,
                            ),
                            itemCount: _devices.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final device = _devices[index];
                              final isCurrent = device.id == _currentOutput.id;
                              return InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: _switching
                                    ? null
                                    : () => _switchTo(device),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? widget.accentColor.withValues(
                                            alpha: 0.12,
                                          )
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(14),
                                    border: isCurrent
                                        ? Border.all(
                                            color: widget.accentColor
                                                .withValues(alpha: 0.18),
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: isCurrent
                                              ? widget.accentColor.withValues(
                                                  alpha: 0.18,
                                                )
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            _iconForPort(device.port),
                                            color: isCurrent
                                                ? widget.accentColor
                                                : MainScreenColors.getTextColor(
                                                    widget.isDarkMode,
                                                  ),
                                            size: 22,
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
                                              device.name.isNotEmpty
                                                  ? device.name
                                                  : (device.port == 'bluetooth'
                                                        ? 'Bluetooth Device'
                                                        : 'Unknown Device'),
                                              style: GoogleFonts.poppins(
                                                fontSize: 15,
                                                fontWeight: isCurrent
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color:
                                                    MainScreenColors.getTextColor(
                                                      widget.isDarkMode,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              device.port[0].toUpperCase() +
                                                  device.port.substring(1),
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color:
                                                    MainScreenColors.getTextColor(
                                                      widget.isDarkMode,
                                                    ).withValues(alpha: 0.6),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isCurrent)
                                        Icon(
                                          Icons.check_circle,
                                          color: widget.accentColor,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
