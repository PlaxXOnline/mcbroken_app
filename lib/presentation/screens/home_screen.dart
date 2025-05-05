// filepath: /Users/janikkahle/Documents/Development/Projekte/Mobile/mcbroken_app/lib/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mcbroken/constants/enums.dart';
import 'package:mcbroken/logic/blocs/home/home_bloc.dart';
import 'package:mcbroken/logic/cubits/connectivity/internet_cubit.dart';
import 'package:mcbroken/presentation/screens/settings_screen.dart';
import 'package:mcbroken/presentation/widgets/map.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Hauptbildschirm der Anwendung
///
/// Zeigt die Karte mit den McDonald's-Standorten und den Status ihrer Eismaschinen an.
/// Reagiert auf den Verbindungsstatus und den aktuellen HomeBloc-Zustand.
class HomeScreen extends StatefulWidget {
  /// Erstellt einen neuen HomeScreen
  ///
  /// [key] ist ein optionaler Schlüssel zur Identifikation dieses Widgets
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Controller für das Suchfeld
  final TextEditingController _searchController = TextEditingController();

  /// Baut die Suchleiste für die Ortssuche
  Widget _buildSearchBar(BuildContext context, AppLocalizations locale) {
    final homeBloc = context.read<HomeBloc>();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Suchfeld mit Autocomplete
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: locale.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            homeBloc.add(ResetSearchEvent());
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
                ),
                onChanged: (value) {
                  // Aktualisieren der UI, um den Clear-Button anzuzeigen
                  setState(() {});
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    homeBloc.add(SearchLocationsEvent(query: value));
                  } else {
                    homeBloc.add(ResetSearchEvent());
                  }
                },
              ),
            ),
          ),
          
          // Filteroptionen
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context, locale);
            },
          ),
        ],
      ),
    );
  }
  
  /// Zeigt einen Dialog mit Filteroptionen an
  Future<void> _showFilterDialog(BuildContext context, AppLocalizations locale) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final homeBloc = context.read<HomeBloc>();
        final currentState = homeBloc.state;
        
        bool? showOnlyBroken;
        bool? showOnlyWorking;
        
        if (currentState is HomeStateLoaded) {
          showOnlyBroken = currentState.showOnlyBroken;
          showOnlyWorking = currentState.showOnlyWorking;
        } else if (currentState is HomeStateNoLocation) {
          showOnlyBroken = currentState.showOnlyBroken;
          showOnlyWorking = currentState.showOnlyWorking;
        }
        
        bool onlyFavorites = false;
        
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(locale.filterTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(locale.showAll),
                    leading: Radio<bool?>(
                      value: null,
                      groupValue: showOnlyBroken == null && showOnlyWorking == null ? null : false,
                      onChanged: (value) {
                        setState(() {
                          showOnlyBroken = null;
                          showOnlyWorking = null;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: Text(locale.showOnlyDefect),
                    leading: Radio<bool?>(
                      value: true,
                      groupValue: showOnlyBroken,
                      onChanged: (value) {
                        setState(() {
                          showOnlyBroken = value;
                          showOnlyWorking = null;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: Text(locale.showOnlyWorking),
                    leading: Radio<bool?>(
                      value: true,
                      groupValue: showOnlyWorking,
                      onChanged: (value) {
                        setState(() {
                          showOnlyWorking = value;
                          showOnlyBroken = null;
                        });
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: Text(locale.favorites),
                    leading: Checkbox(
                      value: onlyFavorites,
                      onChanged: (value) {
                        setState(() {
                          onlyFavorites = value ?? false;
                        });
                      },
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(locale.cancel),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(locale.apply),
                  onPressed: () {
                    homeBloc.add(FilterLocationsEvent(
                      onlyBroken: showOnlyBroken,
                      onlyWorking: showOnlyWorking,
                      onlyFavorites: onlyFavorites,
                    ));
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Native Splash Screen entfernen, sobald der Bildschirm aufgebaut ist
    FlutterNativeSplash.remove();
    
    // Lokalisierungsobjekt für übersetzte Texte
    final AppLocalizations locale = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        actions: [
          // Einstellungsschaltfläche
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()));
            },
          ),
        ],
        leading: Image.asset(
          'assets/flurry_icon.ico',
        ),
        title: Text(
          locale.appTitle,
          style: GoogleFonts.courgette(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: _buildSearchBar(context, locale),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            Builder(
              builder: (blocContext) {
                // Überwachen des Internetverbindungsstatus
                var internetState = context.watch<InternetCubit>().state;
                
                // Wenn über WLAN oder Mobilfunk verbunden
                if (internetState is InternetConnected &&
                        internetState.connectionType == ConnectionType.Wifi ||
                    internetState is InternetConnected &&
                        internetState.connectionType == ConnectionType.Mobile) {
                  // Daten anfordern bei Verbindung
                  context.read<HomeBloc>().add(DataRequestEvent());
                  
                  return Flexible(
                    child: Builder(
                      builder: ((context) {
                        // Überwachen des HomeBloc-Zustands
                        final homeState = context.watch<HomeBloc>().state;
                        
                        // Je nach State passende UI anzeigen
                        if (homeState is HomeStateLoaded) {
                          return const McDonaldsMap();
                        } else if (homeState is HomeStateNoLocation) {
                          // Wenn Daten geladen wurden, aber keine Position verfügbar ist
                          return const McDonaldsMap();
                        } else if (homeState is HomeStateOffline) {
                          // Bei Offline-Status mit verfügbaren Cache-Daten
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Offline-Modus',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(homeState.message),
                              const SizedBox(height: 16),
                              const Expanded(child: McDonaldsMap()),
                            ],
                          );
                        } else if (homeState is HomeStateError) {
                          // Bei Fehlern
                          return Center(
                            child: Text(homeState.message),
                          );
                        } else {
                          // Ladeindikator für alle anderen Zustände
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                      }),
                    ),
                  );
                } else if (internetState is InternetDisconnected) {
                  // Wenn keine Internetverbindung besteht
                  return Text(locale.noConnection);
                }
                
                // Ladeindikator während die Verbindung geprüft wird
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
      ),
    );
  }
}
