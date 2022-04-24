import 'dart:convert';

import 'package:mcbroken/data/models/mcdonalds_model.dart';
import 'package:mcbroken/data/provider/mcdonalds.provider.dart';

class McDonaldsRepository {
  late final McDonaldsDataProvider mcDonaldsDataProvider =
      McDonaldsDataProvider();

  Future<List<McDonaldsModel>> getDatafromMcDonalds() async {
    final rawData = await mcDonaldsDataProvider.fetchData();
    List<McDonaldsModel> mcDonaldsData = List<McDonaldsModel>.from(
        json.decode(rawData).map((x) => McDonaldsModel.fromMap(x)));

    //final McDonaldsModel mcDonaldsData = McDonaldsModel.fromJson(rawData);

    return mcDonaldsData;
  }
}
