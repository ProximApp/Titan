import 'package:http/http.dart' as http;
import 'package:titan/tools/logs/logger.dart';
import 'dart:async';
import 'dart:convert';
import 'package:titan/centralassociation/class/asso.dart';

class AssoRepository {
  AssoRepository({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  static const String host = "https://assos.myecl.fr/assos_links.json";
  final Duration timeout;
  final Map<String, String> headers = {
    "Content-Type": "application/json; charset=UTF-8",
    "Accept": "application/json",
  };

  final http.Client _client;
  static final Logger logger = Logger();
  void initLogger() {
    logger.init();
  }

  Future<List<Asso>> getAssoList() async {
    try {
      // Without a timeout an unreachable host hangs forever and the UI stays
      // on its loading spinner.
      final response = await _client
          .get(Uri.parse(host), headers: headers)
          .timeout(timeout);
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final test = data.map<Asso>((asso) => Asso.fromJson(asso)).toList();
          return test;
        } catch (e) {
          logger.error("GET $host\nError while decoding response");
          return <Asso>[];
        }
      } else {
        logger.error("GET $host\n${response.statusCode} ${response.body}");
        return <Asso>[];
      }
    } on TimeoutException catch (_) {
      logger.error("GET $host\nTimeout while fetching response");
      return <Asso>[];
    } catch (e) {
      logger.error("GET $host\nError while fetching response");
      return <Asso>[];
    }
  }
}
