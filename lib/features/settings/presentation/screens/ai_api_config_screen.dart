import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers/settings_provider.dart';
import '../widgets/settings_item.dart';
import '../../../../shared/components/app_snackbar.dart';

class AiApiConfigScreen extends StatefulWidget {
  const AiApiConfigScreen({Key? key}) : super(key: key);

  @override
  State<AiApiConfigScreen> createState() => _AiApiConfigScreenState();
}

class _AiApiConfigScreenState extends State<AiApiConfigScreen> {
  late TextEditingController _geminiApiKeyController;
  late TextEditingController _openAiApiKeyController;
  late String _selectedAiProvider;

  @override
  void initState() {
    super.initState();
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    _geminiApiKeyController = TextEditingController(
      text: settingsProvider.geminiApiKeyValue,
    );
    _openAiApiKeyController = TextEditingController(
      text: settingsProvider.openAiApiKeyValue,
    );
    _selectedAiProvider = settingsProvider.aiProvider;
  }

  @override
  void dispose() {
    _geminiApiKeyController.dispose();
    _openAiApiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = settingsProvider.accentColor;

    return Scaffold(
      backgroundColor: isDarkMode
          ? MainScreenColors.darkBackgroundColor
          : MainScreenColors.lightBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'ai_api_configuration'.tr(),
          style: AppTextStyles.appBarTitle(isDarkMode: isDarkMode),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: MainScreenColors.getTextColor(isDarkMode),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimens.paddingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsSectionHeader(
              title: 'select_ai_provider'.tr(),
              icon: Icons.cloud,
              isDarkMode: isDarkMode,
              accentColor: accentColor,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedAiProvider = 'Gemini';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedAiProvider == 'Gemini'
                          ? accentColor
                          : (isDarkMode
                                ? MainScreenColors.darkSurfaceColor
                                : MainScreenColors.lightSurfaceColor),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimens.paddingMd,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        side: BorderSide(
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.08),
                          width: AppDimens.borderWidthThin,
                        ),
                      ),
                      elevation: _selectedAiProvider == 'Gemini'
                          ? AppDimens.elevationMedium
                          : AppDimens.elevationNone,
                    ),
                    child: Text(
                      'Gemini'.tr(),
                      style: AppTextStyles.bodyMd(isDarkMode: isDarkMode)
                          .copyWith(
                            color: _selectedAiProvider == 'Gemini'
                                ? Colors.white
                                : MainScreenColors.getTextColor(isDarkMode),
                            fontWeight: AppTextStyles.weightSemiBold,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimens.spacingLg),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedAiProvider = 'OpenAI';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedAiProvider == 'OpenAI'
                          ? accentColor
                          : (isDarkMode
                                ? MainScreenColors.darkSurfaceColor
                                : MainScreenColors.lightSurfaceColor),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimens.paddingMd,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        side: BorderSide(
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.08),
                          width: AppDimens.borderWidthThin,
                        ),
                      ),
                      elevation: _selectedAiProvider == 'OpenAI'
                          ? AppDimens.elevationMedium
                          : AppDimens.elevationNone,
                    ),
                    child: Text(
                      'OpenAI'.tr(),
                      style: AppTextStyles.bodyMd(isDarkMode: isDarkMode)
                          .copyWith(
                            color: _selectedAiProvider == 'OpenAI'
                                ? Colors.white
                                : MainScreenColors.getTextColor(isDarkMode),
                            fontWeight: AppTextStyles.weightSemiBold,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.spacingLg),
            SettingsSectionHeader(
              title: '${_selectedAiProvider} API Key'.tr(),
              icon: Icons.vpn_key,
              isDarkMode: isDarkMode,
              accentColor: accentColor,
            ),
            Container(
              margin: const EdgeInsets.only(bottom: AppDimens.spacingSm),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? MainScreenColors.darkSurfaceColor
                    : MainScreenColors.lightSurfaceColor,
                borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                border: Border.all(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08),
                  width: AppDimens.borderWidthThin,
                ),
              ),
              child: TextField(
                cursorColor: accentColor,

                controller: _selectedAiProvider == 'Gemini'
                    ? _geminiApiKeyController
                    : _openAiApiKeyController,
                decoration: InputDecoration(
                  labelText: 'enter_your_api_key_here'.tr(),
                  labelStyle: GoogleFonts.poppins(
                    color: MainScreenColors.getTextColor(
                      isDarkMode,
                    ).withValues(alpha: 0.7),
                  ),
                  hintText: 'e.g., sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
                  hintStyle: GoogleFonts.poppins(
                    color: MainScreenColors.getTextColor(
                      isDarkMode,
                    ).withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.paddingMd,
                    vertical: AppDimens.spacingSmMd,
                  ),
                ),
                style: AppTextStyles.bodyMd(
                  isDarkMode: isDarkMode,
                ).copyWith(fontWeight: AppTextStyles.weightMedium),
              ),
            ),
            const SizedBox(height: AppDimens.spacingXl),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  final geminiKey = _geminiApiKeyController.text.trim();
                  final openAiKey = _openAiApiKeyController.text.trim();

                  if (_selectedAiProvider == 'Gemini' && geminiKey.isEmpty) {
                    AppSnackBar.showError(
                      context,
                      'gemini_api_key_cannot_be_empty'.tr(),
                    );
                    return;
                  }

                  if (_selectedAiProvider == 'OpenAI' && openAiKey.isEmpty) {
                    AppSnackBar.showError(
                      context,
                      'openai_api_key_cannot_be_empty'.tr(),
                    );
                    return;
                  }

                  settingsProvider.geminiApiKeyValue = geminiKey;
                  settingsProvider.openAiApiKeyValue = openAiKey;
                  settingsProvider.aiProvider = _selectedAiProvider;
                  AppSnackBar.showSuccess(
                    context,
                    'api_key_and_ai_provider_saved'.tr(),
                    accentColor: accentColor,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spacingXxl,
                    vertical: AppDimens.paddingMd,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                  elevation: AppDimens.elevationMedium,
                ),
                child: Text('save_api_key'.tr(), style: AppTextStyles.button()),
              ),
            ),
            const SizedBox(height: 18),
            SettingsSectionHeader(
              title: '${_selectedAiProvider} API Key Documentation'.tr(),
              icon: Icons.description,
              isDarkMode: isDarkMode,
              accentColor: accentColor,
            ),
            _buildApiDocumentation(isDarkMode, accentColor),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildApiDocumentation(bool isDarkMode, Color accentColor) {
    List<String> steps = [];
    String url = '';

    if (_selectedAiProvider == 'Gemini') {
      steps = [
        '1. Go to the Google AI Studio API Key page.',
        '2. Sign in with your Google account.',
        '3. Click "Create API key in new project" or "Create API key" if you have an existing project.',
        '4. Copy the generated API key and paste it above.',
      ];
      url = 'https://aistudio.google.com/app/apikey';
    } else if (_selectedAiProvider == 'OpenAI') {
      steps = [
        '1. Go to the OpenAI API Keys page.',
        '2. Log in to your OpenAI account.',
        '3. Click "+ Create new secret key".',
        '4. Copy the generated API key and paste it above.',
      ];
      url = 'https://platform.openai.com/account/api-keys';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.spacingSm),
      padding: const EdgeInsets.all(AppDimens.paddingLg),
      decoration: BoxDecoration(
        color: isDarkMode
            ? MainScreenColors.darkSurfaceColor
            : MainScreenColors.lightSurfaceColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
          width: AppDimens.borderWidthThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...steps.map(
            (step) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.spacingSm),
              child: Text(
                step.tr(),
                style: AppTextStyles.bodyMd(isDarkMode: isDarkMode),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _launchURL(url),
              child: Text(
                'Go to API Page'.tr(),
                style: AppTextStyles.bodyMd(isDarkMode: isDarkMode).copyWith(
                  color: accentColor,
                  fontWeight: AppTextStyles.weightSemiBold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      AppSnackBar.showError(context, 'Could not launch $url'.tr());
    }
  }
}
