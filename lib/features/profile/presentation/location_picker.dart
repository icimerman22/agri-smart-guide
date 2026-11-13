import 'package:flutter/material.dart';

import '../domain/farm_location.dart';
import 'profile_keys.dart';

/// Dropdown for choosing the primary location (S06, section "Općenito").
class LocationPicker extends StatelessWidget {
  const LocationPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final FarmLocation? value;
  final ValueChanged<FarmLocation> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final options = [...FarmLocation.croatianCities];
    // Keep a stored location selectable even if it is not in the list.
    final current = value;
    if (current != null && !options.contains(current)) {
      options.insert(0, current);
    }

    // DropdownButton (not DropdownButtonFormField) keeps the code compatible
    // with older Flutter versions used in the team.
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Primarna lokacija (za vremensku prognozu)',
        prefixIcon: Icon(Icons.place_outlined),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FarmLocation>(
          key: ProfileKeys.location,
          value: current,
          isExpanded: true,
          isDense: true,
          hint: const Text('Odaberite lokaciju'),
          items: [
            for (final location in options)
              DropdownMenuItem(value: location, child: Text(location.name)),
          ],
          onChanged: enabled
              ? (location) {
                  if (location != null) onChanged(location);
                }
              : null,
        ),
      ),
    );
  }
}
