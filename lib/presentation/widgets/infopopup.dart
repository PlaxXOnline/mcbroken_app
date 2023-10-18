import 'package:flutter/material.dart';
import 'package:mcbroken/presentation/widgets/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class InfoPopup extends StatelessWidget {
  const InfoPopup({
    super.key,
    required this.size,
    required this.locale,
    required this.facilityMarker,
  });

  final Size size;
  final AppLocalizations locale;
  final FacilityMarker facilityMarker;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: size.width * 0.6,
        height: size.height * 0.3,
        color: Colors.white,
        child: GestureDetector(
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
            child: Column(
              children: [
                SizedBox(
                  height: size.height * 0.125,
                  width: size.width * 0.25,
                  child: Image.asset('assets/flurry_big_transparent.png'),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      locale.mcDonalds,
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      facilityMarker.city,
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  facilityMarker.street,
                  style: const TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      locale.iceMachine,
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      facilityMarker.dot == 'working'
                          ? locale.working
                          : locale.notWorking,
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      facilityMarker.dot == 'working'
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: facilityMarker.dot == 'working'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
