import '../models/user.dart';
import 'db_service.dart';

class UserService {
  final _db = DBService.instance;

  Future<List<AppUser>> allUsers() => _db.getAllUsers();

  Future<AppUser?> byEmail(String email) => _db.getUserByEmail(email);

  Future<AppUser?> byId(int id) => _db.getUserById(id);

  Future<int> create(AppUser user) => _db.insertUser(user);

  Future<int> update(AppUser user) => _db.updateUser(user);
}
