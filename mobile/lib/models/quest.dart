class Quest {
  final int id;
  final String title;
  final String type; // pushup, squat, jumping_jack
  final int target;
  final int rewardXp;
  final int rewardGems;
  final String icon;
  final String desc;

  Quest({
    required this.id,
    required this.title,
    required this.type,
    required this.target,
    required this.rewardXp,
    this.rewardGems = 0,
    required this.icon,
    required this.desc,
  });
}
