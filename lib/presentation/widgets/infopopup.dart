import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mcbroken/logic/blocs/home/home_bloc.dart';
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
                const SizedBox(height: 10),
                _buildFavoritesButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Erstellt einen Button zum Hinzufügen/Entfernen aus Favoriten
  ///
  /// [context] ist der BuildContext für den Zugriff auf den BLoC
  /// 
  /// Gibt ein Widget zurück, das je nach Favoritenstatus unterschiedlich aussieht
  Widget _buildFavoritesButton(BuildContext context) {
    // Generieren einer eindeutigen ID für den Standort
    // Zugriff auf die Koordinaten über das point-Attribut der Marker-Klasse
    final String locationId = '${facilityMarker.point.longitude}_${facilityMarker.point.latitude}';
    
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        // Prüfen, ob der aktuelle Standort in den Favoriten ist
        bool isFavorite = false;
        
        if (state is HomeStateLoaded) {
          isFavorite = state.favorites.contains(locationId);
        } else if (state is HomeStateNoLocation) {
          isFavorite = state.favorites.contains(locationId);
        }
        
        return TextButton.icon(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.grey,
          ),
          label: Text(
            isFavorite ? locale.removeFromFavorites : locale.addToFavorites,
            style: TextStyle(
              color: isFavorite ? Colors.red : Colors.grey,
              fontSize: 12,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () {
            if (isFavorite) {
              context.read<HomeBloc>().add(RemoveFromFavoritesEvent(locationId: locationId));
            } else {
              context.read<HomeBloc>().add(AddToFavoritesEvent(locationId: locationId));
            }
          },
        );
      },
    );
  }
}
