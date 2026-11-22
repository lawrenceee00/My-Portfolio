/// Formats a points value as a decimal number, e.g. 1.5 -> "1.50".
/// Change the number of decimals here and it updates everywhere.
String formatPoints(num value) => value.toStringAsFixed(2);