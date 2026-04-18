import 'package:flutter/material.dart';

class WeatherCard extends StatelessWidget {
  final double temperature;
  final String condition;
  final String location;
  final int humidity;
  final double windSpeed;
  final int uvIndex;
  final bool isLoading;
  final double feelsLike;
  final double precipitation;
  final String description;

  const WeatherCard({
    super.key,
    this.temperature = 0,
    this.condition = 'Unknown',
    this.location = 'Unknown',
    this.humidity = 0,
    this.windSpeed = 0,
    this.uvIndex = 0,
    this.isLoading = false,
    this.feelsLike = 0,
    this.precipitation = 0,
    this.description = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s Weather',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              _getWeatherIcon(condition),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${temperature.round()}°C',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    condition,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherDetail(
                context,
                Icons.water_drop,
                '$humidity%',
                'Humidity',
              ),
              _buildWeatherDetail(
                context,
                Icons.air,
                '${windSpeed.toStringAsFixed(1)} km/h',
                'Wind',
              ),
              _buildWeatherDetail(
                context,
                Icons.umbrella,
                '${precipitation.toStringAsFixed(1)} mm',
                'Precip',
              ),
              _buildWeatherDetail(
                context,
                Icons.thermostat,
                '${feelsLike.round()}°C',
                'Feels Like',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(
      BuildContext context,
      IconData icon,
      String value,
      String label,
      ) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _getWeatherIcon(String condition) {
    IconData iconData;

    // Mapping weather conditions to icons
    switch (condition.toLowerCase()) {
      case 'clear':
        iconData = Icons.wb_sunny;
        break;
      case 'clouds':
        iconData = Icons.cloud;
        break;
      case 'rain':
        iconData = Icons.water_drop;
        break;
      case 'thunderstorm':
        iconData = Icons.thunderstorm;
        break;
      case 'snow':
        iconData = Icons.ac_unit;
        break;
      case 'mist':
        iconData = Icons.cloud_queue;
        break;
      default:
        iconData = Icons.wb_sunny;
    }

    return Icon(
      iconData,
      color: Colors.white,
      size: 36,
    );
  }
}