import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:user/common/dividers.dart';
import 'package:user/common/shared.dart';

TextEditingController _instructionsController;

class InstructionsInput extends StatelessWidget {
  final void Function(String) onDone;

  InstructionsInput._(String instructions, this.onDone) {
    _instructionsController = TextEditingController(text: instructions);
  }

  static void showInstructionsInput(
    BuildContext context,
    String instructions,
    void Function(String) onDone,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return InstructionsInput._(instructions, onDone);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text("Instructions"),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextFormField(
            controller: _instructionsController,
            minLines: 4,
            maxLines: 6,
            keyboardType: TextInputType.multiline,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Add instructions here",
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(),
                borderRadius: BorderRadius.all(
                  Radius.circular(8),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(),
                borderRadius: BorderRadius.all(
                  Radius.circular(8),
                ),
              ),
            ),
          ),
        ),
        TDivider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  closeKeyboard(context);
                },
                style: ButtonStyle(
                  elevation: MaterialStateProperty.all(0),
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.pressed))
                        return Colors.grey;
                      return Colors.grey.withOpacity(0.8);
                    },
                  ),
                ),
              ),
              VTDivider(),
              Row(
                children: [
                  ElevatedButton(
                    child: Text(
                      "Save",
                      style: TextStyle(color: Colors.black),
                    ),
                    onPressed: () {
                      onDone(_instructionsController.text);
                      closeKeyboard(context);
                      Navigator.pop(context);
                    },
                    style: ButtonStyle(
                      elevation: MaterialStateProperty.all(0),
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.pressed))
                            return appPrimaryColor;
                          return appPrimaryColor.withOpacity(0.8);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
      backgroundColor: Colors.white,
    );
  }
}
