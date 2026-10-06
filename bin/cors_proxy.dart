// ignore_for_file: avoid_print
import 'dart:io';

void main() async {
  const targetHost = 'cocoapp-api.somee.com';
  const targetPort = 80;
  const proxyPort = 8080;

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, proxyPort);
  print('========================================================');
  print('🚀 COCO CORS Proxy đang chạy tại http://localhost:$proxyPort');
  print('   Chuyển tiếp yêu cầu tới: http://$targetHost');
  print('   Đã tự động xử lý CORS Header và OPTIONS 200 OK');
  print('========================================================');

  final client = HttpClient();

  await for (HttpRequest request in server) {
    // 1. Gắn các tiêu đề CORS cho mọi phản hồi
    request.response.headers.set('Access-Control-Allow-Origin', '*');
    request.response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    request.response.headers.set('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');

    // 2. Phản hồi ngay 200 OK cho yêu cầu preflight OPTIONS của trình duyệt
    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      continue;
    }

    try {
      final targetUri = Uri(
        scheme: 'http',
        host: targetHost,
        port: targetPort,
        path: request.uri.path,
        query: request.uri.query.isNotEmpty ? request.uri.query : null,
      );

      final proxyRequest = await client.openUrl(request.method, targetUri);

      // Sao chép headers từ trình duyệt gửi lên
      request.headers.forEach((name, values) {
        if (name.toLowerCase() != 'host') {
          for (var value in values) {
            proxyRequest.headers.add(name, value);
          }
        }
      });
      proxyRequest.headers.set('Host', targetHost);

      // Chuyển tiếp Body (JSON, Text...)
      await proxyRequest.addStream(request);
      final proxyResponse = await proxyRequest.close();

      request.response.statusCode = proxyResponse.statusCode;
      proxyResponse.headers.forEach((name, values) {
        if (!name.toLowerCase().startsWith('access-control-')) {
          for (var value in values) {
            request.response.headers.add(name, value);
          }
        }
      });

      // Trả lại kết quả cho Flutter Web
      await request.response.addStream(proxyResponse);
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.badGateway;
      request.response.write('Lỗi Proxy: $e');
      await request.response.close();
    }
  }
}
