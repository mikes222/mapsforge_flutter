/// Enumeration defining positioning options for map elements like text labels and symbols.
/// 
/// Used to control where elements are placed relative to their anchor point,
/// such as positioning text labels around POI markers or symbols along ways.
enum MapPositioning { 
  /// Automatic positioning based on available space and collision detection.
  AUTO, 
  
  /// Center the element on its anchor point.
  CENTER, 
  
  /// Position the element below its anchor point.
  BELOW, 
  
  /// Position the element below and to the left of its anchor point.
  BELOW_LEFT, 
  
  /// Position the element below and to the right of its anchor point.
  BELOW_RIGHT, 
  
  /// Position the element above its anchor point.
  ABOVE, 
  
  /// Position the element above and to the left of its anchor point.
  ABOVE_LEFT, 
  
  /// Position the element above and to the right of its anchor point.
  ABOVE_RIGHT, 
  
  /// Position the element to the left of its anchor point.
  LEFT, 
  
  /// Position the element to the right of its anchor point.
  RIGHT 
}
