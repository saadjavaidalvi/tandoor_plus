import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:user/common/shared.dart';

class PrimaryConfirmButton extends StatelessWidget {
  final String text;
  final bool enabled;
  final void Function() onPressed;

  PrimaryConfirmButton({
    @required this.text,
    @required this.enabled,
    @required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Opacity(
            opacity: enabled ? 1 : 0.4,
            child: ElevatedButton(
              style: ButtonStyle(
                elevation: MaterialStateProperty.all(3),
                backgroundColor: MaterialStateProperty.all(
                  appPrimaryColor,
                ),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              onPressed: () {
                if (enabled) onPressed?.call();
              },
              child: Text(
                text,
                style: AppTextStyle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
