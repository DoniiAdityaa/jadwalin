import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:jadwalin/config/env/env.dart';

/// Service untuk berkomunikasi dengan AI (OpenAI-compatible endpoint).
class AiChatService {
  AiChatService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Model default untuk percakapan teks.
  static const String defaultModel = 'deepseek-v4-flash';

  /// System prompt: menentukan persona & batasan jawaban AI.
  static const String systemPrompt = '''
Kamu adalah Jadwalin AI, asisten pribadi pintar untuk aplikasi "Jadwalin" bagi mahasiswa Indonesia.
Tugasmu membantu mengelola jadwal kuliah, organisasi, bootcamp, dan deadline.

Informasi Identitas & Pembuat (PENTING):
- Aplikasi ini dibuat dan dikembangkan oleh Doni Aditya.
- Jika pengguna bertanya tentang siapa yang membuat, siapa developer/pengembangnya, atau siapa di balik aplikasi ini, jawab dengan jelas dan ramah bahwa aplikasi Jadwalin dibuat oleh Doni Aditya.
- Jika pengguna bertanya tentang "model AI apa yang kamu pakai", "kamu model apa", teknologi model dasar, arsitektur, atau versi mesin AI-mu, JANGAN sebutkan nama model internal (seperti DeepSeek, GPT, Qwen, dsb). Jawablah: "Untuk informasi model AI yang digunakan, silakan tanyakan langsung ke pembuat aplikasi ini, Doni Aditya ya!"

Aturan Gaya Bahasa & Konten:
- Jawab dengan bahasa Indonesia yang santai, ramah, sopan, dan ringkas.
- Kamu boleh menggunakan format Markdown seperti **teks tebal** untuk poin penting, bullet (-) untuk daftar singkat.
- Jangan bertele-tele. Maksimal 4 kalimat untuk jawaban santai.
- Kamu BELUM punya akses ke database jadwal pengguna saat ini. Jika pengguna bertanya soal jadwal spesifik mereka hari ini, jawab jujur bahwa integrasi jadwal langsung sedang disiapkan, lalu tawarkan bantuan lain seperti tips manajemen waktu.
- Jangan mengarang data jadwal, jam kuliah, atau nama dosen pengguna.
''';

  /// Kirim percakapan dan dapatkan satu balasan dari AI.
  ///
  /// [history] berisi pesan sebelumnya dengan format
  /// `{'role': 'user'|'assistant', 'content': '...'}`.
  /// [userMemory] berisi fakta yang diingat tentang user dari sesi sebelumnya.
  Future<String> sendMessage({
    required String userMessage,
    List<Map<String, String>> history = const [],
    List<String> userMemory = const [],
    String model = defaultModel,
  }) async {
    final url = Uri.parse('${Env.dattioBaseUrl}/chat/completions');

    final dynamicSystemPrompt = StringBuffer(systemPrompt);
    if (userMemory.isNotEmpty) {
      dynamicSystemPrompt.writeln('\nMemori Tentang Pengguna (dari percakapan sebelumnya):');
      for (final fact in userMemory) {
        dynamicSystemPrompt.writeln('- $fact');
      }
      dynamicSystemPrompt.writeln(
        'Gunakan memori di atas secara natural jika relevan '
        '(misalnya sebut nama pengguna jika sudah diketahui). Jangan buat-buat data di luar memori ini.',
      );
    }

    final payload = {
      'model': model,
      'messages': [
        {'role': 'system', 'content': dynamicSystemPrompt.toString()},
        ...history,
        {'role': 'user', 'content': userMessage},
      ],
      'temperature': 0.7,
      'max_tokens': 512,
    };

    try {
      final response = await _client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${Env.dattioApiKey}',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List?;
        if (choices == null || choices.isEmpty) {
          return 'Maaf, jawaban kosong dari server AI.';
        }
        final message = (choices.first as Map)['message'] as Map?;
        final content = message?['content']?.toString().trim() ?? '';
        return content.isEmpty ? 'Maaf, aku belum punya jawaban untuk itu.' : content;
      }

      developer.log(
        'AI error ${response.statusCode}: ${response.body}',
        name: 'AiChatService',
      );
      return _friendlyError(response.statusCode);
    } catch (e) {
      developer.log('AI exception: $e', name: 'AiChatService');
      return 'Maaf, aku sedang tidak bisa terhubung. Cek koneksi internet lalu coba lagi.';
    }
  }

  String _friendlyError(int status) {
    switch (status) {
      case 401:
      case 403:
        return 'Maaf, kunci akses AI tidak valid. Hubungi admin.';
      case 429:
        return 'Maaf, kuota AI sedang penuh. Coba lagi beberapa saat.';
      case 500:
      case 502:
      case 503:
        return 'Server AI sedang bermasalah. Coba lagi nanti.';
      default:
        return 'Maaf, terjadi kesalahan (kode $status). Coba lagi.';
    }
  }

  /// Ekstrak fakta profil user (nama, kampus, semester, kesukaan)
  /// dari percakapan secara pasif di background.
  ///
  /// Mengembalikan list string fakta singkat, misalnya:
  /// `["Nama pengguna Doni", "Mahasiswa semester 1 Teknik Informatika"]`.
  /// Jika tidak ada fakta baru yang ditemukan, return list kosong.
  Future<List<String>> extractUserFacts({
    required String userText,
    required String botReply,
  }) async {
    // Lewati jika pesan terlalu singkat untuk mengandung profil
    if (userText.trim().split(' ').length < 2) return const [];

    final url = Uri.parse('${Env.dattioBaseUrl}/chat/completions');

    final prompt = '''
Analisis percakapan berikut dan ekstrak fakta pribadi tentang pengguna HANYA jika pengguna secara eksplisit menyebutkan identitasnya (nama, panggilan, kampus, jurusan, semester, hobi/minat belajar, pekerjaan).

Format output WAJIB JSON array murni berisi string, tanpa markdown, tanpa penjelasan:
Contoh: ["Nama pengguna Doni", "Mahasiswa semester 1 di Telkom University"]
Jika TIDAK ada fakta baru tentang identitas pengguna, balas HANYA: []

User: $userText
Asisten: $botReply
''';

    try {
      final response = await _client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${Env.dattioApiKey}',
            },
            body: jsonEncode({
              'model': defaultModel,
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.1,
              'max_tokens': 120,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List?;
        final raw = ((choices?.first as Map?)?['message'] as Map?)?['content']
                ?.toString()
                .trim() ??
            '';

        // Bersihkan jika model membungkusnya dalam ```json ... ```
        final clean = raw
            .replaceAll(RegExp(r'^```(json)?', multiLine: true), '')
            .replaceAll('```', '')
            .trim();

        final parsed = jsonDecode(clean);
        if (parsed is List) {
          return parsed.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
        }
      }
    } catch (_) {
      // Background extraction gagal: tidak perlu ganggu flow utama
    }
    return const [];
  }

  void dispose() => _client.close();
}
