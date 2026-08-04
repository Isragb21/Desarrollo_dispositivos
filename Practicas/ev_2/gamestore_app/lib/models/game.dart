class Game {
  final String id;
  final String title;
  final String genre;
  final String description;
  final double price;
  final double rating;
  final String imageUrl;
  final List<String> tags;
  final bool isOnSale;
  final double? salePrice;

  const Game({
    required this.id,
    required this.title,
    required this.genre,
    required this.description,
    required this.price,
    required this.rating,
    required this.imageUrl,
    this.tags = const [],
    this.isOnSale = false,
    this.salePrice,
  });
}
