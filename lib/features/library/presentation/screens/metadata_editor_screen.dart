import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import '../../../../core/services/local_songs_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../shared/components/app_snackbar.dart';
import '../../data/providers/library_provider.dart';

class MetadataEditorScreen extends StatefulWidget {
  final Map<String, dynamic> song;

  const MetadataEditorScreen({Key? key, required this.song}) : super(key: key);

  @override
  State<MetadataEditorScreen> createState() => _MetadataEditorScreenState();
}

class _MetadataEditorScreenState extends State<MetadataEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;
  late TextEditingController _genreController;
  late TextEditingController _yearController;
  late TextEditingController _trackNumberController;
  late TextEditingController _albumArtistController;
  late TextEditingController _trackTotalController;
  late TextEditingController _discNumberController;
  late TextEditingController _discTotalController;
  late TextEditingController _durationMsController;
  late TextEditingController _fileSizeController;

  bool _isLoading = false;
  String? _filePath;
  String? _selectedImagePath;
  Picture? _currentPicture;

  @override
  void initState() {
    super.initState();
    _filePath =
        widget.song['localPath'] ?? widget.song['data'] ?? widget.song['path'];

    _titleController = TextEditingController(
      text: widget.song['title'] ?? widget.song['name'] ?? '',
    );
    _artistController = TextEditingController(
      text: widget.song['artist'] ?? widget.song['artistName'] ?? '',
    );
    _albumController = TextEditingController(text: widget.song['album'] ?? '');
    _genreController = TextEditingController(text: widget.song['genre'] ?? '');
    _yearController = TextEditingController(
      text: widget.song['year']?.toString() ?? '',
    );
    _trackNumberController = TextEditingController(
      text: widget.song['track']?.toString() ?? '',
    );
    _albumArtistController = TextEditingController(
      text: widget.song['albumArtist'] ?? '',
    );
    _trackTotalController = TextEditingController();
    _discNumberController = TextEditingController();
    _discTotalController = TextEditingController();
    _durationMsController = TextEditingController();
    _fileSizeController = TextEditingController();

    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    if (_filePath == null || !File(_filePath!).existsSync()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final metadata = await MetadataGod.readMetadata(file: _filePath!);
      if (mounted) {
        setState(() {
          _titleController.text = metadata.title ?? _titleController.text;
          _artistController.text = metadata.artist ?? _artistController.text;
          _albumController.text = metadata.album ?? _albumController.text;
          _genreController.text = metadata.genre ?? _genreController.text;
          _yearController.text =
              metadata.year?.toString() ?? _yearController.text;
          _trackNumberController.text =
              metadata.trackNumber?.toString() ?? _trackNumberController.text;
          _albumArtistController.text =
              metadata.albumArtist ?? _albumArtistController.text;
          _trackTotalController.text = metadata.trackTotal?.toString() ?? '';
          _discNumberController.text = metadata.discNumber?.toString() ?? '';
          _discTotalController.text = metadata.discTotal?.toString() ?? '';
          _durationMsController.text = metadata.durationMs?.toString() ?? '';
          _fileSizeController.text = metadata.fileSize?.toString() ?? '';
          _currentPicture = metadata.picture;
        });
      }
    } catch (e) {
      debugPrint('Error loading metadata: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImagePath = result.files.single.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to pick image');
      }
    }
  }

  Future<void> _saveMetadata() async {
    if (_filePath == null || !File(_filePath!).existsSync()) {
      AppSnackBar.showError(context, 'File not found');
      return;
    }

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      Permission permission;
      if (sdkInt >= 30) {
        permission = Permission.manageExternalStorage;
      } else {
        permission = Permission.storage;
      }

      final status = await permission.status;
      if (!status.isGranted) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final settingsProvider = Provider.of<SettingsProvider>(
          context,
          listen: false,
        );
        final accentColor = settingsProvider.accentColor;
        final surfaceColor = MainScreenColors.getSurfaceColor(isDarkMode);
        final textColor = MainScreenColors.getTextColor(isDarkMode);

        final shouldRequest = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusLg),
            ),
            title: Text(
              'Permission Required',
              style: AppTextStyles.titleLg(isDarkMode: isDarkMode),
            ),
            content: Text(
              'To save metadata changes, the app needs permission to modify files on your device.',
              style: AppTextStyles.bodyMd(isDarkMode: isDarkMode),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.button(
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Grant Permission',
                  style: AppTextStyles.button(color: accentColor),
                ),
              ),
            ],
          ),
        );

        if (shouldRequest != true) return;

        final result = await permission.request();
        if (!result.isGranted) {
          if (mounted) {
            AppSnackBar.showError(
              context,
              'Storage permission required to save metadata',
            );
          }
          return;
        }
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final metadata = Metadata(
        title: _titleController.text.isNotEmpty ? _titleController.text : null,
        artist: _artistController.text.isNotEmpty
            ? _artistController.text
            : null,
        album: _albumController.text.isNotEmpty ? _albumController.text : null,
        genre: _genreController.text.isNotEmpty ? _genreController.text : null,
        year: int.tryParse(_yearController.text),
        trackNumber: int.tryParse(_trackNumberController.text),
        albumArtist: _albumArtistController.text.isNotEmpty
            ? _albumArtistController.text
            : null,
        trackTotal: int.tryParse(_trackTotalController.text),
        discNumber: int.tryParse(_discNumberController.text),
        discTotal: int.tryParse(_discTotalController.text),
        durationMs: double.tryParse(_durationMsController.text),
        fileSize: _fileSizeController.text.isNotEmpty
            ? BigInt.tryParse(_fileSizeController.text)
            : null,
        picture: _selectedImagePath != null
            ? Picture(
                data: File(_selectedImagePath!).readAsBytesSync(),
                mimeType: lookupMimeType(_selectedImagePath!) ?? 'image/jpeg',
              )
            : _currentPicture,
      );

      await MetadataGod.writeMetadata(file: _filePath!, metadata: metadata);

      if (Platform.isAndroid) {
        try {
          await LocalSongsService().scanMedia(_filePath!);
        } catch (e) {
          debugPrint('Error scanning media: $e');
        }
      }

      if (mounted) {
        AppSnackBar.showSuccess(context, 'Metadata saved successfully');
      }

      if (mounted) {
        final libraryProvider = Provider.of<LibraryProvider>(
          context,
          listen: false,
        );
        libraryProvider.refreshLibraryData();
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving metadata: $e');
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to save metadata');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _genreController.dispose();
    _yearController.dispose();
    _trackNumberController.dispose();
    _albumArtistController.dispose();
    _trackTotalController.dispose();
    _discNumberController.dispose();
    _discTotalController.dispose();
    _durationMsController.dispose();
    _fileSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final accentColor = settingsProvider.accentColor;
    final textColor = MainScreenColors.getTextColor(isDarkMode);
    final backgroundColor = MainScreenColors.getBackgroundColor(isDarkMode);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'edit_metadata'.tr(),
          style: AppTextStyles.appBarTitle(isDarkMode: isDarkMode),
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: accentColor,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(Icons.save, color: accentColor),
            onPressed: _isLoading ? null : _saveMetadata,
          ),
        ],
      ),
      body: _isLoading && _titleController.text.isEmpty
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimens.radiusLg,
                          ),
                          image: _selectedImagePath != null
                              ? DecorationImage(
                                  image: FileImage(File(_selectedImagePath!)),
                                  fit: BoxFit.cover,
                                )
                              : _currentPicture != null
                              ? DecorationImage(
                                  image: MemoryImage(_currentPicture!.data),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child:
                            _selectedImagePath == null &&
                                _currentPicture == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 40,
                                    color: textColor.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add Cover',
                                    style:
                                        AppTextStyles.bodyMd(
                                          isDarkMode: isDarkMode,
                                        ).copyWith(
                                          color: textColor.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimens.spacingXl),
                  _buildTextField(
                    controller: _titleController,
                    label: 'Title',
                    isDarkMode: isDarkMode,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: AppDimens.spacingMd),
                  _buildTextField(
                    controller: _artistController,
                    label: 'Artist',
                    isDarkMode: isDarkMode,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: AppDimens.spacingMd),
                  _buildTextField(
                    controller: _albumController,
                    label: 'Album',
                    isDarkMode: isDarkMode,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: AppDimens.spacingMd),
                  _buildTextField(
                    controller: _albumArtistController,
                    label: 'Album Artist',
                    isDarkMode: isDarkMode,
                    accentColor: accentColor,
                  ),
                  const SizedBox(height: AppDimens.spacingMd),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _yearController,
                          label: 'Year',
                          isDarkMode: isDarkMode,
                          accentColor: accentColor,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppDimens.spacingMd),
                      Expanded(
                        child: _buildTextField(
                          controller: _trackNumberController,
                          label: 'Track Number',
                          isDarkMode: isDarkMode,
                          accentColor: accentColor,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.spacingMd),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _trackTotalController,
                          label: 'Track Total',
                          isDarkMode: isDarkMode,
                          accentColor: accentColor,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppDimens.spacingMd),
                      Expanded(
                        child: _buildTextField(
                          controller: _discNumberController,
                          label: 'Disc Number',
                          isDarkMode: isDarkMode,
                          accentColor: accentColor,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.spacingMd),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _discTotalController,
                          label: 'Disc Total',
                          isDarkMode: isDarkMode,
                          accentColor: accentColor,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppDimens.spacingMd),
                      Expanded(
                        child: _buildTextField(
                          controller: _durationMsController,
                          label: 'Duration (ms)',
                          isDarkMode: isDarkMode,
                          accentColor: accentColor,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimens.spacingMd),
                  _buildTextField(
                    controller: _fileSizeController,
                    label: 'File Size (bytes)',
                    isDarkMode: isDarkMode,
                    accentColor: accentColor,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppDimens.spacingMd),
                  _buildTextField(
                    controller: _genreController,
                    label: 'Genre',
                    isDarkMode: isDarkMode,
                    accentColor: accentColor,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool isDarkMode,
    required Color accentColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final textColor = MainScreenColors.getTextColor(isDarkMode);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyLg(isDarkMode: isDarkMode),
      cursorColor: accentColor,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodyMd(
          isDarkMode: isDarkMode,
        ).copyWith(color: textColor.withValues(alpha: 0.7)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: textColor.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: accentColor),
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacingMd,
          vertical: AppDimens.spacingMd,
        ),
      ),
    );
  }
}
