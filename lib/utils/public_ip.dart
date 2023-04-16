import 'dart:convert' as convert;

import 'package:http/http.dart' as http;

Future<String> getPublicIP() async {
    var url = Uri.https('api.ipify.org', '', {'q': '{https}'});
    var response = await http.get(url);
    if (response.statusCode == 200) {
      return response.body;
    } else {
      return '0.0.0.0';
    }

}