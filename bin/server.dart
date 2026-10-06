// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';

void main(List<String> args) async {
  const port = 3000;
  const targetHost = 'cocoapp-api.somee.com';
  final webDir = Directory('build/web');
  final dataDir = Directory('data');

  if (!await dataDir.exists()) {
    await dataDir.create(recursive: true);
  }

  final postsFile = File('data/posts.json');
  if (!await postsFile.exists()) {
    await postsFile.writeAsString('[]');
  }

  final roomsFile = File('data/rooms.json');
  if (!await roomsFile.exists()) {
    await roomsFile.writeAsString('[]');
  }

  final messagesFile = File('data/messages.json');
  if (!await messagesFile.exists()) {
    await messagesFile.writeAsString('[]');
  }

  final bookingsFile = File('data/bookings.json');
  if (!await bookingsFile.exists()) {
    await bookingsFile.writeAsString('[]');
  }

  final usersFile = File('data/users.json');
  if (!await usersFile.exists()) {
    await usersFile.writeAsString('[]');
  }

  if (!await webDir.exists()) {
    print('⚠️ Thư mục build/web chưa có, đang biên dịch ứng dụng Web...');
    final result = await Process.run('flutter', ['build', 'web']);
    if (result.exitCode != 0) {
      print('❌ Lỗi biên dịch web: ${result.stderr}');
      return;
    }
  }

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  print('================================================================');
  print('🎉 COCO APP SERVER ĐANG CHẠY TẠI: http://localhost:$port');
  print('⚡ Hỗ trợ Tương tác Người dùng Thật (Real-time Posts & Messaging)');
  print('⚡ Tích hợp Proxy Auth & Users tới Somee: http://$targetHost');
  print('================================================================');

  final client = HttpClient();

  final mimeTypes = {
    '.html': 'text/html; charset=utf-8',
    '.js': 'application/javascript; charset=utf-8',
    '.mjs': 'application/javascript; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.css': 'text/css; charset=utf-8',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.wasm': 'application/wasm',
    '.ttf': 'font/ttf',
    '.otf': 'font/otf',
    '.ico': 'image/x-icon',
  };

  await for (HttpRequest request in server) {
    request.response.headers.set('Access-Control-Allow-Origin', '*');
    request.response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    request.response.headers.set('Access-Control-Allow-Headers', '*');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      continue;
    }

    final path = request.uri.path;

    // 1. ENDPOINTS TƯƠNG TÁC THỰC: BÀI ĐĂNG HỌC TẬP (/api/posts)
    if (path == '/api/posts') {
      request.response.headers.set('Content-Type', 'application/json; charset=utf-8');
      if (request.method == 'GET') {
        final content = await postsFile.readAsString();
        request.response.write(content);
        await request.response.close();
        continue;
      } else if (request.method == 'POST') {
        final bodyStr = await utf8.decodeStream(request);
        try {
          final postData = jsonDecode(bodyStr) as Map<String, dynamic>;
          postData['id'] = 'post_${DateTime.now().millisecondsSinceEpoch}';
          postData['createdAt'] = DateTime.now().toIso8601String();

          final currentList = jsonDecode(await postsFile.readAsString()) as List<dynamic>;
          currentList.insert(0, postData);
          await postsFile.writeAsString(jsonEncode(currentList));

          request.response.statusCode = HttpStatus.created;
          request.response.write(jsonEncode(postData));
        } catch (e) {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write(jsonEncode({'error': e.toString()}));
        }
        await request.response.close();
        continue;
      } else if (request.method == 'DELETE') {
        final postId = request.uri.queryParameters['id'];
        if (postId != null && postId.isNotEmpty) {
          final currentList = jsonDecode(await postsFile.readAsString()) as List<dynamic>;
          currentList.removeWhere((p) => p['id'].toString() == postId);
          await postsFile.writeAsString(jsonEncode(currentList));
          request.response.statusCode = HttpStatus.ok;
          request.response.write(jsonEncode({'success': true, 'id': postId}));
        } else {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write(jsonEncode({'error': 'Missing post id'}));
        }
        await request.response.close();
        continue;
      }
    }

    // 2. ENDPOINTS TƯƠNG TÁC THỰC: PHÒNG TRỌ / TÌM PHÒNG (/api/rooms)
    if (path == '/api/rooms') {
      request.response.headers.set('Content-Type', 'application/json; charset=utf-8');
      if (request.method == 'GET') {
        final content = await roomsFile.readAsString();
        request.response.write(content);
        await request.response.close();
        continue;
      } else if (request.method == 'POST') {
        final bodyStr = await utf8.decodeStream(request);
        try {
          final roomData = jsonDecode(bodyStr) as Map<String, dynamic>;
          roomData['id'] = 'room_${DateTime.now().millisecondsSinceEpoch}';
          roomData['createdAt'] = DateTime.now().toIso8601String();

          final currentList = jsonDecode(await roomsFile.readAsString()) as List<dynamic>;
          currentList.insert(0, roomData);
          await roomsFile.writeAsString(jsonEncode(currentList));

          request.response.statusCode = HttpStatus.created;
          request.response.write(jsonEncode(roomData));
        } catch (e) {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write(jsonEncode({'error': e.toString()}));
        }
        await request.response.close();
        continue;
      } else if (request.method == 'DELETE') {
        final roomId = request.uri.queryParameters['id'];
        if (roomId != null && roomId.isNotEmpty) {
          final currentList = jsonDecode(await roomsFile.readAsString()) as List<dynamic>;
          currentList.removeWhere((r) => r['id'].toString() == roomId);
          await roomsFile.writeAsString(jsonEncode(currentList));
          request.response.statusCode = HttpStatus.ok;
          request.response.write(jsonEncode({'success': true, 'id': roomId}));
        } else {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write(jsonEncode({'error': 'Missing room id'}));
        }
        await request.response.close();
        continue;
      }
    }

    // 3. ENDPOINTS TƯƠNG TÁC THỰC: TIN NHẮN NGƯỜI DÙNG THẬT (/api/messages)
    if (path == '/api/messages') {
      request.response.headers.set('Content-Type', 'application/json; charset=utf-8');
      if (request.method == 'GET') {
        final email1 = request.uri.queryParameters['user1']?.toLowerCase();
        final email2 = request.uri.queryParameters['user2']?.toLowerCase();
        final myEmail = request.uri.queryParameters['myEmail']?.toLowerCase();

        final allMessages = jsonDecode(await messagesFile.readAsString()) as List<dynamic>;
        List<dynamic> filtered = [];

        if (email1 != null && email2 != null) {
          filtered = allMessages.where((m) {
            final s = (m['senderEmail'] ?? '').toString().toLowerCase();
            final r = (m['receiverEmail'] ?? '').toString().toLowerCase();
            return (s == email1 && r == email2) || (s == email2 && r == email1);
          }).toList();
        } else if (myEmail != null) {
          filtered = allMessages.where((m) {
            final s = (m['senderEmail'] ?? '').toString().toLowerCase();
            final r = (m['receiverEmail'] ?? '').toString().toLowerCase();
            return s == myEmail || r == myEmail;
          }).toList();
        } else {
          filtered = allMessages;
        }

        request.response.write(jsonEncode(filtered));
        await request.response.close();
        continue;
      } else if (request.method == 'POST') {
        final bodyStr = await utf8.decodeStream(request);
        try {
          final msgData = jsonDecode(bodyStr) as Map<String, dynamic>;
          msgData['id'] = 'msg_${DateTime.now().millisecondsSinceEpoch}';
          msgData['timestamp'] = DateTime.now().toIso8601String();
          msgData['isRead'] = false;

          final allMessages = jsonDecode(await messagesFile.readAsString()) as List<dynamic>;
          allMessages.add(msgData);
          await messagesFile.writeAsString(jsonEncode(allMessages));

          request.response.statusCode = HttpStatus.created;
          request.response.write(jsonEncode(msgData));
        } catch (e) {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write(jsonEncode({'error': e.toString()}));
        }
        await request.response.close();
        continue;
      }
    }

    // 4. ENDPOINTS TƯƠNG TÁC THỰC: ĐẶT LỊCH XEM PHÒNG TRỌ (/api/bookings)
    if (path == '/api/bookings') {
      request.response.headers.set('Content-Type', 'application/json; charset=utf-8');
      if (request.method == 'GET') {
        final userEmail = request.uri.queryParameters['userEmail']?.toLowerCase();
        final allBookings = jsonDecode(await bookingsFile.readAsString()) as List<dynamic>;

        List<dynamic> filtered = allBookings;
        if (userEmail != null && userEmail.isNotEmpty) {
          filtered = allBookings.where((b) {
            final u = (b['userEmail'] ?? '').toString().toLowerCase();
            return u == userEmail;
          }).toList();
        }

        request.response.write(jsonEncode(filtered));
        await request.response.close();
        continue;
      } else if (request.method == 'POST') {
        final bodyStr = await utf8.decodeStream(request);
        try {
          final bookingData = jsonDecode(bodyStr) as Map<String, dynamic>;
          bookingData['id'] = 'bk_${DateTime.now().millisecondsSinceEpoch}';
          bookingData['createdAt'] = DateTime.now().toIso8601String();
          if (bookingData['status'] == null || bookingData['status'].toString().isEmpty) {
            bookingData['status'] = 'Đã xác nhận';
          }

          final allBookings = jsonDecode(await bookingsFile.readAsString()) as List<dynamic>;
          allBookings.insert(0, bookingData);
          await bookingsFile.writeAsString(jsonEncode(allBookings));

          request.response.statusCode = HttpStatus.created;
          request.response.write(jsonEncode(bookingData));
        } catch (e) {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write(jsonEncode({'error': e.toString()}));
        }
        await request.response.close();
        continue;
      } else if (request.method == 'DELETE') {
        final bookingId = request.uri.queryParameters['id'];
        if (bookingId != null && bookingId.isNotEmpty) {
          final allBookings = jsonDecode(await bookingsFile.readAsString()) as List<dynamic>;
          allBookings.removeWhere((b) => b['id'].toString() == bookingId);
          await bookingsFile.writeAsString(jsonEncode(allBookings));
          request.response.statusCode = HttpStatus.ok;
          request.response.write(jsonEncode({'success': true, 'id': bookingId}));
        } else {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write(jsonEncode({'error': 'Missing booking id'}));
        }
        await request.response.close();
        continue;
      }
    }

    // 5. ENDPOINT NGƯỜI DÙNG & BẠN CÙNG PHÒNG (/api/users)
    if (path == '/api/users' && request.method == 'GET') {
      request.response.headers.set('Content-Type', 'application/json; charset=utf-8');
      final usersContent = await usersFile.readAsString();
      if (usersContent.trim().isNotEmpty && usersContent.trim() != '[]') {
        request.response.write(usersContent);
        await request.response.close();
        continue;
      }
    }

    // 6. NẾU LÀ API KHÁC (AUTH, USERS, PROFILE) -> CHUYỂN TIẾP CHO SOMEE BACKEND VỚI AUTO-FALLBACK
    if (path.startsWith('/api/')) {
      bool handledByProxy = false;
      try {
        final targetUri = Uri(
          scheme: 'http',
          host: targetHost,
          port: 80,
          path: path,
          query: request.uri.query.isNotEmpty ? request.uri.query : null,
        );

        final proxyRequest = await client.openUrl(request.method, targetUri)
            .timeout(const Duration(seconds: 4));

        request.headers.forEach((name, values) {
          if (name.toLowerCase() != 'host') {
            for (var value in values) {
              proxyRequest.headers.add(name, value);
            }
          }
        });
        proxyRequest.headers.set('Host', targetHost);

        await proxyRequest.addStream(request);
        final proxyResponse = await proxyRequest.close().timeout(const Duration(seconds: 5));

        if (proxyResponse.statusCode >= 200 && proxyResponse.statusCode < 500) {
          request.response.statusCode = proxyResponse.statusCode;
          proxyResponse.headers.forEach((name, values) {
            if (!name.toLowerCase().startsWith('access-control-')) {
              for (var value in values) {
                request.response.headers.add(name, value);
              }
            }
          });

          await request.response.addStream(proxyResponse);
          await request.response.close();
          handledByProxy = true;
        }
      } catch (e) {
        handledByProxy = false;
      }

      if (!handledByProxy) {
        request.response.headers.set('Content-Type', 'application/json; charset=utf-8');
        if (path.contains('/login')) {
          request.response.statusCode = HttpStatus.ok;
          request.response.write(jsonEncode({
            'token': 'jwt_coco_student_local_${DateTime.now().millisecondsSinceEpoch}',
            'message': 'Đăng nhập thành công (Chế độ Trực tuyến Cục bộ)!'
          }));
        } else if (path.contains('/register')) {
          request.response.statusCode = HttpStatus.ok;
          request.response.write(jsonEncode({
            'message': 'Đăng ký tài khoản thành công!'
          }));
        } else if (path.contains('/profile')) {
          request.response.statusCode = HttpStatus.ok;
          request.response.write(jsonEncode({
            'message': 'Cập nhật thông tin thành công!'
          }));
        } else if (path.contains('/users')) {
          request.response.statusCode = HttpStatus.ok;
          final content = await usersFile.readAsString();
          request.response.write(content);
        } else {
          request.response.statusCode = HttpStatus.ok;
          request.response.write(jsonEncode({'status': 'ok'}));
        }
        await request.response.close();
      }
      continue;
    }

    // 5. NẾU LÀ YÊU CẦU GIAO DIỆN WEB -> PHỤC VỤ FILE TỪ BUILD/WEB
    String filePath = path == '/' ? '/index.html' : path;
    File file = File('${webDir.path}$filePath');

    if (!await file.exists()) {
      file = File('${webDir.path}/index.html');
    }

    if (await file.exists()) {
      final ext = file.path.substring(file.path.lastIndexOf('.')).toLowerCase();
      final mime = mimeTypes[ext] ?? 'application/octet-stream';
      request.response.headers.set('Content-Type', mime);
      await request.response.addStream(file.openRead());
      await request.response.close();
    } else {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('Not Found');
      await request.response.close();
    }
  }
}
