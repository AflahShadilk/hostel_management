import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_dropdown_field.dart';
import '../cubit/tenant_form_cubit.dart';
import '../cubit/tenant_form_state.dart';

class IdentityDocumentPicker extends StatelessWidget {
  const IdentityDocumentPicker({super.key});

  Future<void> _pickDocument(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      if (!context.mounted) return;
      final sourcePath = result.files.single.path!;
      final extension = p.extension(sourcePath).toLowerCase();
      final isImage =
          ['jpg', 'jpeg', 'png'].contains(extension.replaceAll('.', ''));

      try {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${result.files.single.name}';
        final savedPath = p.join(appDir.path, fileName);

        await File(sourcePath).copy(savedPath);

        if (context.mounted) {
          context.read<TenantFormCubit>().updateDocument(savedPath, isImage);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save document.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TenantFormCubit, TenantFormState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppDropdownField<String>(
              label: 'ID Type (optional)',
              value: state.selectedIdType,
              items: const [
                'Aadhaar Card',
                'Passport',
                'Driving License',
                'Voter ID',
                'Other',
              ],
              itemLabelBuilder: (s) => s,
              onChanged: (val) {
                context.read<TenantFormCubit>().updateIdType(val);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.idDocumentPath == null)
              OutlinedButton.icon(
                onPressed: () => _pickDocument(context),
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Document (Image/PDF)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (state.isDocumentImage)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(
                          File(state.idDocumentPath!),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 48),
                        ),
                      )
                    else
                      const Icon(
                        Icons.picture_as_pdf,
                        size: 48,
                        color: Colors.redAccent,
                      ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.basename(state.idDocumentPath!),
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Tap remove to replace',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.error),
                      onPressed: () {
                        context.read<TenantFormCubit>().clearDocument();
                      },
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
