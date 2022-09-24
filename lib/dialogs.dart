import 'package:flutter/material.dart';

class _AskDeletePermissionDialog extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AskDeletePermissionDialogState();
}

class _AskDeletePermissionDialogState
    extends State<_AskDeletePermissionDialog> {
  bool sure = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Are you sure to delete?"),
      content: CheckboxListTile(
        value: sure,
        title: const Text("I am sure."),
        controlAffinity: ListTileControlAffinity.leading,
        onChanged: (bool? value) {
          setState(() {
            sure = value!;
          });
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, sure),
          child: const Text('Yes'),
        ),
      ],
    );
  }
}

Future<bool> askDeletePermission(BuildContext context) async {
  var dialog = _AskDeletePermissionDialog();
  bool? response =
      await showDialog(context: context, builder: (context) => dialog);
  return response == true;
}
