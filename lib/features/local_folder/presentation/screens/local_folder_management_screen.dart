import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:math' as math;

import '../../../../core/providers/settings_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../shared/components/app_snackbar.dart';

class LocalFolderManagementScreen extends StatefulWidget {
  const LocalFolderManagementScreen({Key? key}) : super(key: key);

  @override
  _LocalFolderManagementScreenState createState() =>
      _LocalFolderManagementScreenState();
}

class _LocalFolderManagementScreenState
    extends State<LocalFolderManagementScreen> {
  bool _containsFolder(List<String> folders, String folder) {
    if (Platform.isWindows) {
      final normalizedFolder = folder.toLowerCase();
      return folders.any((f) => f.toLowerCase() == normalizedFolder);
    }
    return folders.contains(folder);
  }

  Future<void> _pickFolder(SettingsProvider settings, bool include) async {
    String? result = await FilePicker.getDirectoryPath();

    if (result != null) {
      setState(() {
        if (include) {
          if (_containsFolder(settings.excludedFolders, result)) {
            AppSnackBar.showWarning(
              context,
              'Folder already exists in excluded folders',
            );
            return;
          }

          if (!_containsFolder(settings.includedFolders, result)) {
            settings.includedFolders = [...settings.includedFolders, result];
          }
        } else {
          if (_containsFolder(settings.includedFolders, result)) {
            AppSnackBar.showWarning(
              context,
              'Folder already exists in included folders',
            );
            return;
          }

          if (!_containsFolder(settings.excludedFolders, result)) {
            settings.excludedFolders = [...settings.excludedFolders, result];
          }
        }
      });
    }
  }

  void _showAddExtensionDialog(SettingsProvider settings, bool include) {
    final controller = TextEditingController();
    final isDarkMode = settings.themeMode == ThemeMode.dark;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: isDarkMode
              ? MainScreenColors.darkSurfaceColor
              : MainScreenColors.lightSurfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusXl),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: math.min(
                560.0,
                MediaQuery.of(context).size.width * 0.92,
              ),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Padding(
                padding: EdgeInsets.all(AppDimens.paddingXxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'add_extension'.tr(),
                      style: AppTextStyles.titleLg(isDarkMode: isDarkMode),
                    ),
                    SizedBox(height: AppDimens.spacingXl),
                    TextField(
                      controller: controller,
                      cursorColor: settings.accentColor,

                      decoration: InputDecoration(
                        hintText: '.mp3',
                        hintStyle: AppTextStyles.body2(isDarkMode: isDarkMode)
                            .copyWith(
                              color: MainScreenColors.getTextColor(
                                isDarkMode,
                              ).withValues(alpha: 0.5),
                            ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusMd,
                          ),
                          borderSide: BorderSide(
                            color: MainScreenColors.getTextColor(
                              isDarkMode,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusMd,
                          ),
                          borderSide: BorderSide(color: settings.accentColor),
                        ),
                      ),
                      style: AppTextStyles.bodyMd(isDarkMode: isDarkMode),
                    ),
                    SizedBox(height: AppDimens.spacingXl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'cancel'.tr(),
                            style: AppTextStyles.bodyMd(
                              isDarkMode: isDarkMode,
                            ).copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        SizedBox(width: AppDimens.spacingSm),
                        ElevatedButton(
                          onPressed: () {
                            String extension = controller.text.trim();
                            if (extension.isNotEmpty &&
                                extension.startsWith('.')) {
                              final extLower = extension.toLowerCase();
                              if ((Platform.isWindows || Platform.isLinux) &&
                                  extLower == '.ogg') {
                                AppSnackBar.showWarning(
                                  context,
                                  '".ogg" files are not supported on Windows/Linux',
                                );
                              } else {
                                final includedExts = settings.includedExtensions
                                    .map((e) => e.toLowerCase())
                                    .toSet();
                                final excludedExts = settings.excludedExtensions
                                    .map((e) => e.toLowerCase())
                                    .toSet();

                                if (include &&
                                    excludedExts.contains(extLower)) {
                                  AppSnackBar.showWarning(
                                    context,
                                    'Extension already exists in excluded extensions',
                                  );
                                  Navigator.pop(context);
                                  return;
                                }

                                if (!include &&
                                    includedExts.contains(extLower)) {
                                  AppSnackBar.showWarning(
                                    context,
                                    'Extension already exists in included extensions',
                                  );
                                  Navigator.pop(context);
                                  return;
                                }

                                setState(() {
                                  if (include) {
                                    if (!includedExts.contains(extLower)) {
                                      settings.includedExtensions = [
                                        ...settings.includedExtensions,
                                        extLower,
                                      ];
                                    }
                                  } else {
                                    if (!excludedExts.contains(extLower)) {
                                      settings.excludedExtensions = [
                                        ...settings.excludedExtensions,
                                        extLower,
                                      ];
                                    }
                                  }
                                });
                              }
                            }
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: settings.accentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimens.radiusMd,
                              ),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDimens.paddingXl,
                              vertical: AppDimens.paddingMd,
                            ),
                          ),
                          child: Text(
                            'add'.tr(),
                            style: AppTextStyles.button(
                              color: MainScreenColors.getTextColor(!isDarkMode),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDarkMode = settingsProvider.themeMode == ThemeMode.dark;
    final accentColor = settingsProvider.accentColor;

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: isDarkMode
            ? MainScreenColors.darkBackgroundColor
            : MainScreenColors.lightBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'local_folder_management'.tr(),
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = AppDimens.settingsColumns(width);

            final foldersColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  title: 'folders'.tr(),
                  icon: Icons.folder,
                  isDarkMode: isDarkMode,
                  accentColor: accentColor,
                ),
                _buildFolderList(
                  'included_folders'.tr(),
                  settingsProvider.includedFolders,
                  (folder) {
                    settingsProvider.includedFolders = settingsProvider
                        .includedFolders
                        .where((f) => f != folder)
                        .toList();
                  },
                  () => _pickFolder(settingsProvider, true),
                  isDarkMode,
                  accentColor,
                ),
                SizedBox(height: AppDimens.spacingXl),
                _buildFolderList(
                  'excluded_folders'.tr(),
                  settingsProvider.excludedFolders,
                  (folder) {
                    settingsProvider.excludedFolders = settingsProvider
                        .excludedFolders
                        .where((f) => f != folder)
                        .toList();
                  },
                  () => _pickFolder(settingsProvider, false),
                  isDarkMode,
                  accentColor,
                ),
              ],
            );

            final extensionsColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  title: 'extensions'.tr(),
                  icon: Icons.extension,
                  isDarkMode: isDarkMode,
                  accentColor: accentColor,
                ),
                _buildExtensionList(
                  'included_extensions'.tr(),
                  settingsProvider.includedExtensions,
                  (extension) {
                    settingsProvider.includedExtensions = settingsProvider
                        .includedExtensions
                        .where((e) => e != extension)
                        .toList();
                  },
                  () => _showAddExtensionDialog(settingsProvider, true),
                  isDarkMode,
                  accentColor,
                ),
                SizedBox(height: AppDimens.spacingXl),
                _buildExtensionList(
                  'excluded_extensions'.tr(),
                  settingsProvider.excludedExtensions,
                  (extension) {
                    settingsProvider.excludedExtensions = settingsProvider
                        .excludedExtensions
                        .where((e) => e != extension)
                        .toList();
                  },
                  () => _showAddExtensionDialog(settingsProvider, false),
                  isDarkMode,
                  accentColor,
                ),
                Divider(height: AppDimens.spacing4Xl),
                _buildSectionHeader(
                  title: 'duration'.tr(),
                  icon: Icons.timelapse,
                  isDarkMode: isDarkMode,
                  accentColor: accentColor,
                ),
                SizedBox(height: AppDimens.spacingSmMd),
                Container(
                  padding: EdgeInsets.all(AppDimens.paddingLg),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? MainScreenColors.darkSurfaceColor
                        : MainScreenColors.lightSurfaceColor,
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'minimum_song_duration'.tr(),
                        style: AppTextStyles.subtitle(isDarkMode: isDarkMode),
                      ),
                      SizedBox(height: AppDimens.spacingSm),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: settingsProvider.minSongDuration
                                  .toDouble(),
                              min: 0,
                              max: 300,
                              divisions: 30,
                              label: '${settingsProvider.minSongDuration}s',
                              onChanged: (value) {
                                settingsProvider.minSongDuration = value
                                    .toInt();
                              },
                              activeColor: accentColor,
                              inactiveColor: MainScreenColors.getTextColor(
                                isDarkMode,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          SizedBox(width: AppDimens.spacingSm),
                          Text(
                            '${settingsProvider.minSongDuration}s',
                            style: AppTextStyles.bodyMd(isDarkMode: isDarkMode)
                                .copyWith(
                                  color: MainScreenColors.getTextColor(
                                    isDarkMode,
                                  ).withValues(alpha: 0.8),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );

            return SingleChildScrollView(
              padding: EdgeInsets.all(AppDimens.paddingLg),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppDimens.maxContentWidth,
                ),
                child: columns == 1
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          foldersColumn,
                          SizedBox(height: AppDimens.spacingXl),
                          extensionsColumn,
                          SizedBox(height: AppDimens.spacingXxxl),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 1, child: foldersColumn),
                          SizedBox(width: AppDimens.spacingLg),
                          Expanded(flex: 1, child: extensionsColumn),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required bool isDarkMode,
    required Color accentColor,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimens.spacingXs,
        AppDimens.spacingXxl,
        AppDimens.spacingXs,
        AppDimens.spacingMd,
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: AppDimens.iconMdLg),
          SizedBox(width: AppDimens.spacingSm),
          Text(title, style: AppTextStyles.titleSm(color: accentColor)),
        ],
      ),
    );
  }

  Widget _buildFolderList(
    String title,
    List<String> folders,
    Function(String) onRemove,
    VoidCallback onAdd,
    bool isDarkMode,
    Color accentColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? MainScreenColors.darkSurfaceColor
            : MainScreenColors.lightSurfaceColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimens.paddingLg,
              AppDimens.paddingLg,
              AppDimens.paddingSm,
              AppDimens.paddingSm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle(isDarkMode: isDarkMode),
                ),
                IconButton(
                  icon: Icon(Icons.add, color: accentColor),
                  onPressed: onAdd,
                ),
              ],
            ),
          ),
          folders.isEmpty
              ? Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDimens.paddingLg,
                    0,
                    AppDimens.paddingLg,
                    AppDimens.paddingMd,
                  ),
                  child: Text(
                    'no_folders_added'.tr(),
                    style: AppTextStyles.body2(isDarkMode: isDarkMode).copyWith(
                      color: MainScreenColors.getTextColor(
                        isDarkMode,
                      ).withValues(alpha: 0.7),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    return ListTile(
                      leading: Icon(
                        Icons.folder,
                        color: MainScreenColors.getTextColor(isDarkMode),
                      ),
                      title: Text(
                        folder,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMd(isDarkMode: isDarkMode),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => onRemove(folder),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildExtensionList(
    String title,
    List<String> extensions,
    Function(String) onRemove,
    VoidCallback onAdd,
    bool isDarkMode,
    Color accentColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? MainScreenColors.darkSurfaceColor
            : MainScreenColors.lightSurfaceColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimens.paddingLg,
              AppDimens.paddingLg,
              AppDimens.paddingSm,
              AppDimens.paddingSm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle(isDarkMode: isDarkMode),
                ),
                IconButton(
                  icon: Icon(Icons.add, color: accentColor),
                  onPressed: onAdd,
                ),
              ],
            ),
          ),
          extensions.isEmpty
              ? Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDimens.paddingLg,
                    0,
                    AppDimens.paddingLg,
                    AppDimens.paddingMd,
                  ),
                  child: Text(
                    'no_extensions_added'.tr(),
                    style: AppTextStyles.body2(isDarkMode: isDarkMode).copyWith(
                      color: MainScreenColors.getTextColor(
                        isDarkMode,
                      ).withValues(alpha: 0.7),
                    ),
                  ),
                )
              : Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDimens.paddingLg,
                    0,
                    AppDimens.paddingLg,
                    AppDimens.paddingMd,
                  ),
                  child: Wrap(
                    spacing: AppDimens.spacingSm,
                    runSpacing: AppDimens.spacingSm,
                    children: extensions
                        .map(
                          (ext) => Chip(
                            label: Text(ext),
                            onDeleted: () => onRemove(ext),
                            deleteIconColor: Colors.redAccent,
                            backgroundColor: accentColor.withValues(alpha: 0.1),
                            labelStyle: AppTextStyles.chipLabel(
                              color: accentColor,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimens.radiusSm,
                              ),
                              side: BorderSide(color: accentColor, width: 0.5),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDimens.spacingSmMd,
                              vertical: AppDimens.paddingSm,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
        ],
      ),
    );
  }
}
