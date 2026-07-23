import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile(
      {required this.title, this.subtitle, required this.trailing, super.key});
  final String title;
  final String? subtitle;
  final Widget trailing;
  @override
  Widget build(BuildContext context) => ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: trailing);
}
