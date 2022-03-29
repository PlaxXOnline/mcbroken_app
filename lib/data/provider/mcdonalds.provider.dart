import 'package:http/http.dart' as http;

class McDonaldsDataProvider {
  var url = Uri.parse(
      'https://raw.githubusercontent.com/rashiq/mcbroken-archive/main/mcbroken.json');
  Future fetchData() async {
    final rawData = await http.get(url);
    return rawData;
  }
}
