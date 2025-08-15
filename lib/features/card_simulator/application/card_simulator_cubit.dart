import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/entities/playing_card_model.dart';
import 'card_simulator_state.dart';
import '../domain/entities/deck_model.dart';
import '../domain/repositories/deck_repository.dart';
import '../infrastructure/repositories/shared_prefs_deck_repository.dart';

class CardSimulatorCubit
    extends Cubit<CardSimulatorState> {
  CardSimulatorCubit({
    DeckRepository? deckRepository,
  }) : _deckRepository =
           deckRepository ??
           SharedPrefsDeckRepository(),
       super(CardSimulatorState.initial());

  final _uuid = const Uuid();
  final DeckRepository _deckRepository;

  void initialize() {
    // No default deck - user must load their own deck
  }

  void reset() =>
      emit(CardSimulatorState.initial());

  Future<void> confirmAndReset(
    BuildContext context,
  ) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Board?'),
        content: const Text(
          'This will return all cards to their original zones and shuffle.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (shouldReset != true) return;

    final all = _allCards();
    final battlefield = <PlayingCardModel>[];
    final hand = <PlayingCardModel>[];
    final library = <PlayingCardModel>[];
    final graveyard = <PlayingCardModel>[];
    final exile = <PlayingCardModel>[];
    final command = <PlayingCardModel>[];

    for (final c in all) {
      final original = c.copyWith(
        zone: c.originZone,
        position: null,
        isTapped: false,
      );
      switch (original.originZone) {
        case Zone.battlefield:
          battlefield.add(original);
          break;
        case Zone.hand:
          hand.add(original);
          break;
        case Zone.library:
          library.add(original);
          break;
        case Zone.graveyard:
          graveyard.add(original);
          break;
        case Zone.exile:
          exile.add(original);
          break;
        case Zone.command:
          command.add(original);
          break;
      }
    }
    library.shuffle();
    hand.shuffle();
    battlefield.shuffle();
    graveyard.shuffle();
    exile.shuffle();
    command.shuffle();

    emit(
      CardSimulatorState(
        battlefield: battlefield,
        hand: hand,
        library: library,
        graveyard: graveyard,
        exile: exile,
        command: command,
        life: 40,
        turn: 1,

        currentDeckName: state.currentDeckName,
      ),
    );
  }

  void incrementLife() =>
      emit(state.copyWith(life: state.life + 1));
  void decrementLife() =>
      emit(state.copyWith(life: state.life - 1));
  void nextTurn() =>
      emit(state.copyWith(turn: state.turn + 1));

  void addCardToLibrary({
    required String name,
    required String imageUrl,
  }) {
    final card = PlayingCardModel(
      id: _uuid.v4(),
      name: name,
      imageUrl: imageUrl,
      zone: Zone.library,
      isFaceDown: true,
      originZone: Zone.library,
    );
    emit(
      state.copyWith(
        library: [card, ...state.library],
      ),
    );
  }

  void draw(int count) {
    if (state.library.isEmpty) return;

    // Move cards from library to hand using the consolidated moveCard method
    final drawn = state.library
        .take(count)
        .toList();
    for (final card in drawn) {
      moveCard(card.id, Zone.hand);
    }
  }

  // Deck loading
  Future<void> importDeckFromFolder(
    BuildContext context,
  ) async {
    try {
      List<String> images = [];
      String folderName = 'Imported Deck';

      if (Platform.isAndroid) {
        // On Android, use file picker for multiple image selection
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'Opening file browser...',
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Use file picker to select multiple images
        images = await _selectAndroidImages(
          context,
        );

        if (images.isNotEmpty) {
          folderName = 'Android Deck';
        }
      } else {
        // On desktop, use directory picker
        final result = await FilePicker.platform
            .getDirectoryPath();
        if (result == null) return;

        final dir = Directory(result);
        if (!await dir.exists()) return;

        images = await dir
            .list()
            .where((e) => e is File)
            .map((e) => e.path)
            .where(
              (p) =>
                  p.toLowerCase().endsWith(
                    '.png',
                  ) ||
                  p.toLowerCase().endsWith(
                    '.jpg',
                  ) ||
                  p.toLowerCase().endsWith(
                    '.jpeg',
                  ),
            )
            .toList();

        folderName = _getFolderName(result);
      }

      if (images.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'No image files selected.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final deck = DeckModel(
        name: folderName,
        imagePaths: images,
      );
      await _deckRepository.saveDeck(deck);
      _loadDeck(deck);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully loaded deck: $folderName (${images.length} cards)',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // If import fails, show an error
      print('Failed to import deck: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to import deck: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      // No default deck - user must load their own deck
    }
  }

  Future<List<String>> _selectAndroidImages(
    BuildContext context,
  ) async {
    try {
      print(
        'Starting Android folder selection...',
      );

      // Request comprehensive storage permissions
      print(
        'Requesting comprehensive storage permissions...',
      );

      // Request only necessary storage permissions
      final permissions = [
        Permission.storage,
        Permission.manageExternalStorage,
      ];

      Map<Permission, PermissionStatus> statuses =
          {};

      for (final permission in permissions) {
        final status = await permission.status;
        print(
          '${permission.toString()}: $status',
        );

        if (!status.isGranted) {
          print(
            'Requesting ${permission.toString()}...',
          );
          final result = await permission
              .request();
          statuses[permission] = result;
          print(
            '${permission.toString()} result: $result',
          );
        } else {
          statuses[permission] = status;
        }
      }

      // Check if any critical permissions are granted
      final hasStorageAccess =
          statuses[Permission.storage]
                  ?.isGranted ==
              true ||
          statuses[Permission
                      .manageExternalStorage]
                  ?.isGranted ==
              true;

      print(
        'Has storage access: $hasStorageAccess',
      );

      // Try multiple approaches for folder access
      List<String> images = [];

      // Approach 1: Try directory picker with proper permission handling
      print('Opening directory picker...');
      final selectedDir = await FilePicker
          .platform
          .getDirectoryPath(
            dialogTitle:
                'Select folder containing card images',
          );

      if (selectedDir != null) {
        print(
          'User selected directory: $selectedDir',
        );

        // Try to access the directory contents with multiple methods
        images =
            await _tryMultipleDirectoryAccessMethods(
              selectedDir,
            );

        if (images.isNotEmpty) {
          print(
            'Found ${images.length} images using directory access',
          );
          return images;
        }
      }

      // Approach 2: If directory scanning failed, try file picker with folder navigation
      if (images.isEmpty) {
        print(
          'Directory scanning failed, trying file picker with folder navigation...',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'Folder access limited. Please navigate to your folder and select all images.',
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 4),
            ),
          );
        }

        // Wait a moment then open file picker
        await Future.delayed(
          const Duration(milliseconds: 1000),
        );

        return await _selectIndividualFiles(
          context,
        );
      }

      return [];
    } catch (e) {
      print('Error selecting Android folder: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'Error selecting folder: $e',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return [];
    }
  }

  Future<List<String>>
  _tryMultipleDirectoryAccessMethods(
    String dirPath,
  ) async {
    print(
      'Trying multiple directory access methods for: $dirPath',
    );

    // Method 1: Try standard directory listing
    try {
      final images =
          await _scanDirectoryRecursively(
            dirPath,
          );
      if (images.isNotEmpty) {
        print(
          'Method 1 (standard listing) succeeded with ${images.length} images',
        );
        return images;
      }
    } catch (e) {
      print('Method 1 failed: $e');
    }

    // Method 2: Try with different permission approach
    try {
      final images =
          await _scanDirectoryWithPermissions(
            dirPath,
          );
      if (images.isNotEmpty) {
        print(
          'Method 2 (permission-based) succeeded with ${images.length} images',
        );
        return images;
      }
    } catch (e) {
      print('Method 2 failed: $e');
    }

    // Method 3: Try with file picker in the same directory
    try {
      final images =
          await _pickFilesFromDirectory(dirPath);
      if (images.isNotEmpty) {
        print(
          'Method 3 (file picker) succeeded with ${images.length} images',
        );
        return images;
      }
    } catch (e) {
      print('Method 3 failed: $e');
    }

    print('All directory access methods failed');
    return [];
  }

  Future<List<String>>
  _scanDirectoryWithPermissions(
    String dirPath,
  ) async {
    try {
      print(
        'Attempting directory scan with permissions: $dirPath',
      );

      // Check only necessary storage permissions
      final permissions = [
        Permission.storage,
        Permission.manageExternalStorage,
      ];

      Map<Permission, PermissionStatus> statuses =
          {};
      for (final permission in permissions) {
        statuses[permission] =
            await permission.status;
      }

      print('Permission statuses: $statuses');

      // Request permissions if not granted
      bool hasAnyPermission = false;
      for (final permission in permissions) {
        if (statuses[permission]?.isGranted ==
            true) {
          hasAnyPermission = true;
          break;
        }
      }

      if (!hasAnyPermission) {
        print(
          'No permissions granted, requesting permissions...',
        );
        for (final permission in permissions) {
          if (statuses[permission]?.isGranted !=
              true) {
            final result = await permission
                .request();
            print(
              '${permission.toString()} request result: $result',
            );
            if (result.isGranted) {
              hasAnyPermission = true;
            }
          }
        }
      }

      print(
        'Has any permission: $hasAnyPermission',
      );

      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        print(
          'Directory does not exist: $dirPath',
        );
        return [];
      }

      // Try to list with different approaches
      List<FileSystemEntity> allFiles = [];

      try {
        allFiles = await dir.list().toList();
        print(
          'Permission-based listing found ${allFiles.length} items',
        );
      } catch (e) {
        print(
          'Permission-based listing failed: $e',
        );
        return [];
      }

      // Filter for image files
      final imageFiles = allFiles
          .where((e) => e is File)
          .map((e) => e.path)
          .where((path) {
            final lowerPath = path.toLowerCase();
            return lowerPath.endsWith('.png') ||
                lowerPath.endsWith('.jpg') ||
                lowerPath.endsWith('.jpeg');
          })
          .toList();

      print(
        'Found ${imageFiles.length} image files with permissions',
      );
      return imageFiles;
    } catch (e) {
      print(
        'Error in permission-based directory scan: $e',
      );
      return [];
    }
  }

  Future<List<String>> _pickFilesFromDirectory(
    String dirPath,
  ) async {
    try {
      print(
        'Attempting file picker from directory: $dirPath',
      );

      // Try to use file picker with the directory path as starting point
      final result = await FilePicker.platform
          .pickFiles(
            type: FileType.custom,
            allowedExtensions: [
              'png',
              'jpg',
              'jpeg',
            ],
            allowMultiple: true,
            allowCompression: false,
            withData: false,
            withReadStream: false,
            dialogTitle:
                'Select images from the selected folder',
          );

      if (result != null &&
          result.files.isNotEmpty) {
        print(
          'File picker from directory selected ${result.files.length} files',
        );

        final images = result.files
            .where((file) => file.path != null)
            .map((file) => file.path!)
            .where((path) {
              final lowerPath = path
                  .toLowerCase();
              return lowerPath.endsWith('.png') ||
                  lowerPath.endsWith('.jpg') ||
                  lowerPath.endsWith('.jpeg');
            })
            .toList();

        print(
          'Found ${images.length} valid image files from directory picker',
        );
        return images;
      }

      return [];
    } catch (e) {
      print('Error in directory file picker: $e');
      return [];
    }
  }

  Future<List<String>> _scanDirectoryRecursively(
    String dirPath,
  ) async {
    try {
      print(
        'Attempting recursive directory scan: $dirPath',
      );

      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        print(
          'Directory does not exist: $dirPath',
        );
        return [];
      }

      // Try different approaches to list directory contents
      List<FileSystemEntity> allFiles = [];

      try {
        // Approach 1: Standard directory listing
        allFiles = await dir.list().toList();
        print(
          'Standard listing found ${allFiles.length} items',
        );
      } catch (e) {
        print('Standard listing failed: $e');

        try {
          // Approach 2: Try with recursive listing
          allFiles = await dir
              .list(recursive: true)
              .toList();
          print(
            'Recursive listing found ${allFiles.length} items',
          );
        } catch (e2) {
          print(
            'Recursive listing also failed: $e2',
          );
          return [];
        }
      }

      // Filter for image files
      final imageFiles = allFiles
          .where((e) => e is File)
          .map((e) => e.path)
          .where((path) {
            final lowerPath = path.toLowerCase();
            return lowerPath.endsWith('.png') ||
                lowerPath.endsWith('.jpg') ||
                lowerPath.endsWith('.jpeg');
          })
          .toList();

      print(
        'Found ${imageFiles.length} image files in recursive scan',
      );

      // Log first few image files for debugging
      if (imageFiles.isNotEmpty) {
        print('First few image files:');
        for (
          int i = 0;
          i < math.min(3, imageFiles.length);
          i++
        ) {
          print('  - ${imageFiles[i]}');
        }
      }

      return imageFiles;
    } catch (e) {
      print(
        'Error in recursive directory scan: $e',
      );
      return [];
    }
  }

  Future<List<String>> _selectIndividualFiles(
    BuildContext context,
  ) async {
    try {
      print(
        'Opening file picker for individual file selection...',
      );

      final result = await FilePicker.platform
          .pickFiles(
            type: FileType.custom,
            allowedExtensions: [
              'png',
              'jpg',
              'jpeg',
            ],
            allowMultiple: true,
            allowCompression: false,
            withData: false,
            withReadStream: false,
            dialogTitle:
                'Select individual image files (you can select multiple)',
          );

      if (result != null &&
          result.files.isNotEmpty) {
        print(
          'File picker selected ${result.files.length} files',
        );

        final images = result.files
            .where((file) => file.path != null)
            .map((file) => file.path!)
            .where((path) {
              final lowerPath = path
                  .toLowerCase();
              return lowerPath.endsWith('.png') ||
                  lowerPath.endsWith('.jpg') ||
                  lowerPath.endsWith('.jpeg');
            })
            .toList();

        print(
          'Found ${images.length} valid image files',
        );
        return images;
      } else {
        print(
          'No files selected in fallback picker',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'No files selected. Please try again.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      return [];
    } catch (e) {
      print('Error in fallback file picker: $e');
      return [];
    }
  }

  Future<List<String>>
  _browseAndroidDirectory() async {
    try {
      print(
        'Starting Android directory browsing...',
      );

      // Request storage permissions
      final status = await Permission.storage
          .request();
      print('Storage permission status: $status');

      if (!status.isGranted) {
        print('Storage permission denied');
        return [];
      }

      // Get external storage directory
      final externalDir =
          await getExternalStorageDirectory();
      if (externalDir == null) {
        print(
          'Could not access external storage',
        );
        return [];
      }

      print(
        'External storage path: ${externalDir.path}',
      );

      // Try to find common directories where card images might be stored
      final possiblePaths = [
        '${externalDir.path}/Download',
        '${externalDir.path}/Pictures',
        '${externalDir.path}/Documents',
        '${externalDir.path}/DCIM',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Pictures',
        '/storage/emulated/0/Documents',
        '/storage/emulated/0/DCIM',
      ];

      print(
        'Checking possible paths: $possiblePaths',
      );

      for (final path in possiblePaths) {
        final dir = Directory(path);
        final exists = await dir.exists();
        print('Directory $path exists: $exists');

        if (exists) {
          print('Checking directory: $path');
          final images =
              await _scanDirectoryForImages(dir);
          if (images.isNotEmpty) {
            print(
              'Found ${images.length} images in $path',
            );
            return images;
          }
        }
      }

      print(
        'No images found in common directories, opening directory picker...',
      );

      // If no images found in common directories, let user select a directory
      final selectedDir = await FilePicker
          .platform
          .getDirectoryPath();

      if (selectedDir != null) {
        print(
          'User selected directory: $selectedDir',
        );
        final dir = Directory(selectedDir);
        final exists = await dir.exists();
        print(
          'Selected directory exists: $exists',
        );

        if (exists) {
          final images =
              await _scanDirectoryForImages(dir);
          print(
            'Found ${images.length} images in selected directory',
          );
          return images;
        }
      } else {
        print('No directory selected by user');
      }

      return [];
    } catch (e) {
      print(
        'Error browsing Android directory: $e',
      );
      return [];
    }
  }

  Future<List<String>> _scanDirectoryForImages(
    Directory directory,
  ) async {
    try {
      print(
        'Scanning directory: ${directory.path}',
      );

      final allFiles = await directory
          .list()
          .toList();
      print(
        'Found ${allFiles.length} total files in ${directory.path}',
      );

      // Log all files for debugging
      for (final file in allFiles) {
        print(
          'File: ${file.path} (type: ${file.runtimeType})',
        );
      }

      final imageFiles = allFiles
          .where((e) => e is File)
          .map((e) => e.path)
          .where((path) {
            final lowerPath = path.toLowerCase();
            final isImage =
                lowerPath.endsWith('.png') ||
                lowerPath.endsWith('.jpg') ||
                lowerPath.endsWith('.jpeg');
            print(
              'Checking path: $path -> isImage: $isImage',
            );
            return isImage;
          })
          .toList();

      print(
        'Found ${imageFiles.length} image files',
      );

      // Log all image files for debugging
      if (imageFiles.isNotEmpty) {
        print('All image files found:');
        for (final image in imageFiles) {
          print('  - $image');
        }
      } else {
        print(
          'No image files found. Checking file extensions...',
        );
        final allPaths = allFiles
            .where((e) => e is File)
            .map((e) => e.path)
            .toList();
        for (final path in allPaths) {
          final extension = path
              .split('.')
              .last
              .toLowerCase();
          print(
            '  File: $path -> Extension: $extension',
          );
        }
      }

      return imageFiles;
    } catch (e) {
      print('Error scanning directory: $e');
      return [];
    }
  }

  Future<List<String>>
  _pickMultipleFilesOnAndroid() async {
    try {
      print(
        'Using file picker fallback for Android...',
      );

      final result = await FilePicker.platform
          .pickFiles(
            type: FileType.custom,
            allowedExtensions: [
              'png',
              'jpg',
              'jpeg',
            ],
            allowMultiple: true,
            allowCompression: false,
            withData: false,
            withReadStream: false,
          );

      if (result != null &&
          result.files.isNotEmpty) {
        final images = result.files
            .where((file) => file.path != null)
            .map((file) => file.path!)
            .where(
              (path) =>
                  path.toLowerCase().endsWith(
                    '.png',
                  ) ||
                  path.toLowerCase().endsWith(
                    '.jpg',
                  ) ||
                  path.toLowerCase().endsWith(
                    '.jpeg',
                  ),
            )
            .toList();

        print(
          'File picker selected ${images.length} images',
        );
        return images;
      }

      print('No files selected via file picker');
      return [];
    } catch (e) {
      print(
        'Error with file picker fallback: $e',
      );
      return [];
    }
  }

  String _getFolderName(String path) {
    if (Platform.isAndroid) {
      // For Android content URIs, extract a meaningful name
      if (path.contains('Download'))
        return 'Download Deck';
      if (path.contains('Pictures'))
        return 'Pictures Deck';
      if (path.contains('Documents'))
        return 'Documents Deck';
      return 'Android Deck';
    } else {
      // For desktop, use the folder name
      return path
          .split(Platform.pathSeparator)
          .last;
    }
  }

  Future<List<DeckModel>> loadSavedDecks() async {
    try {
      return await _deckRepository
          .loadSavedDecks();
    } catch (e) {
      print('Failed to load saved decks: $e');
      // Return empty list if loading fails - no default deck
      return [];
    }
  }

  Future<void> loadDeckByName(String name) async {
    try {
      final decks = await _deckRepository
          .loadSavedDecks();
      final deck = decks.firstWhere(
        (d) => d.name == name,
        orElse: () => decks.first,
      );
      _loadDeck(deck);
    } catch (e) {
      // If loading fails, show error but don't create default deck
      print('Failed to load deck "$name": $e');
    }
  }

  void _loadDeck(DeckModel deck) {
    final library = deck.imagePaths
        .map(
          (path) => PlayingCardModel(
            id: _uuid.v4(),
            name: _fileName(path),
            imageUrl: _getImageUrl(path),
            zone: Zone.library,
            isFaceDown: true,
            originZone: Zone.library,
          ),
        )
        .toList();
    library.shuffle();
    emit(
      CardSimulatorState(
        battlefield: const [],
        hand: const [],
        library: library,
        graveyard: const [],
        exile: const [],
        command: const [],
        life: 40,
        turn: 1,
        currentDeckName: deck.name,
      ),
    );
  }

  String _getImageUrl(String path) {
    // Handle different path types for different platforms
    if (path.startsWith('assets/')) {
      // For bundled assets
      return path;
    } else if (path.startsWith('http')) {
      // For network URLs
      return path;
    } else {
      // For local file paths
      try {
        return File(path).uri.toString();
      } catch (e) {
        // Fallback to a placeholder
        return 'https://picsum.photos/300/420?random=${_uuid.v4()}';
      }
    }
  }

  String _fileName(String path) {
    final parts = path.split(
      Platform.pathSeparator,
    );
    return parts.isNotEmpty ? parts.last : 'Card';
  }

  void moveCard(
    String id,
    Zone target, {
    Offset? position,
    int? insertIndex, // For hand insertion
  }) {
    // Clear selection before moving any card
    if (state.selectedCardId != null) {
      clearSelection();
    }

    // Create copies to avoid mutating lists that the UI may be iterating over
    final battlefield =
        List<PlayingCardModel>.from(
          state.battlefield,
        );
    final hand = List<PlayingCardModel>.from(
      state.hand,
    );
    final library = List<PlayingCardModel>.from(
      state.library,
    );
    final graveyard = List<PlayingCardModel>.from(
      state.graveyard,
    );
    final exile = List<PlayingCardModel>.from(
      state.exile,
    );
    final command = List<PlayingCardModel>.from(
      state.command,
    );

    PlayingCardModel? card;
    Zone? fromZone;
    for (final c in battlefield) {
      if (c.id == id) {
        card = c;
        fromZone = Zone.battlefield;
        break;
      }
    }
    if (card == null &&
        hand.any((c) => c.id == id)) {
      card = hand.firstWhere((c) => c.id == id);
      fromZone = Zone.hand;
    }
    if (card == null &&
        library.any((c) => c.id == id)) {
      card = library.firstWhere(
        (c) => c.id == id,
      );
      fromZone = Zone.library;
    }
    if (card == null &&
        graveyard.any((c) => c.id == id)) {
      card = graveyard.firstWhere(
        (c) => c.id == id,
      );
      fromZone = Zone.graveyard;
    }
    if (card == null &&
        exile.any((c) => c.id == id)) {
      card = exile.firstWhere((c) => c.id == id);
      fromZone = Zone.exile;
    }
    if (card == null &&
        command.any((c) => c.id == id)) {
      card = command.firstWhere(
        (c) => c.id == id,
      );
      fromZone = Zone.command;
    }

    // Handle same-zone reordering (e.g., hand to hand)
    if (fromZone == target) {
      switch (target) {
        case Zone.hand:
          final currentIndex = hand.indexWhere(
            (c) => c.id == id,
          );
          if (currentIndex == -1) return;
          final cardToMove = hand.removeAt(
            currentIndex,
          );
          final index =
              insertIndex ?? hand.length;
          final safeIndex = index.clamp(
            0,
            hand.length,
          );
          hand.insert(safeIndex, cardToMove);
          break;
        case Zone.battlefield:
          // For battlefield, we might want to update position
          if (position != null) {
            final cardIndex = battlefield
                .indexWhere((c) => c.id == id);
            if (cardIndex != -1) {
              battlefield[cardIndex] =
                  battlefield[cardIndex].copyWith(
                    position: position,
                  );
            }
          }
          break;
        default:
          // For other zones, same-zone reordering doesn't make sense
          return;
      }
    } else {
      // Handle cross-zone movement
      // Remove from the source zone
      switch (fromZone) {
        case Zone.battlefield:
          battlefield.removeWhere(
            (c) => c.id == id,
          );
          break;
        case Zone.hand:
          hand.removeWhere((c) => c.id == id);
          break;
        case Zone.library:
          library.removeWhere((c) => c.id == id);
          break;
        case Zone.graveyard:
          graveyard.removeWhere(
            (c) => c.id == id,
          );
          break;
        case Zone.exile:
          exile.removeWhere((c) => c.id == id);
          break;
        case Zone.command:
          command.removeWhere((c) => c.id == id);
          break;
        case null:
          break;
      }

      if (card == null) return;
      final source = card;
      final moved = target == Zone.library
          ? source.copyWith(
              zone: target,
              position: null,
              isFaceDown: true,
              isTapped:
                  false, // Force portrait orientation
            )
          : source.copyWith(
              zone: target,
              position: position,
              isFaceDown: false,
              isTapped:
                  false, // Force portrait orientation
            );

      // Handle zone-specific insertion logic
      switch (target) {
        case Zone.battlefield:
          battlefield.add(moved);
          break;
        case Zone.hand:
          // Use insertIndex if provided, otherwise add to end
          final index =
              insertIndex ?? hand.length;
          final safeIndex = index.clamp(
            0,
            hand.length,
          );
          hand.insert(safeIndex, moved);
          break;
        case Zone.library:
          library.insert(0, moved);
          break;
        case Zone.graveyard:
          graveyard.add(moved);
          break;
        case Zone.exile:
          exile.add(moved);
          break;
        case Zone.command:
          command.add(moved);
          break;
      }
    }

    emit(
      state.copyWith(
        battlefield: battlefield,
        hand: hand,
        library: library,
        graveyard: graveyard,
        exile: exile,
        command: command,
      ),
    );
  }

  void updateBattlefieldPosition(
    String id,
    Offset position,
  ) {
    final updated = state.battlefield
        .map(
          (c) => c.id == id
              ? c.copyWith(position: position)
              : c,
        )
        .toList();
    emit(state.copyWith(battlefield: updated));
  }

  void toggleTapped(String id) {
    final allZones = {
      Zone.battlefield: state.battlefield,
      Zone.hand: state.hand,
      Zone.library: state.library,
      Zone.graveyard: state.graveyard,
      Zone.exile: state.exile,
      Zone.command: state.command,
    };
    final zone = allZones.entries
        .firstWhere(
          (e) => e.value.any((c) => c.id == id),
        )
        .key;
    final updated = allZones[zone]!
        .map(
          (c) => c.id == id
              ? c.copyWith(isTapped: !c.isTapped)
              : c,
        )
        .toList();
    emit(_replaceZone(zone, updated));
  }

  void deleteCard(String id) {
    // Clear selection before deleting any card
    if (state.selectedCardId != null) {
      clearSelection();
    }

    final allZones = {
      Zone.battlefield: state.battlefield
          .where((c) => c.id != id)
          .toList(),
      Zone.hand: state.hand
          .where((c) => c.id != id)
          .toList(),
      Zone.library: state.library
          .where((c) => c.id != id)
          .toList(),
      Zone.graveyard: state.graveyard
          .where((c) => c.id != id)
          .toList(),
      Zone.exile: state.exile
          .where((c) => c.id != id)
          .toList(),
      Zone.command: state.command
          .where((c) => c.id != id)
          .toList(),
    };
    emit(
      state.copyWith(
        battlefield: allZones[Zone.battlefield]!,
        hand: allZones[Zone.hand]!,
        library: allZones[Zone.library]!,
        graveyard: allZones[Zone.graveyard]!,
        exile: allZones[Zone.exile]!,
        command: allZones[Zone.command]!,
      ),
    );
  }

  // Helpers
  List<PlayingCardModel> _allCards() => [
    ...state.battlefield,
    ...state.hand,
    ...state.library,
    ...state.graveyard,
    ...state.exile,
    ...state.command,
  ];

  CardSimulatorState _replaceZone(
    Zone zone,
    List<PlayingCardModel> cards,
  ) {
    switch (zone) {
      case Zone.battlefield:
        return state.copyWith(battlefield: cards);
      case Zone.hand:
        return state.copyWith(hand: cards);
      case Zone.library:
        return state.copyWith(library: cards);
      case Zone.graveyard:
        return state.copyWith(graveyard: cards);
      case Zone.exile:
        return state.copyWith(exile: cards);
      case Zone.command:
        return state.copyWith(command: cards);
    }
  }

  // _rebuild removed; state is rebuilt directly in emit calls

  // Card selection methods
  void selectCard(String? cardId) {
    print(
      'Cubit selectCard called with cardId: $cardId',
    );
    print(
      'Current selectedCardId: ${state.selectedCardId}',
    );

    final newState = state.copyWith(
      selectedCardId: cardId,
    );

    print(
      'New selectedCardId will be: ${newState.selectedCardId}',
    );
    emit(newState);
  }

  void clearSelection() {
    // Create new state directly instead of using copyWith
    final newState = CardSimulatorState(
      battlefield: state.battlefield,
      hand: state.hand,
      library: state.library,
      graveyard: state.graveyard,
      exile: state.exile,
      command: state.command,
      life: state.life,
      turn: state.turn,
      currentDeckName: state.currentDeckName,
      selectedCardId:
          null, // Explicitly set to null
    );

    emit(newState);
  }
}
