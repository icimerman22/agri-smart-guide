enum PlantingStage {
  planted('planted', 'Posađeno'),
  germination('germination', 'Nicanje'),
  growth('growth', 'Rast'),
  flowering('flowering', 'Cvatnja'),
  fruiting('fruiting', 'Plodonošenje'),
  harvestReady('harvest_ready', 'Spremno za berbu');

  const PlantingStage(this.key, this.label);

  final String key;
  final String label;

  static PlantingStage? fromKey(String key) {
    for (final stage in values) {
      if (stage.key == key) return stage;
    }
    return null;
  }

  static String labelOf(String key) => fromKey(key)?.label ?? key;
}

abstract final class PlantingStatus {
  static const active = 'active';
  static const completed = 'completed';

  static String labelOf(String status) => switch (status) {
    active => 'Aktivna',
    completed => 'Završena',
    _ => status,
  };
}
