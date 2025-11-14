import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthField extends StatefulWidget {
  final String hintText;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final IconData? prefixIcon; // keeps your IconData API
  final Color? fillColor;

  // NEW (optional) form-related props
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final int? maxLines; // ignored for password (stays 1)
  final AutovalidateMode? autovalidateMode;

  const AuthField({
    super.key,
    required this.hintText,
    this.isPassword = false,
    this.controller,
    this.keyboardType,
    this.prefixIcon,
    this.fillColor,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction,
    this.inputFormatters,
    this.readOnly = false,
    this.maxLines = 1,
    this.autovalidateMode,
  });

  @override
  _AuthFieldState createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _isObscured = true; // for password visibility toggle

  @override
  Widget build(BuildContext context) {
    final bool isPwd = widget.isPassword;

    return TextFormField(
      controller: widget.controller,
      obscureText: isPwd ? _isObscured : false,
      keyboardType: widget.keyboardType,
      validator: widget.validator, // ✅ enables Form validation
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      readOnly: widget.readOnly,
      autovalidateMode: widget.autovalidateMode,
      maxLines: isPwd ? 1 : (widget.maxLines ?? 1),
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        filled: widget.fillColor != null,
        fillColor: widget.fillColor ?? Colors.grey.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),

        // Focused border (shown when focused AND no error)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
        ),

        // Error borders are used automatically by TextFormField when validator returns a string
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),

        // Password visibility toggle
        suffixIcon: isPwd
            ? IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () => setState(() => _isObscured = !_isObscured),
              )
            : null,
      ),
    );
  }
}
