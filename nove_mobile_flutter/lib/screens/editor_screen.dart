<<<<<<< HEAD
import 'dart:async';
import 'dart:io';
=======
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
<<<<<<< HEAD
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../services/category_service.dart';
import '../services/database_service.dart';
import '../services/note_service.dart';
import '../services/stats_service.dart';
import '../theme/tokens.dart';
import '../widgets/markdown_editing_controller.dart';

// ─── Backward-compat shim: home_screen.dart still imports this ────────────────
Future<List<String>> loadAllCategories() => CategoryService.loadAllCategories();
Future<void> saveCustomCategory(String cat) => CategoryService.saveCustomCategory(cat);
=======
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../services/note_service.dart';
import '../theme/tokens.dart';

// ─── Custom categories stored in SharedPreferences ───────────────────────────
const _builtInCategories = ['Work', 'Ideas', 'Personal', 'Urgent'];
const _customCategoriesKey = 'custom_categories';

Future<List<String>> loadAllCategories() async {
  final prefs = await SharedPreferences.getInstance();
  final custom = prefs.getStringList(_customCategoriesKey) ?? [];
  return [..._builtInCategories, ...custom];
}

Future<void> saveCustomCategory(String category) async {
  final prefs = await SharedPreferences.getInstance();
  final existing = prefs.getStringList(_customCategoriesKey) ?? [];
  if (!existing.contains(category)) {
    existing.add(category);
    await prefs.setStringList(_customCategoriesKey, existing);
  }
}

// ─── Color options ─────────────────────────────────────────────────────────
const _colorLabels = [
  '#C0452A',
  '#F5C842',
  '#5DCAA5',
  '#85B7EB',
  '#ED93B1',
  '#FFFFFF',
];
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f

class EditorScreen extends ConsumerStatefulWidget {
  final Note? note;
  const EditorScreen({super.key, this.note});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
<<<<<<< HEAD
  final ScrollController _editorScrollController = ScrollController();

  late bool _isPinned;
  late bool _isFavorite;
=======

  late bool _isPinned;
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
  late bool _isNewNote;
  late String _selectedCategory;
  late String _selectedColor;

  bool _hasChanges = false;
  bool _isSaved = false;
  bool _focusMode = false;
<<<<<<< HEAD
  bool _showScrollToTop = false;
  bool _showFindReplace = false;

  // Find & Replace state
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  List<int> _findMatches = [];
  int _findMatchIndex = 0;

  Timer? _debounce;

  List<String> _availableCategories = [...kBuiltInCategories];
  int _initialWordCount = 0;
=======
  bool _isPreviewMode = false;

  List<String> _availableCategories = [..._builtInCategories];
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f

  @override
  void initState() {
    super.initState();
    _isNewNote = widget.note == null;
<<<<<<< HEAD
    _initialWordCount = widget.note?.wordCount ?? 0;
=======
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f

    _titleController = TextEditingController(
      text: widget.note?.title == 'Untitled' ? '' : (widget.note?.title ?? ''),
    );
<<<<<<< HEAD
    _contentController = MarkdownEditingController(
      context: context,
=======
    _contentController = TextEditingController(
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
      text: widget.note?.content ?? '',
    );

    _isPinned = widget.note?.isPinned ?? false;
<<<<<<< HEAD
    _isFavorite = widget.note?.isFavorite ?? false;
=======
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
    _selectedCategory = widget.note?.category ?? '';
    _selectedColor = widget.note?.colorLabel ?? '#FFFFFF';

    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);

<<<<<<< HEAD
    _editorScrollController.addListener(() {
      final shouldShow = _editorScrollController.offset > 200;
      if (shouldShow != _showScrollToTop) {
        setState(() => _showScrollToTop = shouldShow);
      }
    });

=======
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
    _loadCategories();
  }

  void _onChanged() {
    setState(() {
      _hasChanges = true;
      _isSaved = false;
    });
<<<<<<< HEAD
    // Debounced autosave — cancels previous timer before scheduling a new one
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), _autoSave);
  }

  Future<void> _loadCategories() async {
    final cats = await CategoryService.loadAllCategories();
=======
  }

  Future<void> _loadCategories() async {
    final cats = await loadAllCategories();
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
    if (mounted) setState(() => _availableCategories = cats);
  }

  @override
  void dispose() {
<<<<<<< HEAD
    _debounce?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _titleController.dispose();
    _contentController.dispose();
    _editorScrollController.dispose();
    _findController.dispose();
    _replaceController.dispose();
=======
    // Ensure we restore standard UI mode if the user leaves while in Zen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _titleController.dispose();
    _contentController.dispose();
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
    super.dispose();
  }

  String get _effectiveTitle {
    final t = _titleController.text.trim();
    if (t.isNotEmpty) return t;
    final firstLine = _contentController.text.split('\n').first.trim();
    return firstLine.isEmpty ? 'Untitled' : firstLine;
  }

<<<<<<< HEAD
  void _recordWordStats() {
    final newWordCount = _contentController.text.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
    final diff = newWordCount - _initialWordCount;
    if (diff > 0) {
      StatsService.addWords(diff);
    }
    _initialWordCount = newWordCount;
  }

  Future<void> _saveAndClose() async {
    _debounce?.cancel();
=======
  Future<void> _saveAndClose() async {
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
    final content = _contentController.text.trim();
    final title = _effectiveTitle;

    if (content.isEmpty && _titleController.text.trim().isEmpty) {
      if (!_isNewNote && widget.note != null) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: NoveColors.cardBg(context),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Empty note',
              style: GoogleFonts.lora(
                  fontWeight: FontWeight.bold, color: NoveColors.primaryText(context)),
            ),
            content: Text(
              'This note is empty. Would you like to keep it or discard it?',
              style: GoogleFonts.dmSans(color: NoveColors.secondaryText(context)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Keep',
                    style: GoogleFonts.dmSans(
                        color: NoveColors.accent(context), fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Discard', style: GoogleFonts.dmSans(color: NoveColors.error)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await ref.read(notesProvider.notifier).deleteNote(widget.note!.id);
        }
        if (mounted) Navigator.pop(context);
      } else {
        if (mounted) Navigator.pop(context);
      }
      return;
    }

<<<<<<< HEAD
    _recordWordStats();

=======
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
    if (_isNewNote) {
      await ref.read(notesProvider.notifier).createNote(
            content,
            title: title,
            colorLabel: _selectedColor,
            category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
          );
    } else if (_hasChanges && widget.note != null) {
<<<<<<< HEAD
      // Save a version snapshot before overwriting
      final existing = await DatabaseService.getVersions(widget.note!.id);
      final currentNote = await NoteService.updateNote(
=======
      await NoteService.updateNote(
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
        widget.note!.id,
        title: title,
        content: content,
        isPinned: _isPinned,
<<<<<<< HEAD
        isFavorite: _isFavorite,
        colorLabel: _selectedColor,
        category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
      );
      if (currentNote != null && existing.isEmpty) {
        // Save original version only if no history yet
        if (widget.note!.content.trim().isNotEmpty) {
          await DatabaseService.saveVersion(widget.note!);
        }
      }
      if (currentNote != null) {
        await DatabaseService.saveVersion(currentNote);
      }
=======
        colorLabel: _selectedColor,
        category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
      );
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
    }

    HapticFeedback.lightImpact();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _autoSave() async {
    final content = _contentController.text.trim();
    if (!_hasChanges) return;
<<<<<<< HEAD
    
    _recordWordStats();

    if (!_isNewNote && widget.note != null) {
      final updated = await NoteService.updateNote(
=======
    if (!_isNewNote && widget.note != null) {
      await NoteService.updateNote(
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
        widget.note!.id,
        title: _effectiveTitle,
        content: content,
        isPinned: _isPinned,
<<<<<<< HEAD
        isFavorite: _isFavorite,
        colorLabel: _selectedColor,
        category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
      );
      if (updated != null) await DatabaseService.saveVersion(updated);
=======
        colorLabel: _selectedColor,
        category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
      );
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
      if (mounted) setState(() { _isSaved = true; _hasChanges = false; });
    }
  }

  void _insertFormatting(String prefix, [String? suffix]) {
<<<<<<< HEAD
    HapticFeedback.selectionClick();
    var sel = _contentController.selection;
    if (!sel.isValid) {
      sel = TextSelection.collapsed(offset: _contentController.text.length);
    }
=======
    HapticFeedback.selectionClick(); // Tactile feedback for formatting
    final sel = _contentController.selection;
    if (!sel.isValid) return;
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
    final text = _contentController.text;
    final selected = sel.textInside(text);
    final replacement = suffix != null ? '$prefix$selected$suffix' : '$prefix$selected';
    final newText = text.replaceRange(sel.start, sel.end, replacement);
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + replacement.length),
    );
  }

<<<<<<< HEAD
  // ─── Find & Replace ───────────────────────────────────────────────────────
  void _updateFindMatches() {
    final query = _findController.text;
    if (query.isEmpty) {
      setState(() { _findMatches = []; _findMatchIndex = 0; });
      return;
    }
    final text = _contentController.text;
    final matches = <int>[];
    int idx = 0;
    while (true) {
      idx = text.toLowerCase().indexOf(query.toLowerCase(), idx);
      if (idx == -1) break;
      matches.add(idx);
      idx += query.length;
    }
    setState(() {
      _findMatches = matches;
      _findMatchIndex = matches.isEmpty ? 0 : 0;
    });
    if (matches.isNotEmpty) {
      _contentController.selection = TextSelection(
        baseOffset: matches[0],
        extentOffset: matches[0] + query.length,
      );
    }
  }

  void _navigateMatch(int direction) {
    if (_findMatches.isEmpty) return;
    setState(() {
      _findMatchIndex = (_findMatchIndex + direction).clamp(0, _findMatches.length - 1);
    });
    final idx = _findMatches[_findMatchIndex];
    _contentController.selection = TextSelection(
      baseOffset: idx,
      extentOffset: idx + _findController.text.length,
    );
  }

  void _replaceCurrentMatch() {
    if (_findMatches.isEmpty) return;
    final idx = _findMatches[_findMatchIndex];
    final query = _findController.text;
    final replacement = _replaceController.text;
    final newText = _contentController.text.replaceRange(idx, idx + query.length, replacement);
    _contentController.text = newText;
    _onChanged();
    _updateFindMatches();
  }

  void _replaceAllMatches() {
    final query = _findController.text;
    if (query.isEmpty) return;
    final replacement = _replaceController.text;
    final newText = _contentController.text.replaceAll(query, replacement);
    _contentController.text = newText;
    _onChanged();
    _updateFindMatches();
  }

  // ─── Image Picker ─────────────────────────────────────────────────────────
  Future<void> _insertImage() async {
    HapticFeedback.mediumImpact();
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: NoveColors.cardBg(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text('Camera', style: GoogleFonts.dmSans()),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('Gallery', style: GoogleFonts.dmSans()),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null || !mounted) return;
    _insertFormatting('![img](${file.path})');
  }

  // ─── Version History ──────────────────────────────────────────────────────
  Future<void> _showVersionHistory() async {
    if (_isNewNote || widget.note == null) return;
    HapticFeedback.lightImpact();
    final versions = await DatabaseService.getVersions(widget.note!.id);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NoveColors.cardBg(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: NoveColors.warmGray300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text('Version History', style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w600, color: NoveColors.primaryText(ctx))),
                  const Spacer(),
                  Text('Last ${versions.length} saves', style: GoogleFonts.dmSans(fontSize: 12, color: NoveColors.mutedText(ctx))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (versions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Text('No versions saved yet.\nAutosave creates a snapshot every 3 seconds.', textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: NoveColors.mutedText(ctx))),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: versions.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final v = versions[i];
                    final ts = DateTime.fromMillisecondsSinceEpoch(v.updatedAt);
                    return ListTile(
                      title: Text(DateFormat('MMM d, y \u2022 h:mm a').format(ts), style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: NoveColors.primaryText(ctx))),
                      subtitle: Text('${v.wordCount} words', style: GoogleFonts.dmSans(fontSize: 12, color: NoveColors.mutedText(ctx))),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _contentController.text = v.content;
                          _titleController.text = v.title == 'Untitled' ? '' : v.title;
                          _onChanged();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Restored to ${DateFormat('MMM d \u2022 h:mm a').format(ts)}')),
                          );
                        },
                        child: Text('Restore', style: GoogleFonts.dmSans(color: NoveColors.accent(ctx), fontWeight: FontWeight.w600)),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

=======
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
  int _getWordCount() => _contentController.text
      .trim()
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .length;

  // ─── Toggles True Zen Mode (Immersive System UI) ──────────────────────────
  void _toggleFocusMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _focusMode = !_focusMode;
      if (_focusMode) {
        // Hides status bar and bottom navigation bar
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        // Restores standard UI
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

<<<<<<< HEAD
  void _toggleFavorite() {
    HapticFeedback.selectionClick();
    setState(() {
      _isFavorite = !_isFavorite;
      _hasChanges = true;
    });
  }

  void _togglePin() {
    HapticFeedback.selectionClick();
    setState(() {
      _isPinned = !_isPinned;
      _hasChanges = true;
    });
  }

=======
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
  Future<void> _showAddCategorySheet() async {
    final controller = TextEditingController();
    final presets = ['Finance', 'Health', 'Travel', 'Learning', 'Reading', 'Shopping'];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NoveColors.cardBg(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New category',
                  style: GoogleFonts.lora(
                      fontSize: 18, fontWeight: FontWeight.w600, color: NoveColors.primaryText(ctx))),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.dmSans(color: NoveColors.primaryText(ctx), fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'e.g. "Finance"',
                  hintStyle: GoogleFonts.dmSans(color: NoveColors.mutedText(ctx)),
                  filled: true,
                  fillColor: NoveColors.inputBg(ctx),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(NoveRadii.lg),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: presets.where((p) => !_availableCategories.contains(p)).map((p) {
                  return GestureDetector(
                    onTap: () {
                      controller.text = p;
                      controller.selection = TextSelection.collapsed(offset: p.length);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: NoveColors.inputBg(ctx),
                        borderRadius: BorderRadius.circular(NoveRadii.full),
                      ),
                      child: Text(p, style: GoogleFonts.dmSans(fontSize: 12, color: NoveColors.secondaryText(ctx))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () async {
                    final value = controller.text.trim();
                    if (value.isNotEmpty && !_availableCategories.contains(value)) {
                      await saveCustomCategory(value);
                      await _loadCategories();
                      if (mounted) {
                        setState(() {
                          _selectedCategory = value;
                          _hasChanges = true;
                        });
                      }
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: NoveColors.accent(context),
                      borderRadius: BorderRadius.circular(NoveRadii.lg),
                    ),
                    child: Center(
                      child: Text('Create category',
                          style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

<<<<<<< HEAD
=======
  Widget _buildPreview(BuildContext context) {
    final raw = _contentController.text;
    if (raw.trim().isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Text(
          'Nothing to preview yet.',
          style: NoveTypography.editorFont(
            style: TextStyle(fontSize: 18, color: NoveColors.mutedText(context)),
          ),
        ),
      );
    }

    final lines = raw.split('\n');
    final spans = <Widget>[];

    for (final line in lines) {
      if (line.startsWith('# ')) {
        spans.add(_previewH(line.substring(2), 24, context));
      } else if (line.startsWith('## ')) {
        spans.add(_previewH(line.substring(3), 20, context));
      } else if (line.startsWith('### ')) {
        spans.add(_previewH(line.substring(4), 17, context));
      } else if (line.startsWith('> ')) {
        spans.add(_previewQuote(line.substring(2), context));
      } else if (line.startsWith('• ') || line.startsWith('- ')) {
        spans.add(_previewBullet(line.substring(2), context));
      } else if (line.startsWith('☐ ') || line.startsWith('☑ ')) {
        final done = line.startsWith('☑ ');
        spans.add(_previewCheckbox(line.substring(2), done, context));
      } else if (line.isEmpty) {
        spans.add(const SizedBox(height: 8));
      } else {
        spans.add(_previewParagraph(line, context));
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      children: spans,
    );
  }

  Widget _previewH(String text, double size, BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 8),
        child: Text(text,
            style: GoogleFonts.lora(
                fontSize: size, fontWeight: FontWeight.w600, color: NoveColors.primaryText(context), height: 1.3)),
      );

  Widget _previewQuote(String text, BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: NoveColors.accent(context), width: 3)),
        ),
        child: Text(text,
            style: GoogleFonts.lora(
                fontSize: 16, fontStyle: FontStyle.italic, color: NoveColors.secondaryText(context), height: 1.6)),
      );

  Widget _previewBullet(String text, BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 7, right: 10),
              child: Container(
                  width: 5, height: 5, decoration: BoxDecoration(color: NoveColors.accent(context), shape: BoxShape.circle)),
            ),
            Expanded(child: _richText(text, 16, context)),
          ],
        ),
      );

  Widget _previewCheckbox(String text, bool done, BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              size: 18,
              color: done ? NoveColors.accent(context) : NoveColors.mutedText(context),
            ),
            const SizedBox(width: 8),
            Expanded(child: _richText(text, 16, context)),
          ],
        ),
      );

  Widget _previewParagraph(String text, BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: _richText(text, 18, context),
      );

  Widget _richText(String text, double size, BuildContext context) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*|_(.+?)_');
    int last = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      if (match.group(1) != null) {
        spans.add(TextSpan(text: match.group(1), style: const TextStyle(fontWeight: FontWeight.w700)));
      } else if (match.group(2) != null) {
        spans.add(TextSpan(text: match.group(2), style: const TextStyle(fontStyle: FontStyle.italic)));
      }
      last = match.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));

    return RichText(
      text: TextSpan(
        style: GoogleFonts.lora(fontSize: size, height: 1.6, color: NoveColors.primaryText(context)),
        children: spans,
      ),
    );
  }

>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wordCount = _getWordCount();
    final readTime = (wordCount / 200).ceil().clamp(1, 99);

    return Scaffold(
      backgroundColor: NoveColors.bg(context),
<<<<<<< HEAD
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
              backgroundColor: NoveColors.cardBg(context),
              elevation: 4,
              onPressed: () {
                _editorScrollController.animateTo(
                  0,
                  duration: NoveAnimation.normal,
                  curve: NoveAnimation.snappy,
                );
              },
              child: Icon(Icons.keyboard_arrow_up_rounded, color: NoveColors.accent(context)),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
=======
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ─────────────────────────────────────────────────
            AnimatedContainer(
              duration: NoveAnimation.fast,
              padding: EdgeInsets.symmetric(
                horizontal: 16, 
                vertical: _focusMode ? 8 : 12 // Shrink slightly in focus mode
              ),
              decoration: BoxDecoration(
                color: NoveColors.bg(context),
                border: Border(
                  bottom: BorderSide(
                    color: _focusMode ? Colors.transparent : NoveColors.cardBorder(context), 
                    width: 0.5
                  ),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _saveAndClose,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16, color: NoveColors.secondaryText(context)),
                        const SizedBox(width: 4),
                        Text('Notes',
                            style: GoogleFonts.dmSans(
                              fontSize: 15, fontWeight: FontWeight.w500, color: NoveColors.secondaryText(context),
                            )),
                      ],
                    ),
                  ),
                  const Spacer(),
<<<<<<< HEAD
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _FormatIconBtn(
                            icon: _focusMode ? Icons.center_focus_weak : Icons.center_focus_strong,
                            tooltip: 'Focus Mode',
                            onTap: _toggleFocusMode,
                            isDark: isDark,
                            expand: false,
                          ),
                          _FormatIconBtn(
                            icon: _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                            tooltip: 'Favorite',
                            onTap: _toggleFavorite,
                            isDark: isDark,
                            expand: false,
                          ),
                          _FormatIconBtn(
                            icon: _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                            tooltip: 'Pin',
                            onTap: _togglePin,
                            isDark: isDark,
                            expand: false,
                          ),
                          if (!_isNewNote && widget.note != null)
                            _FormatIconBtn(
                              icon: Icons.history_rounded,
                              tooltip: 'History',
                              onTap: _showVersionHistory,
                              isDark: isDark,
                              expand: false,
                            ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _saveAndClose,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: NoveColors.accent(context),
                                borderRadius: BorderRadius.circular(NoveRadii.full),
                                boxShadow: [
                                  BoxShadow(
                                    color: NoveColors.accent(context).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text('Done',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
                                  )),
                            ),
=======

                  if (!_focusMode) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: NoveColors.inputBg(context),
                        borderRadius: BorderRadius.circular(NoveRadii.full),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ToggleSegment(
                            label: 'Edit',
                            isActive: !_isPreviewMode,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _isPreviewMode = false);
                            },
                          ),
                          _ToggleSegment(
                            label: 'Preview',
                            isActive: _isPreviewMode,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _isPreviewMode = true);
                            },
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
                          ),
                        ],
                      ),
                    ),
<<<<<<< HEAD
                  ),
=======
                    const SizedBox(width: 8),
                  ],

                  // Focus toggle
                  GestureDetector(
                    onTap: _toggleFocusMode,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _focusMode ? NoveColors.accent(context).withOpacity(0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(NoveRadii.full),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _focusMode ? Icons.fullscreen_exit_rounded : Icons.center_focus_strong_outlined,
                            size: 14,
                            color: _focusMode ? NoveColors.accent(context) : NoveColors.mutedText(context)
                          ),
                          const SizedBox(width: 4),
                          Text(_focusMode ? 'Exit Zen' : 'Focus',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: _focusMode ? NoveColors.accent(context) : NoveColors.mutedText(context),
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  if (!_focusMode) ...[
                    // Pin button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _isPinned = !_isPinned;
                          _hasChanges = true;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _isPinned ? NoveColors.accent(context).withOpacity(0.12) : NoveColors.cardBg(context),
                          borderRadius: BorderRadius.circular(NoveRadii.sm),
                          border: Border.all(color: NoveColors.cardBorder(context), width: 0.5),
                        ),
                        child: Icon(
                            _isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                            size: 18,
                            color: _isPinned ? NoveColors.accent(context) : NoveColors.mutedText(context)),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Done button
                    GestureDetector(
                      onTap: _saveAndClose,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: NoveColors.accent(context),
                          borderRadius: BorderRadius.circular(NoveRadii.full),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 5),
                            Text('Done',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ]
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
                ],
              ),
            ),

            if (!_focusMode)
              Container(
                decoration: BoxDecoration(
                  color: NoveColors.bg(context),
                  border: Border(bottom: BorderSide(color: NoveColors.cardBorder(context), width: 0.5)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
<<<<<<< HEAD
=======
                      readOnly: _isPreviewMode,
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.lora(
                        fontSize: 22, fontWeight: FontWeight.w600, color: NoveColors.primaryText(context), height: 1.3,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Title',
                        hintStyle: GoogleFonts.lora(
                          fontSize: 22, fontWeight: FontWeight.w600, color: NoveColors.mutedText(context), height: 1.3,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onChanged: (_) => Future.delayed(const Duration(seconds: 3), _autoSave),
                    ),
                    const SizedBox(height: 8),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _CategoryChip(
                            label: 'None',
                            isActive: _selectedCategory.isEmpty,
<<<<<<< HEAD
                            onTap: () {
=======
                            onTap: _isPreviewMode ? null : () {
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedCategory = '';
                                _hasChanges = true;
                              });
                            },
                            context: context,
                          ),
                          const SizedBox(width: 6),
                          ..._availableCategories.map((cat) {
                            final isActive = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: _CategoryChip(
                                label: cat,
                                isActive: isActive,
<<<<<<< HEAD
                                onTap: () {
=======
                                onTap: _isPreviewMode ? null : () {
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _selectedCategory = isActive ? '' : cat;
                                    _hasChanges = true;
                                  });
                                },
                                context: context,
                              ),
                            );
                          }),

<<<<<<< HEAD
=======
                          if (!_isPreviewMode)
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _showAddCategorySheet();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(NoveRadii.full),
<<<<<<< HEAD
                                  border: Border.all(color: NoveColors.accent(context).withValues(alpha: 0.5), width: 0.5),
=======
                                  border: Border.all(color: NoveColors.accent(context).withOpacity(0.5), width: 0.5),
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, size: 12, color: NoveColors.accent(context)),
                                    const SizedBox(width: 3),
                                    Text('New',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12, fontWeight: FontWeight.w600, color: NoveColors.accent(context),
                                        )),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(width: 12),
                          Text(
                            DateFormat('MMM d, yyyy').format(
                              widget.note != null
                                  ? DateTime.fromMillisecondsSinceEpoch(widget.note!.updatedAt)
                                  : DateTime.now(),
                            ),
                            style: GoogleFonts.dmSans(fontSize: 11, color: NoveColors.mutedText(context)),
                          ),
                        ],
                      ),
                    ),

<<<<<<< HEAD
                    const SizedBox(height: 8),
=======
                    if (!_isPreviewMode) ...[
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Color:',
                              style: GoogleFonts.dmSans(
                                fontSize: 11, fontWeight: FontWeight.w600, color: NoveColors.mutedText(context),
                              )),
                          const SizedBox(width: 8),
<<<<<<< HEAD
                          ...kNoteColorLabels.map((c) {
=======
                          ..._colorLabels.map((c) {
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
                            final isSelected = _selectedColor == c;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedColor = c;
                                  _hasChanges = true;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: c == '#FFFFFF'
                                      ? Colors.transparent
                                      : Color(int.parse(c.replaceFirst('#', '0xFF'))),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? NoveColors.primaryText(context) : NoveColors.warmGray300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: c == '#FFFFFF' ? Icon(Icons.close, size: 10, color: NoveColors.warmGray400) : null,
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
<<<<<<< HEAD
=======
                  ],
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
                ),
              ),

            // ── Editor Body / Preview ─────────────────────────────────────
            Expanded(
<<<<<<< HEAD
              child: Stack(
=======
              child: _isPreviewMode
                  ? _buildPreview(context)
                  : Stack(
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
                      children: [
                        if (!_focusMode)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: RuledBackgroundPainter(
                                lineColor: isDark
<<<<<<< HEAD
                                    ? NoveColors.warmGray800.withValues(alpha: 0.6)
                                    : NoveColors.warmGray200.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: TextField(
                              controller: _contentController,
                              maxLines: null,
                              expands: true,
                              autofocus: _isNewNote,
                              textAlignVertical: TextAlignVertical.top,
                              cursorColor: NoveColors.accent(context),
                              cursorWidth: 2,
                              onChanged: (_) {},
                              style: NoveTypography.editorFont(
                                style: TextStyle(fontSize: 18, color: NoveColors.primaryText(context)),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Write freely. Nothing leaves this device.',
                                hintStyle: NoveTypography.editorFont(
                                  style: TextStyle(fontSize: 18, color: NoveColors.mutedText(context)),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 24),
                              ),
=======
                                    ? NoveColors.warmGray800.withOpacity(0.6)
                                    : NoveColors.warmGray200.withOpacity(0.5),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: TextField(
                            controller: _contentController,
                            maxLines: null,
                            expands: true,
                            autofocus: _isNewNote,
                            textAlignVertical: TextAlignVertical.top,
                            cursorColor: NoveColors.accent(context),
                            cursorWidth: 2,
                            onChanged: (_) => Future.delayed(const Duration(seconds: 3), _autoSave),
                            style: NoveTypography.editorFont(
                              style: TextStyle(fontSize: 18, color: NoveColors.primaryText(context)),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Write freely. Nothing leaves this device.',
                              hintStyle: NoveTypography.editorFont(
                                style: TextStyle(fontSize: 18, color: NoveColors.mutedText(context)),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 24),
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

<<<<<<< HEAD
            if (!_focusMode)
=======
            if (!_focusMode && !_isPreviewMode)
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                decoration: BoxDecoration(
                  color: NoveColors.cardBg(context),
                  borderRadius: BorderRadius.circular(NoveRadii.sm),
                  border: Border.all(color: NoveColors.cardBorder(context), width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _FormatBtn(label: 'B', bold: true, onTap: () => _insertFormatting('**', '**'), isDark: isDark),
                    _FmtDivider(),
                    _FormatBtn(label: 'I', italic: true, onTap: () => _insertFormatting('_', '_'), isDark: isDark),
                    _FmtDivider(),
<<<<<<< HEAD
                    _FormatBtn(label: '`', onTap: () => _insertFormatting('`', '`'), isDark: isDark),
                    _FmtDivider(),
=======
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
                    _FormatIconBtn(icon: Icons.format_list_bulleted_rounded, tooltip: 'Bullet list', onTap: () => _insertFormatting('• '), isDark: isDark),
                    _FmtDivider(),
                    _FormatIconBtn(icon: Icons.check_box_outlined, tooltip: 'Checkbox', onTap: () => _insertFormatting('☐ '), isDark: isDark),
                    _FmtDivider(),
                    _FormatBtn(label: 'H', onTap: () => _insertFormatting('# '), isDark: isDark),
                    _FmtDivider(),
                    _FormatIconBtn(icon: Icons.format_quote_rounded, tooltip: 'Quote', onTap: () => _insertFormatting('> '), isDark: isDark),
<<<<<<< HEAD
                    _FmtDivider(),
                    _FormatIconBtn(icon: Icons.image_outlined, tooltip: 'Insert image', onTap: _insertImage, isDark: isDark),
                    _FmtDivider(),
                    _FormatIconBtn(icon: Icons.search_rounded, tooltip: 'Find & Replace', onTap: () { HapticFeedback.lightImpact(); setState(() => _showFindReplace = !_showFindReplace); }, isDark: isDark),
=======
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
                  ],
                ),
              ),

<<<<<<< HEAD
            // ── Find & Replace Bar ───────────────────────────────────
            AnimatedContainer(
              duration: NoveAnimation.fast,
              height: _showFindReplace ? null : 0,
              child: _showFindReplace
                  ? Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: NoveColors.cardBg(context),
                        borderRadius: BorderRadius.circular(NoveRadii.sm),
                        border: Border.all(color: NoveColors.cardBorder(context), width: 0.5),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _findController,
                                  onChanged: (_) => _updateFindMatches(),
                                  style: GoogleFonts.dmSans(fontSize: 13, color: NoveColors.primaryText(context)),
                                  decoration: InputDecoration(
                                    hintText: 'Find...',
                                    hintStyle: GoogleFonts.dmSans(fontSize: 13, color: NoveColors.mutedText(context)),
                                    isDense: true,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                  ),
                                ),
                              ),
                              if (_findMatches.isNotEmpty)
                                Text('${_findMatchIndex + 1}/${_findMatches.length}',
                                    style: GoogleFonts.dmSans(fontSize: 11, color: NoveColors.mutedText(context))),
                              const SizedBox(width: 4),
                              IconButton(constraints: const BoxConstraints(minWidth: 32, minHeight: 32), padding: EdgeInsets.zero, icon: const Icon(Icons.keyboard_arrow_up, size: 18), onPressed: () => _navigateMatch(-1)),
                              IconButton(constraints: const BoxConstraints(minWidth: 32, minHeight: 32), padding: EdgeInsets.zero, icon: const Icon(Icons.keyboard_arrow_down, size: 18), onPressed: () => _navigateMatch(1)),
                              IconButton(constraints: const BoxConstraints(minWidth: 32, minHeight: 32), padding: EdgeInsets.zero, icon: const Icon(Icons.close, size: 16), onPressed: () { setState(() { _showFindReplace = false; _findController.clear(); _replaceController.clear(); _findMatches = []; }); }),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _replaceController,
                                  style: GoogleFonts.dmSans(fontSize: 13, color: NoveColors.primaryText(context)),
                                  decoration: InputDecoration(
                                    hintText: 'Replace with...',
                                    hintStyle: GoogleFonts.dmSans(fontSize: 13, color: NoveColors.mutedText(context)),
                                    isDense: true,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                  ),
                                ),
                              ),
                              TextButton(onPressed: _replaceCurrentMatch, child: Text('Replace', style: GoogleFonts.dmSans(fontSize: 12, color: NoveColors.accent(context), fontWeight: FontWeight.w600))),
                              TextButton(onPressed: _replaceAllMatches, child: Text('All', style: GoogleFonts.dmSans(fontSize: 12, color: NoveColors.accent(context), fontWeight: FontWeight.w600))),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

=======
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
            if (!_focusMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: NoveColors.bg(context),
                  border: Border(top: BorderSide(color: NoveColors.cardBorder(context), width: 0.5)),
                ),
                child: Row(
                  children: [
                    Text(
                      '$wordCount words · $readTime min',
                      style: GoogleFonts.dmSans(
                        fontSize: 11, fontWeight: FontWeight.w600, color: NoveColors.mutedText(context), letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
<<<<<<< HEAD
=======
                    if (_isPreviewMode)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: NoveColors.accent(context).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(NoveRadii.full),
                        ),
                        child: Text(
                          'Read-only preview',
                          style: GoogleFonts.dmSans(
                            fontSize: 10, color: NoveColors.accent(context), fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: _isSaved ? 1 : 0,
                      duration: NoveAnimation.fast,
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 12, color: NoveColors.accent(context)),
                          const SizedBox(width: 4),
                          Text('Saved',
                              style: GoogleFonts.dmSans(
                                fontSize: 11, fontWeight: FontWeight.w600, color: NoveColors.accent(context),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

<<<<<<< HEAD
=======
class _ToggleSegment extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ToggleSegment({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: NoveAnimation.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? NoveColors.cardBg(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(NoveRadii.full),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1))] : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12, fontWeight: isActive ? FontWeight.w700 : FontWeight.w500, color: isActive ? NoveColors.primaryText(context) : NoveColors.mutedText(context),
          ),
        ),
      ),
    );
  }
}
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;
  final BuildContext context;

  const _CategoryChip({required this.label, required this.isActive, required this.onTap, required this.context});

  @override
  Widget build(BuildContext _) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: NoveAnimation.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? NoveColors.accent(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(NoveRadii.full),
          border: Border.all(color: isActive ? Colors.transparent : NoveColors.cardBorder(context), width: 0.5),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? Colors.white : NoveColors.secondaryText(context),
          ),
        ),
      ),
    );
  }
}

class RuledBackgroundPainter extends CustomPainter {
  final Color lineColor;
  const RuledBackgroundPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = lineColor..strokeWidth = 0.5;
    const double lineHeight = 39.0;
    const double topOffset = 62.0;
    for (double y = topOffset; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(24, y), Offset(size.width - 24, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant RuledBackgroundPainter old) => old.lineColor != lineColor;
}

class _FormatBtn extends StatelessWidget {
  final String label;
  final bool bold;
  final bool italic;
  final VoidCallback onTap;
  final bool isDark;

  const _FormatBtn({required this.label, required this.onTap, required this.isDark, this.bold = false, this.italic = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 15, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, fontStyle: italic ? FontStyle.italic : FontStyle.normal, color: NoveColors.secondaryText(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormatIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDark;
<<<<<<< HEAD
  final bool expand;

  const _FormatIconBtn({required this.icon, required this.tooltip, required this.onTap, required this.isDark, this.expand = true});

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Center(child: Icon(icon, size: 18, color: NoveColors.secondaryText(context))),
      ),
    );
    return expand ? Expanded(child: child) : child;
=======

  const _FormatIconBtn({required this.icon, required this.tooltip, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(child: Icon(icon, size: 18, color: NoveColors.secondaryText(context))),
        ),
      ),
    );
>>>>>>> 89545a56f2292ebb16fde939916540c4a792ef7f
  }
}

class _FmtDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 0.5, height: 20, color: NoveColors.cardBorder(context));
  }
}