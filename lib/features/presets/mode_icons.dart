import 'package:flutter/material.dart';

import '../../ble/ble_models.dart';

extension ControlModeIcon on ControlMode {
  IconData get icon => switch (this) {
        ControlMode.pulse => Icons.adjust_rounded,
        ControlMode.wave => Icons.waves_rounded,
        ControlMode.rhythm => Icons.equalizer_rounded,
        ControlMode.custom => Icons.tune_rounded,
      };
}
