import 'package:flutter/material.dart';
import 'package:rail_live/app_constant.dart';

class CoachUtils {
  CoachUtils._();

  static Color bgColor(String type) {
    switch (type.toUpperCase()) {
      case '1A':
        return RailLiveColors.qaPurple;
      case '2A':
        return RailLiveColors.qaGreen;
      case '3A':
        return RailLiveColors.qaBlue;
      case 'SL':
        return RailLiveColors.qaAmber;
      case 'GEN':
      case 'GS':
        return RailLiveColors.qaPink;
      case 'ENG':
        return RailLiveColors.primary;
      case 'EOG':
        return RailLiveColors.surface2;
      default:
        return RailLiveColors.border;
    }
  }

  static Color borderColor(String type) {
    switch (type.toUpperCase()) {
      case '1A':
        return RailLiveColors.languageIcon;
      case '2A':
        return RailLiveColors.success;
      case '3A':
        return RailLiveColors.primary2;
      case 'SL':
        return RailLiveColors.notifIcon;
      case 'GEN':
      case 'GS':
        return RailLiveColors.accent;
      case 'ENG':
        return RailLiveColors.primary;
      case 'EOG':
        return RailLiveColors.border;
      default:
        return RailLiveColors.border;
    }
  }

  static Color textColor(String type) {
    switch (type.toUpperCase()) {
      case '1A':
        return RailLiveColors.languageIcon;
      case '2A':
        return RailLiveColors.success;
      case '3A':
        return RailLiveColors.primary2;
      case 'SL':
        return RailLiveColors.warning;
      case 'GEN':
      case 'GS':
        return RailLiveColors.accent;
      case 'ENG':
        return RailLiveColors.surface;
      case 'EOG':
        return RailLiveColors.textSecondary;
      default:
        return RailLiveColors.textHint;
    }
  }

  static String typeLabel(String type) {
    switch (type.toUpperCase()) {
      case '1A':
        return 'First AC';
      case '2A':
        return 'Second AC';
      case '3A':
        return 'Third AC';
      case 'SL':
        return 'Sleeper';
      case 'GEN':
      case 'GS':
        return 'General';
      case 'ENG':
        return 'Locomotive';
      case 'EOG':
        return 'Power Car';
      default:
        return type;
    }
  }
}
