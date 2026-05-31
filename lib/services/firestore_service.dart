import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:daily_fitness/models/app_user.dart';
import 'package:daily_fitness/models/product.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference users() => _firestore.collection('users');
  static CollectionReference products() => _firestore.collection('products');
  static CollectionReference carts() => _firestore.collection('carts');
  static CollectionReference orders() => _firestore.collection('orders');
  static CollectionReference notifications() => _firestore.collection('notifications');
  static CollectionReference addresses() => _firestore.collection('addresses');
  static CollectionReference sellerProfiles() => _firestore.collection('sellerProfiles');
  static CollectionReference riderProfiles() => _firestore.collection('riderProfiles');
  static CollectionReference categories() => _firestore.collection('categories');
  static CollectionReference testimonials() => _firestore.collection('testimonials');
  static CollectionReference analytics() => _firestore.collection('analytics');
  static CollectionReference settings() => _firestore.collection('settings');
  static CollectionReference wishlist() => _firestore.collection('wishlist');
  static CollectionReference reviews() => _firestore.collection('reviews');

  static Future<void> createUserProfile(AppUser user) {
    return users().doc(user.uid).set(user.toMap());
  }

  static Future<DocumentSnapshot> getUserProfile(String uid) {
    return users().doc(uid).get();
  }

  static Stream<List<Product>> liveProducts() {
    return products().where('status', isEqualTo: 'active').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  static Future<void> addProduct(Product product) {
    return products().doc(product.productId).set(product.toMap());
  }

  static Future<void> createCart(String userId, List<Map<String, dynamic>> items, double total) {
    return carts().doc(userId).set({
      'cartId': userId,
      'userId': userId,
      'items': items,
      'totalAmount': total,
      'updatedAt': Timestamp.now(),
    });
  }

  static Future<void> createOrder(Map<String, dynamic> orderData) {
    return orders().doc(orderData['orderId'] as String).set(orderData);
  }

  static Future<void> sendNotification(Map<String, dynamic> notification) {
    return notifications().doc(notification['notificationId'] as String).set(notification);
  }
}
