/// Utility class for location-based auto-detection of prayer time calculation methods
class LocationHelper {
  /// Detect calculation method based on coordinates
  /// Returns the recommended calculation method for the given location
  static String detectCalculationMethod(double latitude, double longitude) {
    // Singapore
    // Approximate bounds: lat 1.0-1.5, lon 103.5-104.5
    if (latitude >= 1.0 && latitude <= 1.5 && 
        longitude >= 103.5 && longitude <= 104.5) {
      return 'singapore';
    }
    
    // Indonesia
    // Approximate bounds: lat -11 to 6, lon 95 to 141
    if (latitude >= -11.0 && latitude <= 6.0 && 
        longitude >= 95.0 && longitude <= 141.0) {
      return 'indonesia';
    }
    
    // Malaysia
    // Approximate bounds: lat 0.5 to 7.5, lon 99.5 to 119.5
    if (latitude >= 0.5 && latitude <= 7.5 && 
        longitude >= 99.5 && longitude <= 119.5) {
      return 'mwl'; // Malaysia commonly uses MWL
    }
    
    // United Arab Emirates (Dubai)
    // Approximate bounds: lat 22.5 to 26, lon 51 to 56.5
    if (latitude >= 22.5 && latitude <= 26.0 && 
        longitude >= 51.0 && longitude <= 56.5) {
      return 'dubai';
    }
    
    // Qatar
    // Approximate bounds: lat 24.5 to 26.2, lon 50.7 to 51.6
    if (latitude >= 24.5 && latitude <= 26.2 && 
        longitude >= 50.7 && longitude <= 51.6) {
      return 'qatar';
    }
    
    // Kuwait
    // Approximate bounds: lat 28.5 to 30.1, lon 46.5 to 48.5
    if (latitude >= 28.5 && latitude <= 30.1 && 
        longitude >= 46.5 && longitude <= 48.5) {
      return 'kuwait';
    }
    
    // Saudi Arabia (Umm al-Qura for Makkah/Madinah region)
    // Approximate bounds: lat 16 to 32, lon 34 to 55
    if (latitude >= 16.0 && latitude <= 32.0 && 
        longitude >= 34.0 && longitude <= 55.0) {
      // Check if in Makkah/Madinah region (more specific)
      if (latitude >= 21.0 && latitude <= 25.0 && 
          longitude >= 39.0 && longitude <= 40.5) {
        return 'umm_al_qura';
      }
      // Other parts of Saudi Arabia might use different methods
      return 'umm_al_qura';
    }
    
    // Egypt
    // Approximate bounds: lat 22 to 31.7, lon 24.5 to 37
    if (latitude >= 22.0 && latitude <= 31.7 && 
        longitude >= 24.5 && longitude <= 37.0) {
      return 'egypt';
    }
    
    // Pakistan (Karachi region)
    // Approximate bounds: lat 23.5 to 37, lon 60.5 to 77.8
    if (latitude >= 23.5 && latitude <= 37.0 && 
        longitude >= 60.5 && longitude <= 77.8) {
      return 'karachi';
    }
    
    // Turkey
    // Approximate bounds: lat 35.8 to 42.1, lon 25.7 to 44.8
    if (latitude >= 35.8 && latitude <= 42.1 && 
        longitude >= 25.7 && longitude <= 44.8) {
      return 'turkey';
    }
    
    // Iran (Tehran)
    // Approximate bounds: lat 25 to 40, lon 44 to 63.3
    if (latitude >= 25.0 && latitude <= 40.0 && 
        longitude >= 44.0 && longitude <= 63.3) {
      return 'tehran';
    }
    
    // North America (USA, Canada)
    // Approximate bounds: lat 24.5 to 71.5, lon -180 to -50
    if (latitude >= 24.5 && latitude <= 71.5 && 
        longitude >= -180.0 && longitude <= -50.0) {
      return 'isna';
    }
    
    // Default to MWL (Muslim World League) - most commonly used worldwide
    return 'mwl';
  }
  
  /// Get timezone name based on coordinates
  /// Returns common timezone for the region
  static String detectTimezone(double latitude, double longitude) {
    // Singapore
    if (latitude >= 1.0 && latitude <= 1.5 && 
        longitude >= 103.5 && longitude <= 104.5) {
      return 'Asia/Singapore';
    }
    
    // Indonesia - multiple timezones
    if (latitude >= -11.0 && latitude <= 6.0 && 
        longitude >= 95.0 && longitude <= 141.0) {
      // Java island (WIB): lat -8.5 to -5.5, lon 105-115
      // Includes: Jakarta (~-6.2, 106.8), Bandung, Yogyakarta, Surabaya, Bali
      if (latitude >= -8.5 && latitude <= -5.5 && longitude >= 105.0 && longitude < 115.0) {
        return 'Asia/Jakarta';
      }
      // Sumatra (WIB): lon 95-105
      if (longitude >= 95.0 && longitude < 105.0) {
        return 'Asia/Jakarta';
      }
      // Western Kalimantan (WIB): lon 108-114, lat -3 to 1
      if (latitude >= -3.0 && latitude <= 1.0 && longitude >= 108.0 && longitude < 114.0) {
        return 'Asia/Jakarta';
      }
      // Central Indonesia (WITA): lon 115-135 (Kalimantan Tengah/Timur, Sulawesi, NTT)
      if (longitude >= 115.0 && longitude < 135.0) {
        return 'Asia/Makassar';
      }
      // Eastern Indonesia (WIT): lon 135-141 (Papua)
      if (longitude >= 135.0 && longitude <= 141.0) {
        return 'Asia/Jayapura';
      }
      // Default to Jakarta (WIB) for most Indonesian locations
      return 'Asia/Jakarta';
    }
    
    // Malaysia
    if (latitude >= 0.5 && latitude <= 7.5 && 
        longitude >= 99.5 && longitude <= 119.5) {
      return 'Asia/Kuala_Lumpur';
    }
    
    // UAE
    if (latitude >= 22.5 && latitude <= 26.0 && 
        longitude >= 51.0 && longitude <= 56.5) {
      return 'Asia/Dubai';
    }
    
    // Qatar
    if (latitude >= 24.5 && latitude <= 26.2 && 
        longitude >= 50.7 && longitude <= 51.6) {
      return 'Asia/Qatar';
    }
    
    // Kuwait
    if (latitude >= 28.5 && latitude <= 30.1 && 
        longitude >= 46.5 && longitude <= 48.5) {
      return 'Asia/Kuwait';
    }
    
    // Saudi Arabia
    if (latitude >= 16.0 && latitude <= 32.0 && 
        longitude >= 34.0 && longitude <= 55.0) {
      return 'Asia/Riyadh';
    }
    
    // Egypt
    if (latitude >= 22.0 && latitude <= 31.7 && 
        longitude >= 24.5 && longitude <= 37.0) {
      return 'Africa/Cairo';
    }
    
    // Pakistan
    if (latitude >= 23.5 && latitude <= 37.0 && 
        longitude >= 60.5 && longitude <= 77.8) {
      return 'Asia/Karachi';
    }
    
    // Turkey
    if (latitude >= 35.8 && latitude <= 42.1 && 
        longitude >= 25.7 && longitude <= 44.8) {
      return 'Europe/Istanbul';
    }
    
    // Iran
    if (latitude >= 25.0 && latitude <= 40.0 && 
        longitude >= 44.0 && longitude <= 63.3) {
      return 'Asia/Tehran';
    }
    
    // Default to UTC
    return 'UTC';
  }
}

