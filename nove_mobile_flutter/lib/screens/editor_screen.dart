import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

class EditorScreen extends ConsumerStatefulWidget {
  final Note? note;
  const EditorScreen({super.key, this.note});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final ScrollController _editorScrollController = ScrollController();

  late bool _isPinned;
  late bool _isFavorite;
  late bool _isNewNote;
  late String _selectedCategory;
  late String _selectedColor;

  bool _hasChanges = false;
  bool _isSaved = false;
  bool _focusMode = false;
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

  @override
  void initState() {
    super.initState();
    _isNewNote = widget.note == null;
    _initialWordCount = widget.note?.wordCount ?? 0;

    _titleController = TextEditingController(
      text: widget.note?.title == 'Untitled' ? '' : (widget.note?.title ?? ''),
    );
    _contentController = MarkdownEditingController(
      context: context,
      text: widget.note?.content ?? '',
    );

    _isPinned = widget.note?.isPinned ?? false;
    _isFavorite = widget.note?.isFavorite ?? false;
    _selectedCategory = widget.note?.category ?? '';
    _selectedColor = widget.note?.colorLabel ?? '#FFFFFF';

    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);

    _editorScrollController.addListener(() {
      final shouldShow = _editorScrollController.offset > 200;
      if (shouldShow != _showScrollToTop) {
        setState(() => _showScrollToTop = shouldShow);
      }
    });

    _loadCategories();
  }

  void _onChanged() {
    setState(() {
      _hasChanges = true;
      _isSaved = false;
    });
    // Debounced autosave — cancels previous timer before scheduling a new one
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 3), _autoSave);
  }

  Future<void> _loadCategories() async {
    final cats = await CategoryService.loadAllCategories();
    if (mounted) setState(() => _availableCategories = cats);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _titleController.dispose();
    _contentController.dispose();
    _editorScrollController.dispose();
    _findController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  String get _effectiveTitle {
    final t = _titleController.text.trim();
    if (t.isNotEmpty) return t;
    final firstLine = _contentController.text.split('\n').first.trim();
    return firstLine.isEmpty ? 'Untitled' : firstLine;
  }

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

    _recordWordStats();

    if (_isNewNote) {
      await ref.read(notesProvider.notifier).createNote(
            content,
            title: title,
            colorLabel: _selectedColor,
            category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
          );
    } else if (_hasChanges && widget.note != null) {
      // Save a version snapshot before overwriting
      final existing = await DatabaseService.getVersions(widget.note!.id);
      final currentNote = await NoteService.updateNote(
        widget.note!.id,
        title: title,
        content: content,
        isPinned: _isPinned,
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
    }

    HapticFeedback.lightImpact();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _autoSave() async {
    final content = _contentController.text.trim();
    if (!_hasChanges) return;
    
    _recordWordStats();

    if (!_isNewNote && widget.note != null) {
      final updated = await NoteService.updateNote(
        widget.note!.id,
        title: _effectiveTitle,
        content: content,
        isPinned: _isPinned,
        isFavorite: _isFavorite,
        colorLabel: _selectedColor,
        category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
      );
      if (updated != null) await DatabaseService.saveVersion(updated);
      if (mounted) setState(() { _isSaved = true; _hasChanges = false; });
    }
  }

  void _insertFormatting(String prefix, [String? suffix]) {
    HapticFeedback.selectionClick();
    var sel = _contentController.selection;
    if (!sel.isValid) {
      sel = TextSelection.collapsed(offset: _contentController.text.length);
    }
    final text = _contentController.text;
    final selected = sel.textInside(text);
    final replacement = suffix != null ? '$prefix$selected$suffix' : '$prefix$selected';
    final newText = text.replaceRange(sel.start, sel.end, replacement);
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + replacement.length),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wordCount = _getWordCount();
    final readTime = (wordCount / 200).ceil().clamp(1, 99);

    return Scaffold(
      backgroundColor: NoveColors.bg(context),
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
                          ),
                        ],
                      ),
                    ),
                  ),
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
                            onTap: () {
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
                                onTap: () {
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
                                  border: Border.all(color: NoveColors.accent(context).withValues(alpha: 0.5), width: 0.5),
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

                    const SizedBox(height: 8),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Color:',
                              style: GoogleFonts.dmSans(
                                fontSize: 11, fontWeight: FontWeight.w600, color: NoveColors.mutedText(context),
                              )),
                          const SizedBox(width: 8),
                          ...kNoteColorLabels.map((c) {
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
                ),
              ),

            // ── Editor Body / Preview ─────────────────────────────────────
            Expanded(
              child: Stack(
                      children: [
                        if (!_focusMode)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: RuledBackgroundPainter(
                                lineColor: isDark
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
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            if (!_focusMode)
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
                    _FormatBtn(label: '`', onTap: () => _insertFormatting('`', '`'), isDark: isDark),
                    _FmtDivider(),
                    _FormatIconBtn(icon: Icons.format_list_bulleted_rounded, tooltip: 'Bullet list', onTap: () => _insertFormatting('• '), isDark: isDark),
                    _FmtDivider(),
                    _FormatIconBtn(icon: Icons.check_box_outlined, tooltip: 'Checkbox', onTap: () => _insertFormatting('☐ '), isDark: isDark),
                    _FmtDivider(),
                    _FormatBtn(label: 'H', onTap: () => _insertFormatting('# '), isDark: isDark),
                    _FmtDivider(),
                    _FormatIconBtn(icon: Icons.format_quote_rounded, tooltip: 'Quote', onTap: () => _insertFormatting('> '), isDark: isDark),
                    _FmtDivider(),
                    _FormatIconBtn(icon: Icons.image_outlined, tooltip: 'Insert image', onTap: _insertImage, isDark: isDark),
                    _FmtDivider(),
                    _FormatIconBtn(icon: Icons.search_rounded, tooltip: 'Find & Replace', onTap: () { HapticFeedback.lightImpact(); setState(() => _showFindReplace = !_showFindReplace); }, isDark: isDark),
                  ],
                ),
              ),

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
  }
}

class _FmtDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 0.5, height: 20, color: NoveColors.cardBorder(context));
  }
}