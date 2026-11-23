import 'package:flutter/foundation.dart';

abstract final class PlantingKeys {
  static const openPlantingForm = ValueKey('openPlantingForm');
  static const form = ValueKey('plantingForm');
  static const cropField = ValueKey('plantingCrop');
  static const parcelField = ValueKey('plantingParcel');
  static const dateField = ValueKey('plantingDate');
  static const save = ValueKey('plantingSave');
  static const loading = ValueKey('plantingLoading');
  static const error = ValueKey('plantingError');
  static const noParcels = ValueKey('plantingNoParcels');
  static const replaceConfirm = ValueKey('plantingReplaceConfirm');
  static const replaceCancel = ValueKey('plantingReplaceCancel');
  static const openPlantingList = ValueKey('openPlantingList');
  static const listEmpty = ValueKey('plantingListEmpty');
  static const stageField = ValueKey('plantingStage');
  static const statusSwitch = ValueKey('plantingStatusSwitch');
  static const detailNotFound = ValueKey('plantingDetailNotFound');

  static ValueKey<String> listItem(String plantingId) =>
      ValueKey('plantingItem-$plantingId');
}
