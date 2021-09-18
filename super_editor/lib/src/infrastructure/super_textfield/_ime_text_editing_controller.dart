import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/src/infrastructure/attributed_spans.dart';
import 'package:super_editor/src/infrastructure/attributed_text.dart';
import 'package:super_editor/src/infrastructure/super_textfield/super_textfield.dart';

import '../_logging.dart';

final _log = imeTextFieldLog;

/// An [AttributedTextEditingController] that integrates the platform's Input
/// Method Engine (IME) changes into the text, selection, and composing region
/// of a text field's content.
///
/// On mobile, all user input must pass through the platform IME, therefore this
/// integration is required for any mobile text field. On desktop, an app developer
/// can choose between the IME and direct keyboard interaction. An app developer can
/// use this controller on desktop to reflect IME changes, just like on mobile. By
/// using the IME on desktop, apps gain access to auto-correction and language
/// composition features.
///
/// Rather than re-implement all of [AttributedTextEditingController],
/// [ImeAttributedTextEditingController] wraps another [AttributedTextEditingController]
/// and defers to that controller wherever possible.
///
/// By default, an [ImeAttributedTextEditingController] is not connect to the platform
/// IME. To connect to the IME, call `attachToIme`. To detach from the IME, call
/// `detachFromIme`.
class ImeAttributedTextEditingController
    with ChangeNotifier
    implements AttributedTextEditingController, TextInputClient {
  ImeAttributedTextEditingController({
    final AttributedTextEditingController? controller,
  }) : _realController = controller ?? AttributedTextEditingController();

  @override
  void dispose() {
    _realController.dispose();
    super.dispose();
  }

  final AttributedTextEditingController _realController;

  TextInputConnection? _inputConnection;
  bool _isKeyboardDisplayDesired = false;

  void attachToIme({
    bool autocorrect = true,
    bool enableSuggestions = true,
    TextInputAction textInputAction = TextInputAction.done,
  }) {
    if (_inputConnection != null) {
      // We're already connected to the IME.
      return;
    }

    _inputConnection = TextInput.attach(
        this,
        TextInputConfiguration(
          autocorrect: autocorrect,
          enableDeltaModel: true,
          enableSuggestions: enableSuggestions,
          inputAction: textInputAction,
        ));
    _inputConnection!
      ..show()
      ..setEditingState(currentTextEditingValue!);
  }

  void detachFromIme() {
    // TODO:
  }

  void showKeyboard() {
    _isKeyboardDisplayDesired = true;
    _inputConnection?.show();
  }

  void toggleKeyboard() {
    _isKeyboardDisplayDesired = !_isKeyboardDisplayDesired;
    if (_isKeyboardDisplayDesired) {
      _inputConnection?.show();
    } else {
      _inputConnection?.close();
    }
  }

  void hideKeyboard() {
    _isKeyboardDisplayDesired = false;
    _inputConnection?.close();
  }

  //------ Start TextInputClient ----
  TextEditingValue? _latestPlatformTextEditingValue;

  void Function(TextInputAction)? _onPerformActionPressed;
  set onPerformActionPressed(Function(TextInputAction)? callback) => _onPerformActionPressed = callback;

  @override
  TextEditingValue? get currentTextEditingValue => TextEditingValue(
        text: text.text,
        selection: selection,
        composing: composingRegion,
      );

  @override
  void updateEditingValue(TextEditingValue value) {
    _latestPlatformTextEditingValue = value;
    _log.fine('New platform TextEditingValue: $value');

    if (_latestPlatformTextEditingValue != currentTextEditingValue) {
      this
        ..text = AttributedText(text: value.text)
        ..selection = value.selection
        ..composingRegion = value.composing;
    }
  }

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> deltas) {
    _log.fine('Received text editing deltas from platform...');
    for (final delta in deltas) {
      _log.fine(
          'Text delta: ${delta.deltaType}, range: ${delta.deltaRange}, new selection: ${delta.selection}, new composing: ${delta.composing}');
      switch (delta.deltaType) {
        case TextEditingDeltaType.insertion:
          insert(
            newText: delta.deltaText,
            insertIndex: delta.deltaRange.start,
            newSelection: delta.selection,
          );
          break;
        case TextEditingDeltaType.deletion:
          delete(
            from: delta.deltaRange.start,
            to: delta.deltaRange.end,
            newSelection: delta.selection,
          );
          break;
        case TextEditingDeltaType.replacement:
          replace(
            newText: AttributedText(text: delta.deltaText),
            from: delta.deltaRange.start,
            to: delta.deltaRange.end,
            newSelection: delta.selection,
          );
          break;
        case TextEditingDeltaType.equality:
          // no-op
          break;
      }
    }

    _latestPlatformTextEditingValue = currentTextEditingValue;
  }

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    // No floating cursor on Android.
  }

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  void performAction(TextInputAction action) {
    _onPerformActionPressed?.call(action);
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    // performPrivateCommand() provides a representation for unofficial
    // input commands to be executed. This appears to be an extension point
    // or an escape hatch for input functionality that an app needs to support,
    // but which does not exist at the OS/platform level.
  }

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    // no-op
  }

  @override
  void connectionClosed() {
    _log.info('TextInputClient: connectionClosed()');
    _inputConnection = null;
    _latestPlatformTextEditingValue = null;
  }
  //------ End TextInputClient -----

  @override
  AttributedText get text => _realController.text;
  @override
  set text(AttributedText newValue) => _realController.text = newValue;

  @override
  TextSelection get selection => _realController.selection;
  @override
  set selection(TextSelection newValue) => _realController.selection = newValue;

  @override
  List<Attribution> get composingAttributions => _realController.composingAttributions;
  @override
  set composingAttributions(List<Attribution> attributions) => _realController.composingAttributions = attributions;

  @override
  TextRange get composingRegion => _realController.composingRegion;
  @override
  set composingRegion(TextRange newValue) => _realController.composingRegion = newValue;

  @override
  void insert({
    required String newText,
    required int insertIndex,
    TextSelection? newSelection,
    TextRange? newComposingRegion,
  }) {
    _realController.insert(
      newText: newText,
      insertIndex: insertIndex,
      newSelection: newSelection,
      newComposingRegion: newComposingRegion,
    );
  }

  @override
  void insertAttributedText({
    required AttributedText newText,
    required int insertIndex,
    TextSelection? newSelection,
    TextRange? newComposingRegion,
  }) {
    _realController.insertAttributedText(
      newText: newText,
      insertIndex: insertIndex,
      newSelection: newSelection,
      newComposingRegion: newComposingRegion,
    );
  }

  @override
  void replace({
    required AttributedText newText,
    required int from,
    required int to,
    TextSelection? newSelection,
    TextRange? newComposingRegion,
  }) {
    _realController.replace(
      newText: newText,
      from: from,
      to: to,
      newSelection: newSelection,
      newComposingRegion: newComposingRegion,
    );
  }

  @override
  void delete({required int from, required int to, TextSelection? newSelection, TextRange? newComposingRegion}) {
    _realController.delete(
      from: from,
      to: to,
      newSelection: newSelection,
      newComposingRegion: newComposingRegion,
    );
  }

  @override
  void updateTextAndSelection({required AttributedText text, required TextSelection selection}) {
    _realController.updateTextAndSelection(
      text: text,
      selection: selection,
    );
  }

  @override
  bool isSelectionWithinTextBounds(TextSelection selection) {
    return _realController.isSelectionWithinTextBounds(selection);
  }

  @override
  void toggleSelectionAttributions(List<Attribution> attributions) {
    _realController.toggleSelectionAttributions(attributions);
  }

  @override
  void clearSelectionAttributions() {
    _realController.clearSelectionAttributions();
  }

  @override
  void addComposingAttributions(List<Attribution> attributions) {
    _realController.addComposingAttributions(attributions);
  }

  @override
  void removeComposingAttributions(List<Attribution> attributions) {
    _realController.removeComposingAttributions(attributions);
  }

  @override
  void toggleComposingAttributions(List<Attribution> attributions) {
    _realController.toggleComposingAttributions(attributions);
  }

  @override
  void clearComposingAttributions() {
    _realController.clearComposingAttributions();
  }

  @override
  TextSpan buildTextSpan(AttributionStyleBuilder styleBuilder) {
    return _realController.buildTextSpan(styleBuilder);
  }

  @override
  void clear() {
    _realController.clear();
  }
}
