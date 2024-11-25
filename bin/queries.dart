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

  Future<Result> getCategory({required int limit, required int offset}) async {
    return await connection.execute(
      Sql.named(
        '''
     SELECT * FROM category ORDER BY id LIMIT @limit OFFSET @offset
     ''',
      ),
      parameters: {
        'limit': limit,
        'offset': offset,
      },
    );
  }

  Future<Result> getProducts({required int type}) async {
    return await connection.execute(
      Sql.named(
        '''
     SELECT * FROM product WHERE category_id = @type
     ''',
      ),
      parameters: {
        'type': type,
      },
    );
  }
}

//   Future<Map<String, dynamic>?> getUserByEmail(String email) async {
//     print('getUserByEmail: $email');
//     final result = await connection.execute(
//       Sql.named('''
//     SELECT id, email, username, profile_photo
//      FROM users
//      WHERE email = @email
//      '''),
//       parameters: {'email': email},
//     );
//     if (result.isNotEmpty) {
//       // Отправляем код на почтовый адрес
//       return result.first.toColumnMap();
//     } else {
//       return null;
//     }
//   }

//   addUser(String email, String username) async {
//     print('addUser: $email, $username');
//     final result = await connection.execute(
//       Sql.named('''
//     INSERT INTO users (email, username)
//     VALUES (@email, @username)
//     '''),
//       parameters: {'email': email, 'username': username},
//     );
//     print('result: $result');
//     print('result: ${result.toList()}');
//   }
// }
