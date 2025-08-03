import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map_marker_cluster_plus/flutter_map_marker_cluster_plus.dart';
import 'package:mcbroken/l10n/app_localizations.dart';
import 'package:mcbroken/logic/blocs/home/home_bloc.dart';
import 'package:mcbroken/presentation/widgets/facilitymarker.dart';

/// Ein modernes Popup-Widget für die Anzeige von McDonald's Filialinformationen
/// 
/// Zeigt Informationen zu einer McDonald's Filiale mit modernem Design an,
/// inklusive Status der Eismaschine und Favoriten-Funktionalität.
class InfoPopup extends StatelessWidget {
  /// Erstellt ein neues InfoPopup-Widget
  ///
  /// [size] ist die Bildschirmgröße für responsive Gestaltung
  /// [locale] ist das Lokalisierungsobjekt für mehrsprachige Texte
  /// [facilityMarker] ist der Marker mit den Filialinformationen
  /// [popupController] ist der Controller zum Schließen des Popups
  const InfoPopup({
    super.key,
    required this.size,
    required this.locale,
    required this.facilityMarker,
    required this.popupController,
  });

  final Size size;
  final AppLocalizations locale;
  final FacilityMarker facilityMarker;
  final PopupController popupController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(16),
      shadowColor: Colors.black.withOpacity(0.3),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: size.width * 0.75,
          minWidth: 240,
          maxHeight: size.height * 0.22,
          minHeight: 140,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.95),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Favoriten-Button oben links
            Positioned(
              top: 4,
              left: 4,
              child: _buildFavoritesIcon(context),
            ),
            // Schließen-Button oben rechts
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: () => popupController.hideAllPopups(),
                icon: const Icon(Icons.close, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: theme.colorScheme.onSurface.withOpacity(0.6),
                  padding: const EdgeInsets.all(4),
                  minimumSize: const Size(24, 24),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 24), // Platz für Icons
                  _buildHeader(),
                  const SizedBox(height: 8),
                  _buildLocationInfo(theme),
                  const SizedBox(height: 8),
                  _buildStatusCard(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Erstellt den Header-Bereich mit dem McFlurry-Logo
  ///
  /// Gibt ein Widget mit dem McFlurry-Logo zurück
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Image.asset(
        'assets/flurry_big_transparent.png',
        height: 36,
        width: 36,
        fit: BoxFit.contain,
      ),
    );
  }

  /// Erstellt den Informationsbereich mit McDonald's und Adressdaten
  ///
  /// [theme] ist das aktuelle Theme für Styling-Informationen
  /// 
  /// Gibt ein Widget mit McDonald's Namen und Adresse zurück
  Widget _buildLocationInfo(ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant,
              color: theme.colorScheme.primary,
              size: 16,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '${locale.mcDonalds} ${facilityMarker.city}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.place,
              color: theme.colorScheme.secondary,
              size: 14,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                facilityMarker.street,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Erstellt die Status-Karte für die Eismaschine
  ///
  /// [theme] ist das aktuelle Theme für Styling-Informationen
  /// 
  /// Gibt ein Widget mit dem Status der Eismaschine zurück
  Widget _buildStatusCard(ThemeData theme) {
    final bool isWorking = facilityMarker.dot == 'working';
    final Color statusColor = isWorking ? Colors.green : Colors.red;
    final IconData statusIcon = isWorking ? Icons.check_circle : Icons.cancel;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.ac_unit,
            color: theme.colorScheme.primary,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            locale.iceMachine,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            statusIcon,
            color: statusColor,
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            isWorking ? locale.working : locale.notWorking,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Erstellt ein dezentes Favoriten-Icon für die obere linke Ecke
  ///
  /// [context] ist der BuildContext für den Zugriff auf den BLoC
  /// 
  /// Gibt ein Icon-Widget zurück, das je nach Favoritenstatus unterschiedlich aussieht
  Widget _buildFavoritesIcon(BuildContext context) {
    // Generieren einer eindeutigen ID für den Standort
    // Zugriff auf die Koordinaten über das point-Attribut der Marker-Klasse
    final String locationId = '${facilityMarker.point.longitude}_${facilityMarker.point.latitude}';
    final theme = Theme.of(context);
    
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        // Prüfen, ob der aktuelle Standort in den Favoriten ist
        bool isFavorite = false;
        
        if (state is HomeStateLoaded) {
          isFavorite = state.favorites.contains(locationId);
        } else if (state is HomeStateNoLocation) {
          isFavorite = state.favorites.contains(locationId);
        }
        
        return IconButton(
          onPressed: () {
            if (isFavorite) {
              context.read<HomeBloc>().add(RemoveFromFavoritesEvent(locationId: locationId));
            } else {
              context.read<HomeBloc>().add(AddToFavoritesEvent(locationId: locationId));
            }
          },
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            size: 18,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: isFavorite 
              ? Colors.red 
              : theme.colorScheme.onSurface.withOpacity(0.6),
            padding: const EdgeInsets.all(4),
            minimumSize: const Size(24, 24),
          ),
        );
      },
    );
  }
}
