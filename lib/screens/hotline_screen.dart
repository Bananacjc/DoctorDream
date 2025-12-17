import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/color_constant.dart';

class HotlineScreen extends StatefulWidget {
  const HotlineScreen({super.key});

  @override
  State<HotlineScreen> createState() => _HotlineScreenState();
}

class _HotlineScreenState extends State<HotlineScreen> {
  // Loaded from .env
  late final String _googleApiKey;
  
  bool _isLoading = true;
  String? _error;
  Position? _currentPosition;
  String _currentCountry = 'Unknown';
  String _currentCountryCode = 'US'; // Default
  
  // Maps
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<Clinic> _clinics = [];
  
  // Hotline Data (Simplified for major regions)
  final Map<String, String> _hotlines = {
    'US': '988', // USA
    'GB': '111', // UK
    'CA': '1-833-456-4566', // Canada
    'AU': '13 11 14', // Australia
    'IN': '9152987821', // India
    'SG': '1-767', // Singapore
    // Add more as needed
  };

  @override
  void initState() {
    super.initState();
    _loadEnvAndInit();
  }

  Future<void> _loadEnvAndInit() async {
    try {
      // Ensure .env is loaded (if not already in main)
      await dotenv.load(fileName: ".env");
      _googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
      _initLocationAndData();
    } catch (e) {
      print("Error loading .env: $e");
      // Fallback or handle error
      _googleApiKey = '';
      _initLocationAndData();
    }
  }

  Future<void> _initLocationAndData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Check Permissions
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable them.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      }

      // 2. Get Position
      final position = await Geolocator.getCurrentPosition();
      _currentPosition = position;

      // 3. Get Country
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          _currentCountry = placemarks.first.country ?? 'Unknown';
          _currentCountryCode = placemarks.first.isoCountryCode ?? 'US';
        }
      } catch (e) {
        print('Error getting address: $e');
      }

      // 4. Fetch Clinics (if API Key is set)
      if (_googleApiKey.isNotEmpty && _googleApiKey != 'YOUR_API_KEY_HERE') {
        await _fetchNearbyClinics(position.latitude, position.longitude);
      } else {
         // Mock data for UI testing if no API key
         _clinics = [
           Clinic(
             name: "Please Configure API Key",
             address: "Add GOOGLE_MAPS_API_KEY in .env file",
             rating: 5.0,
             userRatingsTotal: 1,
             lat: position.latitude + 0.001,
             lng: position.longitude + 0.001,
             placeId: "mock",
           )
         ];
      }

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchNearbyClinics(double lat, double lng) async {
    final radius = 5000; // 5km
    final type = 'doctor'; // broader than 'psychologist' sometimes better results, filter by keyword
    final keyword = 'psychologist';
    
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=$lat,$lng'
      '&radius=$radius'
      '&type=$type'
      '&keyword=$keyword'
      '&key=$_googleApiKey'
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          _clinics = results.map((e) => Clinic.fromJson(e)).toList();
          _updateMarkers();
        } else {
          print('Places API Error: ${data['status']} - ${data['error_message']}');
        }
      }
    } catch (e) {
      print('Error fetching clinics: $e');
    }
  }

  void _updateMarkers() {
    _markers = _clinics.map((clinic) {
      return Marker(
        markerId: MarkerId(clinic.placeId),
        position: LatLng(clinic.lat, clinic.lng),
        infoWindow: InfoWindow(title: clinic.name, snippet: clinic.address),
      );
    }).toSet();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _openMap(double lat, double lng) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotline = _hotlines[_currentCountryCode] ?? '112'; // Default emergency

    return Scaffold(
      backgroundColor: ColorConstant.surface,
      appBar: AppBar(
        backgroundColor: ColorConstant.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: ColorConstant.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Professional Support",
          style: GoogleFonts.robotoFlex(
            color: ColorConstant.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: ColorConstant.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: ColorConstant.onSurfaceVariant),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _initLocationAndData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstant.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: Text("Retry"),
                        )
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Hotline Section
                      Container(
                        margin: EdgeInsets.all(16),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [ColorConstant.secondary, ColorConstant.secondary.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: ColorConstant.secondary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.public, color: Colors.white, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  "Crisis Hotline ($_currentCountry)",
                                  style: GoogleFonts.robotoFlex(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(
                              hotline,
                              style: GoogleFonts.robotoFlex(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _makePhoneCall(hotline),
                                icon: Icon(Icons.phone),
                                label: Text("Call Now"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: ColorConstant.secondary,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                        child: Text(
                          "Nearby Clinics",
                          style: GoogleFonts.robotoFlex(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: ColorConstant.onSurface,
                          ),
                        ),
                      ),

                      if (_googleApiKey.isEmpty || _googleApiKey == 'YOUR_API_KEY_HERE')
                        Container(
                          margin: EdgeInsets.all(16),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withOpacity(0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Google Maps API Key Missing",
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800]),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                "To see nearby clinics, add `GOOGLE_MAPS_API_KEY=your_key` in the `.env` file at the root of your project.",
                                style: TextStyle(color: Colors.orange[900], fontSize: 13),
                              ),
                            ],
                          ),
                        ),

                      // 2. Map Section
                      if (_currentPosition != null)
                        Container(
                          height: 250,
                          margin: EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 10),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                zoom: 13,
                              ),
                              markers: _markers,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              onMapCreated: (controller) => _mapController = controller,
                            ),
                          ),
                        ),

                      SizedBox(height: 16),

                      // 3. Clinic List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _clinics.length,
                        itemBuilder: (context, index) {
                          final clinic = _clinics[index];
                          return Card(
                            elevation: 0,
                            color: ColorConstant.surfaceContainer,
                            margin: EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: ColorConstant.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.medical_services, color: ColorConstant.primary),
                              ),
                              title: Text(
                                clinic.name,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onTap: () {
                                _mapController?.animateCamera(
                                  CameraUpdate.newLatLng(
                                    LatLng(clinic.lat, clinic.lng),
                                  ),
                                );
                              },
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text(clinic.address, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  if (clinic.rating != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.star, size: 14, color: Colors.amber),
                                          SizedBox(width: 4),
                                          Text("${clinic.rating} (${clinic.userRatingsTotal})", style: TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.directions, color: ColorConstant.primary),
                                onPressed: () => _openMap(clinic.lat, clinic.lng),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }
}

class Clinic {
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String placeId;
  final double? rating;
  final int? userRatingsTotal;

  Clinic({
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.placeId,
    this.rating,
    this.userRatingsTotal,
  });

  factory Clinic.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry']['location'];
    return Clinic(
      name: json['name'] ?? 'Unknown Clinic',
      address: json['vicinity'] ?? 'Address unavailable',
      lat: geometry['lat'],
      lng: geometry['lng'],
      placeId: json['place_id'],
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      userRatingsTotal: json['user_ratings_total'],
    );
  }
}

