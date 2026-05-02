import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection. Check your connection and try again.']);
}

class LocationFailure extends Failure {
  const LocationFailure([super.message = 'Location access is required to find nearby stations.']);
}

class LocationPermissionDeniedFailure extends Failure {
  const LocationPermissionDeniedFailure([super.message = 'Location permission was denied. Enable it in Settings to continue.']);
}

class FirestoreFailure extends Failure {
  const FirestoreFailure([super.message = 'Could not load station data. Please try again.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed. Please sign in again.']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'No stations found in this area.']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong. Please try again.']);
}
