// database_queries.dart

import 'package:postgres/postgres.dart';

class DatabaseQueries {
  final Connection connection;

  DatabaseQueries(this.connection);

  Future<List<Map<String, dynamic>>?> getAllCategory() async {
    print('getAllCategory running...');
    try {
      final result = await connection.execute(
        Sql.named('''
     SELECT * FROM category;
     '''),
      );
      print(result);
      print("TRANSFORM");
      print(result.toList().map((row) => row.toColumnMap()).toList());
      return result.toList().map((row) => row.toColumnMap()).toList();
    } catch (e) {
      return null;
    }
  }

  Future<Result> getCategories(
      {required int limit, required int offset}) async {
    return await connection.execute(
      Sql.named(
        '''
     SELECT * FROM categories ORDER BY id LIMIT @limit OFFSET @offset
     ''',
      ),
      parameters: {
        'limit': limit,
        'offset': offset,
      },
    );
  }

  Future<Result> getProducts(
      {required int type, required int limit, required int offset}) async {
    return await connection.execute(
      Sql.named(
        ''' SELECT id, name, photo, price FROM products WHERE category_id = @type LIMIT @limit OFFSET @offset ''',
      ),
      parameters: {
        'type': type,
        'limit': limit,
        'offset': offset,
      },
    );
  }

  Future<Result> getProductInfo({required int id}) async {
    return await connection.execute(
      Sql.named(
        '''
      SELECT 
        p.user_id, 
        p.location, 
        p.delivery, 
        p.description,
        u.name,
        u.number
      FROM products p
      JOIN users u ON p.user_id = u.id
      WHERE p.id = @id
      ''',
      ),
      parameters: {
        'id': id,
      },
    );
  }

  Future<Result> authUser({required String userId}) async {
    print('checkUser running... $userId');
    final result = await connection.execute(
      Sql.named('''
        SELECT * FROM users WHERE id = @id
        '''),
      parameters: {
        'id': userId,
      },
    );
    return result;
  }

  Future<int> registerUser(
      {userId, userName, userEmail, userPhoto, accessToken}) async {
    final result = await connection.execute(
      Sql.named('''
 INSERT INTO users (id, name, email, photo, access_token, status) VALUES (@id, @name, @email, @photo, @access_token, @status) 
 '''),
      parameters: {
        'id': userId,
        'name': userName,
        'email': userEmail,
        'photo': userPhoto,
        'access_token': accessToken,
        'status': 'active',
      },
    );
    return result.affectedRows;
  }

  Future<void> authWithGoogle({userId, userName, userEmail, userPhoto}) async {}
}
