
import 'package:flutter/material.dart';
import 'package:agri_smart_guide/shared/models/crop.dart';
class CropDetailScreen extends StatelessWidget {
  final Crop crop;

  const CropDetailScreen({
    super.key,
    required this.crop,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(crop.name),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

          Container(
          height: 180,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: crop.imageUrl == null
              ? Icon(
            Icons.eco,
            size: 72,
            color: colors.onPrimaryContainer,
          )
              : Image.network(
            crop.imageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.eco,
                size: 72,
                color: colors.onPrimaryContainer,
              );
            },
          ),
        ),
            const SizedBox(height: 20),
            Text(
              crop.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              crop.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _CropInfoCard(
              icon: Icons.calendar_month_outlined,
              title: 'Preporučeno razdoblje sadnje',
              value: crop.plantingPeriodText,
            ),
            _CropInfoCard(
              icon: Icons.wb_sunny_outlined,
              title: 'Uvjeti uzgoja',
              value: crop.growingConditionsText,
            ),
            _CropInfoCard(
              icon: Icons.schedule,
              title: 'Okvirno trajanje uzgoja',
              value: '${crop.growingDurationDays} dana',
            ),
            _CropInfoCard(
              icon: Icons.water_drop_outlined,
              title: 'Potrebe za vodom',
              value: crop.waterNeeds,
            ),
            const SizedBox(height: 12),
            Text(
              'Podaci su informativni. Uvjeti uzgoja mogu '
                  'ovisiti o sorti, lokaciji i vremenskim prilikama.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CropInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _CropInfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(value),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
