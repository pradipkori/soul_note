String getTimeOfDay(DateTime time) {
  final hour = time.hour;

  if (hour >= 5 && hour < 12) {
    return "Morning ☀️";
  } else if (hour >= 12 && hour < 17) {
    return "Afternoon 🌤️";
  } else if (hour >= 17 && hour < 21) {
    return "Evening 🌆";
  } else {
    return "Late Night 🌙";
  }
}
