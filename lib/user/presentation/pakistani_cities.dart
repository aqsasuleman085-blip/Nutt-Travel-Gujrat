/// Major Pakistani cities shown in the From/To city pickers on the Home
/// screen. This list is always shown in full, regardless of which routes
/// currently have buses - availability is checked separately once the
/// user has picked both cities and a date.
const List<String> kPakistaniCities = [
  'Karachi',
  'Lahore',
  'Islamabad',
  'Rawalpindi',
  'Faisalabad',
  'Multan',
  'Peshawar',
  'Quetta',
  'Sialkot',
  'Gujranwala',
  'Hyderabad',
  'Bahawalpur',
  'Sargodha',
  'Sukkur',
  'Larkana',
  'Sheikhupura',
  'Rahim Yar Khan',
  'Gujrat',
  'Jhelum',
  'Mardan',
  'Kasur',
  'Okara',
  'Mingora',
  'Nawabshah',
  'Chiniot',
  'Kotri',
  'Dera Ghazi Khan',
  'Sahiwal',
  'Wah Cantonment',
  'Mirpur Khas',
];

/// Compares two city names ignoring case and leading/trailing whitespace.
///
/// Bus routes are entered by the admin as free text (add_bus_screen.dart
/// has no city list of its own), while the user side now always selects
/// from the fixed [kPakistaniCities] list. To keep a route like
/// "Gujrat" -> "Lahore" matching regardless of how the admin actually
/// typed it (e.g. "gujrat ", "GUJRAT", "Gujrat"), every from/to comparison
/// between a bus record and a user-selected city MUST go through this
/// helper instead of using `==` directly.
bool citiesMatch(String a, String b) {
  return a.trim().toLowerCase() == b.trim().toLowerCase();
}
