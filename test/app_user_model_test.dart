import 'package:flutter_test/flutter_test.dart';
import 'package:umkmap/models/app_user.dart';

void main() {
  group('AppUser Model - Points & Tier System Tests', () {
    test('default points is 0 and tier is Bronze', () {
      const user = AppUser(
        id: 'user-1',
        email: 'test@example.com',
        fullName: 'Test User',
        role: 'pemilik',
      );

      expect(user.poin, 0);
      expect(user.tier, 'Bronze');
      expect(user.isAdmin, isFalse);
    });

    test('determines tier correctly based on points range', () {
      expect(const AppUser(id: '1', email: '', fullName: '', role: '', poin: 0).tier, 'Bronze');
      expect(const AppUser(id: '1', email: '', fullName: '', role: '', poin: 100).tier, 'Bronze');
      expect(const AppUser(id: '1', email: '', fullName: '', role: '', poin: 101).tier, 'Silver');
      expect(const AppUser(id: '1', email: '', fullName: '', role: '', poin: 200).tier, 'Silver');
      expect(const AppUser(id: '1', email: '', fullName: '', role: '', poin: 201).tier, 'Gold');
      expect(const AppUser(id: '1', email: '', fullName: '', role: '', poin: 300).tier, 'Gold');
      expect(const AppUser(id: '1', email: '', fullName: '', role: '', poin: 301).tier, 'Platinum');
      expect(const AppUser(id: '1', email: '', fullName: '', role: '', poin: 400).tier, 'Platinum');
      expect(const AppUser(id: '1', email: '', fullName: '', role: '', poin: 450).tier, 'Super User');
    });

    test('fromJson parses poin correctly', () {
      final json = {
        'id': 'user-2',
        'email': 'user2@example.com',
        'full_name': 'Second User',
        'role': 'admin',
        'poin': 250,
      };

      final user = AppUser.fromJson(json);

      expect(user.id, 'user-2');
      expect(user.email, 'user2@example.com');
      expect(user.fullName, 'Second User');
      expect(user.role, 'admin');
      expect(user.poin, 250);
      expect(user.tier, 'Gold');
      expect(user.isAdmin, isTrue);
    });
  });
}
