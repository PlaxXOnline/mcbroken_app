import 'package:http/http.dart' as http;

class McDonaldsDataProvider {
  var url = Uri.parse('http://192.168.64.2/mcbroken.json');
  Future fetchData() async {
    var client = http.Client();
    final rawData = await client.get(url);
    return rawData.body;
  }
}
