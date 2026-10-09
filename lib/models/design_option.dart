/// An option of the "صمّم عمرتك" wizard (hotel preference, transport,
/// extra service or room type), managed in the admin and shared with the
/// website. [value] is what's sent on the request; [label] is localized.
class DesignOption {
  final String value;
  final String label;
  final String? description;
  final String? icon;

  const DesignOption({
    required this.value,
    required this.label,
    this.description,
    this.icon,
  });
}
