import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'dart:convert';

void main() {
  runApp(const SkyScopeApp());
}

class SkyScopeApp extends StatelessWidget {
  const SkyScopeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkyScope',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      home: const SplashScreen(),
    );
  }
}

// SPLASH SCREEN
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4A90E2),
              Color(0xFF50C9F5),
              Color(0xFF87CEEB),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wb_sunny_outlined,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'SkyScope',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your Weather Companion',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// HOME SCREEN
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _locationController = TextEditingController();
  final Dio _dio = Dio();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _prediction;

  final List<String> _popularCities = [
    'New York',
    'London',
    'Tokyo',
    'Paris',
    'Dubai',
    'Sydney',
    'Cairo',
    'Mumbai'
  ];

  @override
  void initState() {
    super.initState();
    // Configure Dio
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A90E2),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _fetchPrediction() async {
    if (_locationController.text.isEmpty) {
      setState(() {
        _error = 'Please enter a location';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _prediction = null;
    });

    try {
      final dateStr =
          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      
      final response = await _dio.get(
        'https://wiromp-node.vercel.app/api/predict',
        queryParameters: {
          'date': dateStr,
          'location': _locationController.text,
        },
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.data);
          setState(() {
            _prediction = data;
            _isLoading = false;
          });
        } catch (e) {
          setState(() {
            _error = 'Invalid response format from server';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to fetch prediction';
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        if (e.type == DioExceptionType.connectionTimeout) {
          _error = 'Connection timeout';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          _error = 'Receive timeout';
        } else if (e.type == DioExceptionType.connectionError) {
          _error = 'No internet connection';
        } else {
          _error = 'Error: ${e.message}';
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unexpected error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A90E2),
              Color(0xFF87CEEB),
              Color(0xFFE0F7FA),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'SkyScope',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Predict the weather anywhere, anytime',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 40),

                // INPUT CARD
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location Input
                      const Text(
                        '📍 Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A90E2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          hintText: 'Enter city name',
                          filled: true,
                          fillColor: const Color(0xFFF5F9FC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.location_on,
                              color: Color(0xFF4A90E2)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: _popularCities
                            .map((city) => InkWell(
                                  onTap: () {
                                    _locationController.text = city;
                                  },
                                  child: Chip(
                                    label: Text(city),
                                    backgroundColor: const Color(0xFFE3F2FD),
                                    labelStyle: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF4A90E2),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 24),

                      // Date Picker
                      const Text(
                        '📅 Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A90E2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F9FC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: Color(0xFF4A90E2)),
                              const SizedBox(width: 12),
                              Text(
                                '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Get Prediction Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _fetchPrediction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'Get Prediction',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Error Display
                if (_error != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Prediction Result Card
                if (_prediction != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Weather Prediction',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A90E2),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Rain Status
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: (_prediction!['prediction']['rain']
                                            as bool)
                                        ? const Color(0xFFE3F2FD)
                                        : const Color(0xFFFFF9C4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    (_prediction!['prediction']['rain']
                                            as bool)
                                        ? Icons.water_drop
                                        : Icons.wb_sunny,
                                    size: 40,
                                    color: (_prediction!['prediction']['rain']
                                            as bool)
                                        ? const Color(0xFF4A90E2)
                                        : const Color(0xFFFFA726),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  (_prediction!['prediction']['rain'] as bool)
                                      ? 'Rainy'
                                      : 'Sunny',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            // Temperature
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFEBEE),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.thermostat,
                                    size: 40,
                                    color: Color(0xFFEF5350),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _prediction!['prediction']['temperature'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${_prediction!['location']} • ${_prediction!['date']}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}