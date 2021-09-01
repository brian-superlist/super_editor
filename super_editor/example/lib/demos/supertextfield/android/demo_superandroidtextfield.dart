import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:super_editor/super_editor.dart';

/// Demo of [SuperAndroidTextField].
class SuperAndroidTextFieldDemo extends StatefulWidget {
  @override
  _SuperAndroidTextFieldDemoState createState() => _SuperAndroidTextFieldDemoState();
}

class _SuperAndroidTextFieldDemoState extends State<SuperAndroidTextFieldDemo> {
  final _screenFocusNode = FocusNode();
  final _textController = AttributedTextEditingController(
      text: AttributedText(
          text:
              'This is a custom textfield implementation called SuperAndroidTextField. It is super long so that we can mess with scrolling. This drags it out even further so that we can get multiline scrolling, too. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin tempor sapien est, in eleifend purus rhoncus fringilla. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Nulla varius libero lorem, eget tincidunt ante porta accumsan. Morbi quis ante at nunc molestie ullamcorper.'));

  _TextFieldSizeMode _sizeMode = _TextFieldSizeMode.short;

  bool _showDebugPaint = false;

  @override
  void initState() {
    super.initState();

    initLoggers(Level.FINE, [textFieldLog, androidTextFieldLog]);
  }

  @override
  void dispose() {
    deactivateLoggers([textFieldLog, androidTextFieldLog]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          _screenFocusNode.requestFocus();
        },
        behavior: HitTestBehavior.translucent,
        child: Focus(
          focusNode: _screenFocusNode,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _showDebugPaint = !_showDebugPaint;
          });
        },
        child: const Icon(Icons.bug_report),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _sizeMode == _TextFieldSizeMode.singleLine
            ? 0
            : _sizeMode == _TextFieldSizeMode.short
                ? 1
                : 2,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.short_text),
            label: 'Single Line',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wrap_text_rounded),
            label: 'Short',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wrap_text_rounded),
            label: 'Tall',
          ),
        ],
        onTap: (int newIndex) {
          setState(() {
            if (newIndex == 0) {
              _sizeMode = _TextFieldSizeMode.singleLine;
            } else if (newIndex == 1) {
              _sizeMode = _TextFieldSizeMode.short;
            } else if (newIndex == 2) {
              _sizeMode = _TextFieldSizeMode.tall;
            }
          });
        },
      ),
    );
  }

  Widget _buildTextField() {
    int? minLines;
    int? maxLines;
    switch (_sizeMode) {
      case _TextFieldSizeMode.singleLine:
        minLines = 1;
        maxLines = 1;
        break;
      case _TextFieldSizeMode.short:
        maxLines = 5;
        break;
      case _TextFieldSizeMode.tall:
        // no-op
        break;
    }

    final genericTextStyle = _styleBuilder({});
    final lineHeight = genericTextStyle.fontSize! * (genericTextStyle.height ?? 1.0);

    return SuperAndroidTextfield(
      textController: _textController,
      textStyleBuilder: _styleBuilder,
      selectionColor: Colors.blue.withOpacity(0.4),
      caretColor: Colors.green,
      handlesColor: Colors.lightGreen,
      minLines: minLines,
      maxLines: maxLines,
      lineHeight: lineHeight,
      textInputAction: TextInputAction.done,
      showDebugPaint: _showDebugPaint,
    );
  }

  TextStyle _styleBuilder(Set<Attribution> attributions) {
    return const TextStyle(
      color: Colors.black,
      fontSize: 16,
      height: 1.4,
    );
  }
}

enum _TextFieldSizeMode {
  singleLine,
  short,
  tall,
}
