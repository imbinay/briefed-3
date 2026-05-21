enum NewsCategory {
  world,
  politics,
  sports,
  technology,
  business,
  health,
  entertainment;

  String get label {
    switch (this) {
      case NewsCategory.world:
        return 'World';
      case NewsCategory.politics:
        return 'Politics';
      case NewsCategory.sports:
        return 'Sports';
      case NewsCategory.technology:
        return 'Technology';
      case NewsCategory.business:
        return 'Business';
      case NewsCategory.health:
        return 'Health & Lifestyle';
      case NewsCategory.entertainment:
        return 'Entertainment';
    }
  }

  static NewsCategory? fromString(String s) {
    final lower = s.toLowerCase().trim();
    for (final cat in NewsCategory.values) {
      if (cat.name == lower) return cat;
    }
    return null;
  }
}

enum ApiSource { currents, guardian, newsdata }
