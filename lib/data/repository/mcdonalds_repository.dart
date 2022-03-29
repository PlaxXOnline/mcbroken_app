import 'package:mcbroken/data/models/mcdonalds_model.dart';
import 'package:mcbroken/data/provider/mcdonalds.provider.dart';

class McDonaldsRepository {
  late final McDonaldsDataProvider mcDonaldsDataProvider;

  Future<Mcdonalds_model> getDatafromMcDonalds() async {
    final rawData = await mcDonaldsDataProvider.fetchData();

    final Mcdonalds_model mcDonaldsData = Mcdonalds_model.fromJson(rawData);

    return mcDonaldsData;
  }
}
