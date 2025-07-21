import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool requiredField;
  final bool isSocial;
  final IconData? prefixIcon;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.requiredField = false,
    this.isSocial = false,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        validator: (val) {
          if (requiredField && (val == null || val.isEmpty)) {
            return 'Required';
          }
          // Simple social media handle validation
          if (isSocial && val != null && val.isNotEmpty) {
            final regex = RegExp(r'^[a-zA-Z0-9_.]+$');
            if (!regex.hasMatch(val)) {
              return 'Invalid username format.';
            }
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon:
              isSocial
                  ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(prefixIcon, color: Colors.grey[600]),
                  )
                  : null,
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.black, width: 2),
          ),
        ),
      ),
    );
  }
}
