import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/providers/player_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../data/services/equalizer_services.dart';
import '../widgets/volume_circular_slider.dart';
import '../widgets/speech_circular_slider.dart';
import '../widgets/equalizer_band_slider.dart';
import '../widgets/equalizer_curve_graph.dart';
import '../../../settings/presentation/widgets/settings_item.dart';
import '../../../../shared/components/app_snackbar.dart';

class EqualizerScreen extends StatefulWidget {
  final bool openedFromPlayer;

  const EqualizerScreen({Key? key, this.openedFromPlayer = false})
    : super(key: key);

  @override
  _EqualizerScreenState createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen>
    with SingleTickerProviderStateMixin {
  late EqualizerService _equalizerService;
  bool _serviceReady = false;
  EqualizerParameters? _params;
  late AnimationController _animationController;
  bool _isEnabled = false;
  String _currentPreset = 'Auralis';
  bool _isLoading = false;
  bool _isCurveMode = false;

  Map<String, List<double>> _presets = {};
  Set<String> _customPresetNames = {};

  final ScrollController _presetScrollController = ScrollController();
  Map<String, GlobalKey> _presetKeys = {};

  Future<void> _loadPresets() async {
    final all = await _equalizerService.getAllPresets();
    setState(() {
      _presets = all;
      _customPresetNames = all.keys
          .where((k) => !EqualizerService.builtInPresets.containsKey(k))
          .toSet();

      final existing = _presetKeys;
      _presetKeys = {for (var k in all.keys) k: existing[k] ?? GlobalKey()};
    });

    _ensureCurrentPresetVisible();
  }

  Future<void> _saveCurrentAsPresetPrompt() async {
    final params = await _equalizerService.getEqualizerParameters();
    final bandGains = params.bands.map((b) => b.gain).toList();

    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final settingsProvider = Provider.of<SettingsProvider>(context);
        final accentColor = settingsProvider.accentColor;
        return AlertDialog(
          backgroundColor: MainScreenColors.getSurfaceColor(isDarkMode),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          ),
          title: Text(
            'save_preset'.tr(),
            style: TextStyle(color: MainScreenColors.getTextColor(isDarkMode)),
          ),
          content: TextField(
            controller: controller,
            cursorColor: accentColor,
            decoration: InputDecoration(
              hintText: 'preset_name'.tr(),
              hintStyle: TextStyle(color: Colors.grey[500]),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: accentColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: accentColor, width: 2),
              ),
            ),
            style: TextStyle(color: MainScreenColors.getTextColor(isDarkMode)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr(), style: TextStyle(color: accentColor)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text('save'.tr(), style: TextStyle(color: accentColor)),
            ),
          ],
        );
      },
    );

    if (name != null && name.isNotEmpty) {
      await _equalizerService.saveCustomPreset(name, bandGains);
      await _loadPresets();
      setState(() => _currentPreset = name);
      _ensureCurrentPresetVisible();
    }
  }

  Future<void> _renamePresetPrompt(String oldName) async {
    final controller = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final settingsProvider = Provider.of<SettingsProvider>(context);
        final accentColor = settingsProvider.accentColor;
        return AlertDialog(
          backgroundColor: MainScreenColors.getSurfaceColor(isDarkMode),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          ),
          title: Text(
            'rename_preset'.tr(),
            style: TextStyle(color: MainScreenColors.getTextColor(isDarkMode)),
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'new_name'.tr(),
              hintStyle: TextStyle(color: Colors.grey[500]),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: accentColor),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: accentColor, width: 2),
              ),
            ),
            style: TextStyle(color: MainScreenColors.getTextColor(isDarkMode)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr(), style: TextStyle(color: accentColor)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text('rename'.tr(), style: TextStyle(color: accentColor)),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.isNotEmpty && newName != oldName) {
      final ok = await _equalizerService.renameCustomPreset(oldName, newName);
      if (ok) {
        await _loadPresets();
        setState(() => _currentPreset = newName);
        _ensureCurrentPresetVisible();
      } else {
        AppSnackBar.showError(context, 'name_already_exists'.tr());
      }
    }
  }

  final Map<String, String> _presetDescriptions = {
    'Auralis': 'Preset from creator of Auralis',
    'Flat': 'Balanced sound across all frequencies',
    'Classical': 'Enhanced mids and highs for orchestral clarity',
    'Dance': 'Boosted bass and treble for electronic music',
    'Vocal Boost': 'Clearer vocals with upper mids emphasis',
    'Hip-Hop': 'Deep bass and punchy low mids for beats',
    'Acoustic': 'Natural, warm tones for unplugged music',
    'Treble Boost': 'Crisp highs and detail in vocals and cymbals',
    'Jazz': 'Balanced mids with subtle bass and treble',
    'Pop': 'Slight boost to bass and higher frequencies',
    'Rock': 'Enhanced low mids and high end for energy',
    'Bass Boost': 'Enhanced low frequencies for powerful bass',
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();

    if (GetIt.I.isRegistered<EqualizerService>()) {
      _equalizerService = GetIt.I<EqualizerService>();
      _initializeAudioControls();
    } else {
      Future.microtask(() async {
        while (!GetIt.I.isRegistered<EqualizerService>()) {
          await Future.delayed(const Duration(milliseconds: 50));
        }
        if (!mounted) return;
        _equalizerService = GetIt.I<EqualizerService>();
        _initializeAudioControls();
      });
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _presetScrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeAudioControls() async {
    setState(() => _isLoading = true);

    try {
      _params = await _equalizerService.getEqualizerParameters();

      _isEnabled = _equalizerService.equalizerEnabled;
      _currentPreset = _equalizerService.currentPreset;

      await _loadPresets();
    } catch (e) {
      debugPrint('Error initializing audio controls: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _serviceReady = true;
      });
    }
  }

  void _toggleEqualizer(bool value) async {
    await _equalizerService.setEqualizerEnabled(value);
    setState(() => _isEnabled = value);
  }

  void _applyPreset(String preset) async {
    try {
      setState(() => _isLoading = true);
      await _equalizerService.applyPreset(preset);
      final updated = await _equalizerService.getEqualizerParameters();
      setState(() {
        _currentPreset = preset;
        _params = updated;
        _isLoading = false;
      });

      _ensureCurrentPresetVisible();
    } catch (e) {
      setState(() => _isLoading = false);
      AppSnackBar.showError(context, 'error_applying_preset'.tr());
    }
  }

  Future<void> _onBandGainChanged(int index, double value) async {
    final current = _params;
    if (current == null || index < 0 || index >= current.bands.length) return;

    final updatedBands = List<EqualizerBandDescriptor>.from(current.bands);
    updatedBands[index] = updatedBands[index].copyWith(gain: value);

    setState(() {
      _params = EqualizerParameters(
        minDecibels: current.minDecibels,
        maxDecibels: current.maxDecibels,
        bands: updatedBands,
      );
    });

    await _equalizerService.setBandGain(index, value);
    if (_customPresetNames.contains(_currentPreset)) {
      final bandGains = updatedBands.map((b) => b.gain).toList();
      await _equalizerService.saveCustomPreset(_currentPreset, bandGains);
      await _loadPresets();
    }
  }

  void _ensureCurrentPresetVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _presetKeys[_currentPreset];
      if (key != null && key.currentContext != null) {
        try {
          Scrollable.ensureVisible(
            key.currentContext!,
            duration: const Duration(milliseconds: 300),
            alignment: 0.5,
            curve: Curves.easeInOut,
          );
        } catch (e) {}
      } else {
        final keysList = _presets.keys.toList();
        final idx = keysList.indexOf(_currentPreset);
        if (idx >= 0 && _presetScrollController.hasClients) {
          final approxItemWidth = AppDimens.headerImageSm;
          final targetOffset = (idx * (approxItemWidth + AppDimens.spacingSm))
              .clamp(0.0, _presetScrollController.position.maxScrollExtent);
          _presetScrollController.animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final accentColor = settingsProvider.accentColor;
    final pageBackground = MainScreenColors.getBackgroundColor(isDarkMode);

    final screen = Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: widget.openedFromPlayer
          ? Colors.transparent
          : pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.openedFromPlayer
            ? IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                color: MainScreenColors.getTextColor(isDarkMode),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Equalizer',
          style: AppTextStyles.appBarTitle(isDarkMode: isDarkMode),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            color: accentColor,
            onPressed: _isEnabled ? _saveCurrentAsPresetPrompt : null,
            tooltip: 'save_preset'.tr(),
          ),
          SizedBox(width: AppDimens.spacingSm),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: SettingsToggle(
              value: _isEnabled,
              onChanged: _toggleEqualizer,
              accentColor: accentColor,
              isDarkMode: isDarkMode,
            ),
          ),
        ],
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, playerProvider, _) {
          if (!_serviceReady) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            );
          }

          return Stack(
            children: [
              SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Curves.easeOut,
                      ),
                    ),
                child: FadeTransition(
                  opacity: _animationController,
                  child: Column(
                    children: [
                      AnimatedOpacity(
                        opacity: _isEnabled ? 1.0 : 0.3,
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          children: [
                            Container(
                              height: 32.0,
                              margin: EdgeInsets.symmetric(
                                vertical: AppDimens.spacingSm,
                              ),
                              child: ListView.builder(
                                controller: _presetScrollController,
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppDimens.paddingLg,
                                ),
                                itemCount: _presets.length,
                                itemBuilder: (context, index) {
                                  final preset = _presets.keys.elementAt(index);
                                  final isCustom = _customPresetNames.contains(
                                    preset,
                                  );

                                  final presetKey = _presetKeys.putIfAbsent(
                                    preset,
                                    () => GlobalKey(),
                                  );

                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right: AppDimens.spacingSm,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _isEnabled
                                            ? () => _applyPreset(preset)
                                            : null,
                                        onLongPress: isCustom
                                            ? () => _renamePresetPrompt(preset)
                                            : null,
                                        borderRadius: BorderRadius.circular(
                                          AppDimens.radiusXxl,
                                        ),
                                        child: Container(
                                          key: presetKey,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: AppDimens.paddingLg,
                                            vertical: AppDimens.spacingXxs,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              AppDimens.radiusXxl,
                                            ),
                                            border: Border.all(
                                              color: _currentPreset == preset
                                                  ? accentColor
                                                  : Colors.grey[700]!,
                                              width: 1.5,
                                            ),
                                            color: _currentPreset == preset
                                                ? accentColor.withValues(
                                                    alpha: 0.2,
                                                  )
                                                : Colors.transparent,
                                          ),
                                          child: Center(
                                            child: Text(
                                              preset,
                                              style:
                                                  AppTextStyles.caption(
                                                    isDarkMode: isDarkMode,
                                                  ).copyWith(
                                                    color:
                                                        _currentPreset == preset
                                                        ? accentColor
                                                        : MainScreenColors.getTextColor(
                                                            isDarkMode,
                                                          ),
                                                    fontWeight: AppTextStyles
                                                        .weightBold,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppDimens.paddingLg,
                                ),
                                child: Text(
                                  _presetDescriptions[_currentPreset] ?? '',
                                  key: ValueKey(_currentPreset),
                                  style: AppTextStyles.bodyMd(
                                    isDarkMode: isDarkMode,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppDimens.spacing5Xl),

                      Expanded(
                        child: AnimatedOpacity(
                          opacity: _isEnabled ? 1.0 : 0.3,
                          duration: const Duration(milliseconds: 200),
                          child: _params == null
                              ? Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      accentColor,
                                    ),
                                  ),
                                )
                              : Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppDimens.paddingLg,
                                  ),
                                  child: _isCurveMode
                                      ? Column(
                                          children: [
                                            Expanded(
                                              child: Center(
                                                child: EqualizerCurveGraph(
                                                  params: _params!,
                                                  accentColor: accentColor,
                                                  isDarkMode: isDarkMode,
                                                  isEnabled: _isEnabled,
                                                  onBandChanged: (entry) =>
                                                      _onBandGainChanged(
                                                        entry.key,
                                                        entry.value,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: AppDimens.paddingMd,
                                                vertical: AppDimens.spacingMd,
                                              ),
                                              child: SizedBox(
                                                height:
                                                    AppDimens.buttonSizeCompact,
                                                child: LayoutBuilder(
                                                  builder: (context, constraints) {
                                                    final bands =
                                                        _params!.bands;
                                                    final width =
                                                        constraints.maxWidth;
                                                    final denominator =
                                                        (bands.length - 1)
                                                            .clamp(1, 999);
                                                    return Stack(
                                                      children: List.generate(
                                                        bands.length,
                                                        (index) {
                                                          final x =
                                                              (width /
                                                                  denominator) *
                                                              index;
                                                          return Align(
                                                            alignment:
                                                                Alignment(
                                                                  ((x / width) *
                                                                          2) -
                                                                      1,
                                                                  0,
                                                                ),
                                                            child: Text(
                                                              EqualizerService.getFrequencyText(
                                                                bands[index]
                                                                    .centerFrequency,
                                                              ),
                                                              style:
                                                                  AppTextStyles.caption(
                                                                    isDarkMode:
                                                                        isDarkMode,
                                                                  ).copyWith(
                                                                    color: MainScreenColors.getTextColor(
                                                                      isDarkMode,
                                                                    ),
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: List.generate(
                                            _params!.bands.length,
                                            (index) {
                                              final band =
                                                  _params!.bands[index];
                                              return EqualizerBandSlider(
                                                gain: band.gain,
                                                minDecibels:
                                                    _params!.minDecibels,
                                                maxDecibels:
                                                    _params!.maxDecibels,
                                                centerFrequency:
                                                    band.centerFrequency,
                                                isEnabled: _isEnabled,
                                                onChanged: (v) =>
                                                    _onBandGainChanged(
                                                      index,
                                                      v,
                                                    ),
                                              );
                                            },
                                          ),
                                        ),
                                ),
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.only(bottom: AppDimens.spacingSm),
                        child: ToggleButtons(
                          isSelected: [!_isCurveMode, _isCurveMode],
                          onPressed: _isEnabled
                              ? (index) =>
                                    setState(() => _isCurveMode = index == 1)
                              : null,
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusFull,
                          ),
                          borderColor: Colors.grey[700],
                          selectedBorderColor: accentColor,
                          fillColor: accentColor.withValues(alpha: 0.15),
                          selectedColor: accentColor,
                          color: MainScreenColors.getTextColor(isDarkMode),
                          constraints: BoxConstraints(
                            minHeight: 28.0,
                            minWidth:
                                AppDimens.buttonSizeCompact +
                                AppDimens.spacingMd,
                          ),
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppDimens.paddingSm,
                              ),
                              child: Text(
                                'Sliders',
                                style:
                                    AppTextStyles.caption(
                                      isDarkMode: isDarkMode,
                                    ).copyWith(
                                      fontWeight: !_isCurveMode
                                          ? AppTextStyles.weightBold
                                          : AppTextStyles.weightRegular,
                                    ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppDimens.paddingSm,
                              ),
                              child: Text(
                                'Curve',
                                style:
                                    AppTextStyles.caption(
                                      isDarkMode: isDarkMode,
                                    ).copyWith(
                                      fontWeight: _isCurveMode
                                          ? AppTextStyles.weightBold
                                          : AppTextStyles.weightRegular,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: EdgeInsets.only(
                          left: AppDimens.paddingXxl,
                          right: AppDimens.paddingXxl,
                          top: AppDimens.paddingXxl,
                          bottom: AppDimens.paddingLg,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppDimens.radiusFull),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final maxChildWidth =
                                    constraints.maxWidth >=
                                        AppDimens.breakpointTabletShort
                                    ? AppDimens.chartHeight
                                    : (constraints.maxWidth -
                                              AppDimens.spacingMd) /
                                          2.0;

                                return Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: AppDimens.spacingMd,
                                  runSpacing: AppDimens.spacingMd,
                                  children: [
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: AppDimens.headerImageSm,
                                        maxWidth: maxChildWidth,
                                      ),
                                      child: SizedBox(
                                        width: maxChildWidth,
                                        child: const VolumeCircularSlider(),
                                      ),
                                    ),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: AppDimens.headerImageSm,
                                        maxWidth: maxChildWidth,
                                      ),
                                      child: SizedBox(
                                        width: maxChildWidth,
                                        child: const SpeechCircularSlider(),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.15),
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );

    return SafeArea(
      top: false,
      child: widget.openedFromPlayer
          ? ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimens.radiusXxl),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: pageBackground.withValues(alpha: 0.82),
                  child: screen,
                ),
              ),
            )
          : screen,
    );
  }
}
