import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

class EditorScreen extends ConsumerStatefulWidget {
  final Note? note;
  const EditorScreen({super.key, this.note});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  late bool _isPinned;
  late bool _isNewNote;
  late String _selectedCategory;
  late String _selectedColor;

  bool _hasChanges = false;
  bool _isSaved = false;
  bool _focusMode = false;
  bool _isPreviewMode = false;

  List<String> _availableCategories = [..._builtInCategories];

  @override
  void initState() {
    super.initState();
    _isNewNote = widget.note == null;

    _titleController = TextEditingController(
      text: widget.note?.title == 'Untitled' ? '' : (widget.note?.title ?? ''),
    );
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );

    _isPinned = widget.note?.isPinned ?? false;
    _selectedCategory = widget.note?.category ?? '';
    _selectedColor = widget.note?.colorLabel ?? '#FFFFFF';

    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);

    _loadCategories();
  }

  void _onChanged() {
    setState(() {
      _hasChanges = true;
      _isSaved = false;
    });
  }

  Future<void> _loadCategories() async {
    final cats = await loadAllCategories();
    if (mounted) setState(() => _availableCategories = cats);
  }

  @override
  void dispose() {
    // Ensure we restore standard UI mode if the user leaves while in Zen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String get _effectiveTitle {
    final t = _titleController.text.trim();
    if (t.isNotEmpty) return t;
    final firstLine = _contentController.text.split('\n').first.trim();
    return firstLine.isEmpty ? 'Untitled' : firstLine;
  }

  Future<void> _saveAndClose() async {
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

    if (_isNewNote) {
      await ref.read(notesProvider.notifier).createNote(
            content,
            title: title,
            colorLabel: _selectedColor,
            category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
          );
    } else if (_hasChanges && widget.note != null) {
      await NoteService.updateNote(
        widget.note!.id,
        title: title,
        content: content,
        isPinned: _isPinned,
        colorLabel: _selectedColor,
        category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
      );
    }

    HapticFeedback.lightImpact();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _autoSave() async {
    final content = _contentController.text.trim();
    if (!_hasChanges) return;
    if (!_isNewNote && widget.note != null) {
      await NoteService.updateNote(
        widget.note!.id,
        title: _effectiveTitle,
        content: content,
        isPinned: _isPinned,
        colorLabel: _selectedColor,
        category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
      );
      if (mounted) setState(() { _isSaved = true; _hasChanges = false; });
    }
  }

  void _insertFormatting(String prefix, [String? suffix]) {
    HapticFeedback.selectionClick(); // Tactile feedback for formatting
    final sel = _contentController.selection;
    if (!sel.isValid) return;
    final text = _contentController.text;
    final selected = sel.textInside(text);
    final replacement = suffix != null ? '$prefix$selected$suffix' : '$prefix$selected';
    final newText = text.replaceRange(sel.start, sel.end, replacement);
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + replacement.length),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wordCount = _getWordCount();
    final readTime = (wordCount / 200).ceil().clamp(1, 99);

    return Scaffold(
      backgroundColor: NoveColors.bg(context),
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
                          ),
                        ],
                      ),
                    ),
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
                      readOnly: _isPreviewMode,
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
                            onTap: _isPreviewMode ? null : () {
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
                                onTap: _isPreviewMode ? null : () {
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

                          if (!_isPreviewMode)
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
                                  border: Border.all(color: NoveColors.accent(context).withOpacity(0.5), width: 0.5),
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

                    if (!_isPreviewMode) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Color:',
                              style: GoogleFonts.dmSans(
                                fontSize: 11, fontWeight: FontWeight.w600, color: NoveColors.mutedText(context),
                              )),
                          const SizedBox(width: 8),
                          ..._colorLabels.map((c) {
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
                  ],
                ),
              ),

            // ── Editor Body / Preview ─────────────────────────────────────
            Expanded(
              child: _isPreviewMode
                  ? _buildPreview(context)
                  : Stack(
                      children: [
                        if (!_focusMode)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: RuledBackgroundPainter(
                                lineColor: isDark
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
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            if (!_focusMode && !_isPreviewMode)
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
                    _FormatIconBtn(icon: Icons.format_list_bulleted_rounded, tooltip: 'Bullet list', onTap: () => _insertFormatting('• '), isDark: isDark),
                    _FmtDivider(),
                    _FormatIconBtn(icon: Icons.check_box_outlined, tooltip: 'Checkbox', onTap: () => _insertFormatting('☐ '), isDark: isDark),
                    _FmtDivider(),
                    _FormatBtn(label: 'H', onTap: () => _insertFormatting('# '), isDark: isDark),
                    _FmtDivider(),
                    _FormatIconBtn(icon: Icons.format_quote_rounded, tooltip: 'Quote', onTap: () => _insertFormatting('> '), isDark: isDark),
                  ],
                ),
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
  }
}

class _FmtDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 0.5, height: 20, color: NoveColors.cardBorder(context));
  }
}