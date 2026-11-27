class PetModel {
  static String asset(int streak, bool active, Map<String, bool> equipped) {
    const dir = 'assets/images/pet/pet_';
    if (streak == 0) return '${dir}gray.png';
    final level = streak >= 10 ? 2 : 1;
    final slots = [
      for (final s in ['hat', 'glasses', 'shirt'])
        if (equipped[s] == true) s,
    ];
    final style = !active
        ? 'frozen'
        : level == 1 || slots.isEmpty
        ? 'base'
        : slots.length == 3
        ? 'all'
        : slots.join('_');
    return '${dir}lv${level}_$style.png';
  }
}
