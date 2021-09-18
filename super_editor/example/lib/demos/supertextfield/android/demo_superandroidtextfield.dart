import 'package:example/demos/supertextfield/_mobile_textfield_demo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

/// Demo of [SuperAndroidTextField].
class SuperAndroidTextFieldDemo extends StatefulWidget {
  @override
  _SuperAndroidTextFieldDemoState createState() => _SuperAndroidTextFieldDemoState();
}

class _SuperAndroidTextFieldDemoState extends State<SuperAndroidTextFieldDemo> {
  @override
  Widget build(BuildContext context) {
    return MobileSuperTextFieldDemo(
      createTextField: _buildTextField,
    );
  }

  Widget _buildTextField(MobileTextFieldDemoConfig config) {
    final genericTextStyle = config.styleBuilder({});
    final lineHeight = genericTextStyle.fontSize! * (genericTextStyle.height ?? 1.0);

    return SuperAndroidTextfield(
      textController: config.controller,
      textStyleBuilder: config.styleBuilder,
      selectionColor: Colors.blue.withOpacity(0.4),
      caretColor: Colors.green,
      handlesColor: Colors.lightGreen,
      minLines: config.minLines,
      maxLines: config.maxLines,
      lineHeight: lineHeight,
      textInputAction: TextInputAction.done,
      showDebugPaint: config.showDebugPaint,
    );
  }
}
