class M3uChannel {
  final String name;
  final String streamUrl;
  final String tvgId;
  final String tvgName;
  final String groupTitle;
  final String logoUrl;
  final Map<String, String> attributes;

  const M3uChannel({
    required this.name,
    required this.streamUrl,
    this.tvgId = '',
    this.tvgName = '',
    this.groupTitle = '',
    this.logoUrl = '',
    this.attributes = const {},
  });
}
