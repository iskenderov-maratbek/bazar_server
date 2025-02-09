// database_queries.dart

import 'package:postgres/postgres.dart';

class DatabaseQueries {
  final Connection connection;

  DatabaseQueries(this.connection);

  Future<Result> getCategories() async {
    return await connection.execute(
      Sql.named(
        '''
     SELECT id, name, photo FROM categories ORDER BY id;
     ''',
      ),
    );
  }

  Future<Result> getBanners() async {
    return await connection.execute(
      Sql.named(
        '''
     SELECT id, photo, text FROM banners ORDER BY id;
     ''',
      ),
    );
  }

  Future<Result> getListOfCategories() async {
    return await connection.execute(
      Sql.named(
        '''
     SELECT id, name FROM categories;
     ''',
      ),
    );
  }

  Future<Result> getProducts(
      {required int categoryId,
      required int limit,
      required int offset}) async {
    return await connection.execute(
      Sql.named(
        '''
        SELECT 
          p.name, 
          p.photo, 
          p.description, 
          p.price, 
          p.price_type, 
          u.name AS seller,
          p.location, 
          p.delivery, 
          u.phone,
          u.whatsapp
        FROM 
          products p 
        JOIN 
          users u ON p.user_id = u.id 
        WHERE 
          p.category_id = @categoryId 
          AND p.status = @status
        LIMIT 
          @limit 
        OFFSET 
          @offset;
        ''',
      ),
      parameters: {
        'categoryId': categoryId,
        'limit': limit,
        'offset': offset,
        'status': 'active',
      },
    );
  }

  Future<Result> getActiveUserProducts(
      {required String id, limit, offset}) async {
    return await connection.execute(
      Sql.named(
        '''
      SELECT id, name, photo, description, price, price_type, location, delivery, category_id, status
      FROM products 
      WHERE user_id = @id::VARCHAR(255) 
      AND (status = 'active' OR status = 'moderate')
      ORDER BY CASE WHEN status = 'moderate' THEN 1 WHEN status = 'active' THEN 2 ELSE 3 END
      LIMIT @limit::INT
      OFFSET @offset::INT;
      ''',
      ),
      parameters: {
        'id': id,
        'limit': limit,
        'offset': offset,
      },
    );
  }

  Future<Result> getArchiveProducts({required String id, limit, offset}) async {
    return await connection.execute(
      Sql.named(
        '''
      SELECT id, name, photo, description, price, price_type, location, delivery, category_id, status
      FROM products 
      WHERE user_id = @id::VARCHAR(255) 
      AND (status = 'archive' OR status = 'sold')
      ORDER BY created_at DESC
      LIMIT @limit::INT
      OFFSET @offset::INT;
      ''',
      ),
      parameters: {
        'id': id,
        'limit': limit,
        'offset': offset,
      },
    );
  }

  Future<Result> authUser({required String userId}) async {
    final result = await connection.execute(
      Sql.named('''
        SELECT id,name, email, profile_photo, phone, whatsapp, access_token, location FROM users WHERE id = @id
        '''),
      parameters: {
        'id': userId,
      },
    );
    return result;
  }

  Future<int> registerUser({userId, userName, userEmail, accessToken}) async {
    final result = await connection.execute(
      Sql.named('''
 INSERT INTO users (id, name, email, access_token, status) VALUES (@id, @name, @email, @access_token, @status) 
 '''),
      parameters: {
        'id': userId,
        'name': userName,
        'email': userEmail,
        'access_token': accessToken,
        'status': 'active',
      },
    );
    return result.affectedRows;
  }

  Future<Result> getSearchProduct(
      {required String name, required int limit, required int offset}) async {
    return await connection.execute(
      Sql.named(
        '''
        SELECT 
          p.photo, 
          p.description, 
          p.price, 
          p.price_type, 
          p.name, 
          p.location, 
          p.delivery, 
          u.name AS seller,
          u.phone,
          u.whatsapp
        FROM 
          products p 
        JOIN 
          users u ON p.user_id = u.id 
        WHERE 
          p.name ILIKE @name 
          AND p.status = @status
        LIMIT 
          @limit 
        OFFSET 
          @offset;
        ''',
      ),
      parameters: {
        'name': '%$name%',
        'limit': limit,
        'offset': offset,
        'status': 'active',
      },
    );
  }

  Future<bool> updateUserData({
    required String id,
    required String name,
    String? profilePhoto,
    required String phone,
    required String? whatsapp,
    required String? location,
  }) async {
    if (profilePhoto != null) {
      final result = await connection.execute(
        Sql.named('''
UPDATE users 
SET 
  name = @name::VARCHAR(100), 
  phone = @phone::VARCHAR(20), 
  whatsapp = @whatsapp::VARCHAR(20), 
  location = @location::VARCHAR(255),
  profile_photo = @profilePhoto::TEXT
WHERE 
  id = @id::VARCHAR(255);

        '''),
        parameters: {
          'name': name,
          'phone': phone,
          'whatsapp': whatsapp,
          'location': location,
          'id': id,
          'profilePhoto': profilePhoto,
        },
      );
      return result.affectedRows > 0;
    } else {
      final result = await connection.execute(
        Sql.named('''
UPDATE users 
SET 
  name = @name::VARCHAR(100), 
  phone = @phone::VARCHAR(20), 
  whatsapp = @whatsapp::VARCHAR(20), 
  location = @location::VARCHAR(255)
WHERE 
  id = @id::VARCHAR(255);

        '''),
        parameters: {
          'name': name,
          'phone': phone,
          'whatsapp': whatsapp,
          'location': location,
          'id': id,
        },
      );
      return result.affectedRows > 0;
    }
  }

  Future<ResultRow> addUserProduct({
    required String name,
    required int categoryId,
    required String description,
    required int price,
    required String priceType,
    required String location,
    required bool delivery,
    List<String>? photos,
    required String userId,
  }) async {
    final result = await connection.execute(Sql.named('''
    INSERT INTO products (
      name, photo, category_id, description, price, price_type, location, delivery, status, user_id
    ) VALUES (
      @name::VARCHAR(255), @photos::TEXT[], @categoryId::INTEGER, @description::VARCHAR(500), @price::INTEGER, 
      @priceType::VARCHAR(255), @location::VARCHAR(255), @delivery::BOOLEAN, @status::VARCHAR(20), @userId::VARCHAR(255)
    )RETURNING id;
  '''), parameters: {
      'name': name,
      'photos': photos ?? <String>[],
      'categoryId': categoryId,
      'description': description,
      'price': price,
      'priceType': priceType,
      'location': location,
      'delivery': delivery,
      'status': 'moderate',
      'userId': userId,
    });
    return result.first;
  }

  Future<bool> editUserProduct({
    required int id,
    required String name,
    required int categoryId,
    required String description,
    required int price,
    required String priceType,
    required String location,
    required bool delivery,
  }) async {
    final result = await connection.execute(Sql.named('''
UPDATE products
SET 
  name = @name::VARCHAR(100),
  category_id = @categoryId::INTEGER,
  description = @description::TEXT,
  price = @price::INTEGER,
  price_type = @priceType::VARCHAR(50),
  location = @location::VARCHAR(255),
  delivery = @delivery::BOOLEAN,
  status = CASE WHEN status = 'active' THEN 'moderate' ELSE status END
WHERE 
  id = @id::INTEGER;
          '''), parameters: {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'description': description,
      'price': price,
      'priceType': priceType,
      'location': location,
      'delivery': delivery,
    });
    return result.affectedRows > 0;
  }

  Future<dynamic> getPhotoUrl({
    required int productId,
  }) async {
    final result = await connection.execute(Sql.named('''
          SELECT photo
          FROM products
          WHERE id = @id::INTEGER;
          '''), parameters: {
      'id': productId,
    });
    return result.first[0];
  }

  Future<bool> removeUserProduct({
    required int productId,
  }) async {
    final result = await connection.execute(Sql.named('''
            DELETE FROM products 
            WHERE   id = @productId::INTEGER;
          '''), parameters: {
      'productId': productId,
    });
    return result.affectedRows > 0;
  }

  Future<bool> archivedUserProduct({
    required int productId,
  }) async {
    final result = await connection.execute(Sql.named('''
          UPDATE products
          SET status = 'archive'::VARCHAR(50)
          WHERE id = @productId::INTEGER;
          '''), parameters: {
      'productId': productId,
    });
    return result.affectedRows > 0;
  }

  Future<int> getLimit({
    required String id,
  }) async {
    final result = await connection.execute(Sql.named('''
         SELECT COUNT(*) AS product_count FROM products WHERE user_id = @userid;
          '''), parameters: {
      'userid': id,
    });
    return result.first[0] as int;
  }

  Future<bool> moderateUserProduct({
    required int productId,
  }) async {
    final result = await connection.execute(Sql.named('''
          UPDATE products
          SET status = 'moderate'::VARCHAR(50)
          WHERE id = @productId::INTEGER;
          '''), parameters: {
      'productId': productId,
    });
    return result.affectedRows > 0;
  }

  Future<bool> verifyUserAccess({userId, token, int? productId}) async {
    final result = await connection.execute(
      Sql.named(
          '''SELECT COUNT(*) FROM users WHERE id = @userId AND access_token = @accessToken'''),
      parameters: {
        'userId': userId,
        'accessToken': token,
      },
    );
    if (result.first[0] as int > 0) {
      if (productId != null) {
        final checkProduct = await connection.execute(
          Sql.named(
              '''SELECT * FROM products WHERE id = @productId AND user_id = @userId'''),
          parameters: {
            'productId': productId,
            'userId': userId,
          },
        );
        if (checkProduct.isNotEmpty) {
          return true;
        } else {
          return false;
        }
      } else {
        return true;
      }
    } else {
      return false;
    }
  }

  Future<bool> bugReport({
    required String userId,
    required String description,
  }) async {
    final result = await connection.execute(Sql.named('''
        INSERT INTO bugs (user_id, description) VALUES (@userId, @description)
        '''), parameters: {
      'userId': userId,
      'description': description,
    });
    return result.affectedRows > 0;
  }
}
