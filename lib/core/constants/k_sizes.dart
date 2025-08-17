import 'dart:ui';

class KSize {
  // Spacing
  static const double margin1x = 4;
  static const double margin2x = 8;
  static const double margin3x = 12;
  static const double margin4x = 16;
  static const double margin6x = 24;
  static const double radiusDefault = 12;

  // Typography
  static const double fontSizeS = 12;
  static const double fontSizeM = 14;
  static const double fontSizeL = 18;

  // Components
  static const double cardWidth = 72;
  static const double cardHeight = 100;
  static const double handZoneHeight = 160; // Reduced from 180
  static const double libraryZoneHeight = 160; // Reduced from 180
  static const double otherZoneHeight = 160; // Reduced from 180 - Consistent height for all zones

  // Card aspect ratio (standard playing card ratio)
  static const double cardAspectRatio = 72.0 / 100.0; // width / height

  /// Calculates responsive card dimensions based on available space
  /// 
  /// [availableWidth] - Available width for cards
  /// [availableHeight] - Available height for cards  
  /// [maxCards] - Maximum number of cards to fit horizontally
  /// [spacing] - Spacing between cards
  /// [padding] - Padding around the card area
  static Size calculateCardSize({
    required double availableWidth,
    required double availableHeight,
    int maxCards = 1,
    double spacing = 8.0,
    double padding = 16.0,
  }) {
    // Calculate effective available space
    final effectiveWidth = availableWidth - padding;
    final effectiveHeight = availableHeight - padding;
    
    // Calculate card width based on available width and number of cards
    final cardWidth = (effectiveWidth - (spacing * (maxCards - 1))) / maxCards;
    
    // Calculate card height based on aspect ratio
    final cardHeight = cardWidth / cardAspectRatio;
    
    // If calculated height exceeds available height, scale down proportionally
    if (cardHeight > effectiveHeight) {
      final scale = effectiveHeight / cardHeight;
      return Size(cardWidth * scale, effectiveHeight);
    }
    
    return Size(cardWidth, cardHeight);
  }

  /// Calculates the maximum number of cards that can fit horizontally
  /// 
  /// [availableWidth] - Available width
  /// [cardWidth] - Width of each card
  /// [spacing] - Spacing between cards
  /// [padding] - Padding around the card area
  static int calculateMaxCards({
    required double availableWidth,
    required double cardWidth,
    double spacing = 8.0,
    double padding = 16.0,
  }) {
    final effectiveWidth = availableWidth - padding;
    if (effectiveWidth <= 0) return 1;
    
    final maxCards = ((effectiveWidth + spacing) / (cardWidth + spacing)).floor();
    return maxCards.clamp(1, 10); // Limit to reasonable range
  }

  /// Calculates card dimensions for zone display
  /// 
  /// [zoneHeight] - Height of the zone container
  /// [aspectRatio] - Card aspect ratio (width/height)
  /// [padding] - Padding around cards
  /// [scaleFactor] - Factor to scale cards relative to zone height (0.0-1.0)
  static Size calculateZoneCardSize({
    required double zoneHeight,
    double aspectRatio = 72.0 / 100.0,
    double padding = 16.0,
    double scaleFactor = 0.8,
  }) {
    final effectiveHeight = zoneHeight - padding;
    final cardHeight = effectiveHeight * scaleFactor;
    final cardWidth = cardHeight * aspectRatio;
    
    return Size(cardWidth, cardHeight);
  }
}
