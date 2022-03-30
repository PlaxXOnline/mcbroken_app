import 'dart:convert';

import 'package:mcbroken/data/models/mcdonalds_model.dart';
import 'package:mcbroken/data/provider/mcdonalds.provider.dart';

class McDonaldsRepository {
  late final McDonaldsDataProvider mcDonaldsDataProvider;

  Future<List<Mcdonalds_model>> getDatafromMcDonalds() async {
    final rawData = await mcDonaldsDataProvider.fetchData();
    List<Mcdonalds_model> mcDonaldsData = List<Mcdonalds_model>.from(
        json.decode(rawData).map((x) => Mcdonalds_model.fromJson(x)));

    //final Mcdonalds_model mcDonaldsData = Mcdonalds_model.fromJson(rawData);

    return mcDonaldsData;
  }
}
