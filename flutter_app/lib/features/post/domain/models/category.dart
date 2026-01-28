/// Item categories for posts
class ItemCategory {
  final String id;
  final String name;
  final String icon;
  final String color;

  const ItemCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<ItemCategory> all = [
    ItemCategory(id: 'electronics', name: 'Electronics', icon: '📱', color: '#3B82F6'),
    ItemCategory(id: 'documents', name: 'Documents', icon: '📄', color: '#8B5CF6'),
    ItemCategory(id: 'pets', name: 'Pets', icon: '🐕', color: '#F59E0B'),
    ItemCategory(id: 'clothing', name: 'Clothing', icon: '👕', color: '#EC4899'),
    ItemCategory(id: 'jewelry', name: 'Jewelry', icon: '💍', color: '#F97316'),
    ItemCategory(id: 'bags', name: 'Bags & Luggage', icon: '👜', color: '#14B8A6'),
    ItemCategory(id: 'keys', name: 'Keys', icon: '🔑', color: '#6366F1'),
    ItemCategory(id: 'wallet', name: 'Wallet & Cards', icon: '👛', color: '#10B981'),
    ItemCategory(id: 'glasses', name: 'Glasses', icon: '👓', color: '#64748B'),
    ItemCategory(id: 'toys', name: 'Toys', icon: '🧸', color: '#F472B6'),
    ItemCategory(id: 'sports', name: 'Sports Equipment', icon: '⚽', color: '#22C55E'),
    ItemCategory(id: 'musical', name: 'Musical Instruments', icon: '🎸', color: '#EAB308'),
    ItemCategory(id: 'medical', name: 'Medical Items', icon: '💊', color: '#EF4444'),
    ItemCategory(id: 'other', name: 'Other', icon: '📦', color: '#64748B'),
  ];

  static ItemCategory? findById(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<String> get ids => all.map((c) => c.id).toList();
}
