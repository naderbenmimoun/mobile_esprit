import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../config/map_config.dart';
import '../main.dart';
import '../database/database_helper.dart';
import '../models/user_profile.dart';

const String kMapTilerKey = MapConfig.mapTilerKey;
const String kMapboxToken = MapConfig.mapboxToken;

class LivraisonScreen extends StatefulWidget {
  const LivraisonScreen({super.key});

  @override
  State<LivraisonScreen> createState() => _LivraisonScreenState();
}

class _LivraisonScreenState extends State<LivraisonScreen> {
  final TextEditingController nom = TextEditingController();
  final TextEditingController adresse = TextEditingController();
  final TextEditingController ville = TextEditingController();
  final TextEditingController cp = TextEditingController();

  // Position du client
  LatLng _clientPosition = const LatLng(36.8065, 10.1815); // Par défaut Tunis
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.local_shipping, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text('Livraison'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Étapes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _stepCircle(theme, 1, done: true),
                  _stepLine(theme),
                  _stepCircle(theme, 2, done: true),
                  _stepLine(theme),
                  _stepCircle(theme, 3, done: false),
                ],
              ),
              const SizedBox(height: 28),

              Text(
                'Adresse de livraison',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              _StyledTextField(
                  controller: nom,
                  label: 'Nom complet',
                  icon: Icons.person,
                  color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              _StyledTextField(
                  controller: adresse,
                  label: 'Adresse',
                  icon: Icons.home,
                  color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              _StyledTextField(
                  controller: ville,
                  label: 'Ville',
                  icon: Icons.location_city,
                  color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              _StyledTextField(
                  controller: cp,
                  label: 'Code Postal',
                  icon: Icons.map,
                  color: theme.colorScheme.primary,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 24),

              // Carte
              SizedBox(
                height: 250,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialZoom: 14,
                        initialCenter: _clientPosition,
                        onTap: (tapPosition, point) {
                          setState(() {
                            _clientPosition = point;
                          });
                        },
                      ),
                      children: [
                        if (kMapboxToken.isNotEmpty)
                          TileLayer(
                            urlTemplate: 'https://api.mapbox.com/styles/v1/{id}/tiles/256/{z}/{x}/{y}@2x?access_token={accessToken}',
                            additionalOptions: {
                              'accessToken': kMapboxToken,
                              'id': 'mapbox/streets-v12',
                            },
                            userAgentPackageName: 'com.example.workshopmobileseance1',
                            maxNativeZoom: 22,
                          )
                        else if (kMapTilerKey.isNotEmpty)
                          TileLayer(
                            urlTemplate: 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key={key}',
                            additionalOptions: {'key': kMapTilerKey},
                            userAgentPackageName: 'com.example.workshopmobileseance1',
                            maxNativeZoom: 20,
                          )
                        else
                          TileLayer(
                            urlTemplate: 'https://maps.wikimedia.org/osm-intl/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.workshopmobileseance1',
                          ),
                        MarkerLayer(markers: [
                          Marker(
                            point: _clientPosition,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                          ),
                        ]),
                        RichAttributionWidget(
                          alignment: AttributionAlignment.bottomRight,
                          attributions: [
                            if (kMapboxToken.isNotEmpty)
                              const TextSourceAttribution('© Mapbox, © OpenStreetMap contributors')
                            else if (kMapTilerKey.isNotEmpty)
                              const TextSourceAttribution('© MapTiler, © OpenStreetMap contributors')
                            else
                              const TextSourceAttribution('© Wikimedia, © OpenStreetMap contributors'),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Column(
                        children: [
                          FloatingActionButton.small(
                            heroTag: 'zoom_in',
                            onPressed: () {
                              final c = _mapController.camera.center;
                              final z = _mapController.camera.zoom + 1;
                              _mapController.move(c, z);
                            },
                            child: const Icon(Icons.add),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: 'zoom_out',
                            onPressed: () {
                              final c = _mapController.camera.center;
                              final z = _mapController.camera.zoom - 1;
                              _mapController.move(c, z);
                            },
                            child: const Icon(Icons.remove),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: 'my_location',
                            onPressed: _goToCurrentLocation,
                            child: const Icon(Icons.my_location),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Bouton Continuer vers paiement
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.payment, color: Colors.white, size: 26),
                  label: const Text(
                    'Continuer vers paiement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    final adresseMap = {
                      'nom': nom.text,
                      'adresse': adresse.text,
                      'ville': ville.text,
                      'cp': cp.text,
                      'lat': _clientPosition.latitude,
                      'lng': _clientPosition.longitude,
                    };
                    Navigator.pushNamed(context, '/paiement',
                        arguments: {'adresse': jsonEncode(adresseMap)});
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillName());
  }

  Future<void> _prefillName() async {
    try {
      final auth = AuthScope.watch(context);
      final user = auth.currentUser;
      String? fullName;
      final db = DatabaseHelper.instance;
      UserProfile? profile;
      try {
        profile = await db.getUserProfile();
      } catch (_) {}
      if (profile != null && profile.name.trim().isNotEmpty) {
        fullName = profile.name.trim();
      } else if (user != null && user.email.isNotEmpty) {
        final local = user.email.split('@').first;
        fullName = local.replaceAll('.', ' ').replaceAll('_', ' ');
      }
      if (fullName != null && fullName.isNotEmpty && mounted) {
        nom.text = fullName;
      }
    } catch (_) {}
  }

  Future<void> _goToCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Active le service de localisation.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission localisation refusée.')),
      );
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final newCenter = LatLng(pos.latitude, pos.longitude);
    if (!mounted) return;
    setState(() {
      _clientPosition = newCenter;
    });
    _mapController.move(newCenter, _mapController.camera.zoom);
  }

  Widget _stepCircle(ThemeData theme, int number, {bool done = false}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
          color: done ? theme.colorScheme.primary : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: theme.colorScheme.primary, width: 2)),
      alignment: Alignment.center,
      child: done
          ? const Icon(Icons.check, color: Colors.white, size: 22)
          : Text(number.toString(),
              style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
    );
  }

  Widget _stepLine(ThemeData theme) =>
      Container(width: 40, height: 2, color: theme.colorScheme.primary);
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  final TextInputType? keyboardType;
  final double fontSize;
  final double labelSize;
  final String? Function(String?)? validator;

  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.color,
    this.keyboardType,
    this.fontSize = 16,
    this.labelSize = 15,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      cursorColor: color,
      validator: validator,
      style: TextStyle(fontSize: fontSize, letterSpacing: 1),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: labelSize, fontWeight: FontWeight.w500, color: color),
        prefixIcon: Icon(icon, color: color, size: 26),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: color.withOpacity(0.18))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: color, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.shade300, width: 2)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.red.shade400, width: 2)),
      ),
    );
  }
}
