import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/tokens/app_radii.dart';
import '../../core/design/tokens/app_semantic_colors.dart';
import '../../core/design/tokens/app_spacing.dart';
import '../../core/extensions/context_extensions.dart';
import '../../features/capture/domain/place_suggestions.dart';

/// A name field that helps and never insists.
///
/// The rule it is built around: whatever is typed is the answer. Suggestions
/// are a way to avoid typing a name the app already knows how to spell - they
/// are not a list to pick from, and a restaurant nobody has ever heard of has
/// to be as easy to enter as one that is offered. So this is a plain text
/// field that happens to show matches underneath, rather than a picker with
/// an escape hatch.
class PlaceField extends ConsumerStatefulWidget {
  const PlaceField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.textInputAction,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final TextInputAction? textInputAction;

  @override
  ConsumerState<PlaceField> createState() => _PlaceFieldState();
}

class _PlaceFieldState extends ConsumerState<PlaceField> {
  // Owned here, not built in build(): a FocusNode made on every frame leaks
  // and takes the cursor with it the first time anything above rebuilds.
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Suggestions are a convenience. If they have not loaded, or the read
    // failed, the field is still a field.
    final all = ref.watch(placeSuggestionsProvider).valueOrNull ?? const [];

    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focus,
      optionsBuilder: (value) => matchingPlaces(all, value.text),
      // Selecting only fills the box. It does not lock it: the text stays
      // editable, and typing on changes the answer.
      onSelected: (value) => widget.controller.text = value,
      fieldViewBuilder: (context, textController, focusNode, onSubmitted) {
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          textInputAction: widget.textInputAction,
          textCapitalization: TextCapitalization.words,
          onFieldSubmitted: (_) => onSubmitted(),
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: widget.icon == null
                ? null
                : Icon(widget.icon, size: 20),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: AlignmentDirectional.topStart,
          child: Material(
            elevation: 2,
            borderRadius: AppRadii.controlRadius,
            color: context.colors.surfaceContainerLowest,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 232, maxWidth: 420),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    // The 48dp a finger needs, not the 40 a dense tile gives.
                    minVerticalPadding: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadii.controlRadius,
                    ),
                    leading: Icon(
                      Icons.place_outlined,
                      size: 18,
                      color: context.semantic.accentText,
                    ),
                    title: Text(
                      option,
                      style: context.text.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Spacing between two fields on the same form. Here so the forms that use
/// [PlaceField] do not each invent their own.
const SizedBox fieldGap = SizedBox(height: AppSpacing.lg);
