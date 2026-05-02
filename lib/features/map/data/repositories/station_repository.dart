import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/gas_station.dart';

abstract class StationRepository {
  Future<Either<Failure, List<GasStation>>> getStationsNearby({
    required LatLng center,
    required double radiusMeters,
    FuelFilter? filter,
  });

  Future<Either<Failure, GasStation>> getStationById(String id);

  Future<Either<Failure, void>> reportPrice({
    required String stationId,
    required FuelGrade grade,
    required double price,
    required String userId,
  });
}

class StationRepositoryImpl implements StationRepository {
  StationRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<Either<Failure, List<GasStation>>> getStationsNearby({
    required LatLng center,
    required double radiusMeters,
    FuelFilter? filter,
  }) async {
    try {
      // Firestore doesn't support nested geopoint field queries,
      // so we fetch all stations and filter by distance in-memory
      Query<Map<String, dynamic>> query = _firestore.collection('stations');

      // Apply brand filter at Firestore level if available
      if (filter?.brands.isNotEmpty == true) {
        final brandNames = filter!.brands.map((b) => b.name).toList();
        query = query.where('brand', whereIn: brandNames);
      }

      // Fetch with a high limit to ensure we get nearby stations
      final snapshot = await query
          .limit(AppConstants.stationPageSize * 2)
          .get()
          .timeout(AppConstants.apiTimeout);

      var stations = snapshot.docs
          .map((doc) => GasStation.fromFirestore(doc.data(), doc.id))
          .map((s) {
            // Calculate distance to center
            final distanceM = Geolocator.distanceBetween(
              center.latitude, center.longitude,
              s.location.latitude, s.location.longitude,
            );
            return s.copyWith(distanceMiles: distanceM / 1609.34);
          })
          // Filter by radius
          .where((s) => s.distanceMiles * 1609.34 <= radiusMeters)
          .toList();

      // Apply remaining filters
      if (filter != null) {
        if (filter.openNow) {
          stations = stations.where((s) => s.isOpen).toList();
        }
        if (filter.maxDistanceMiles != null) {
          stations = stations.where((s) => s.distanceMiles <= filter.maxDistanceMiles!).toList();
        }
      }

      // Sort by distance (nearest first)
      stations.sort((a, b) => a.distanceMiles.compareTo(b.distanceMiles));
      
      // Limit the results
      if (stations.length > AppConstants.stationPageSize) {
        stations = stations.sublist(0, AppConstants.stationPageSize);
      }

      return Right(stations);
    } on FirebaseException catch (e) {
      return Left(FirestoreFailure(e.message ?? 'Firestore error'));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, GasStation>> getStationById(String id) async {
    try {
      final doc = await _firestore.collection('stations').doc(id).get();
      if (!doc.exists || doc.data() == null) {
        return const Left(NotFoundFailure('Station not found.'));
      }
      return Right(GasStation.fromFirestore(doc.data()!, doc.id));
    } on FirebaseException catch (e) {
      return Left(FirestoreFailure(e.message ?? 'Firestore error'));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  @override
  Future<Either<Failure, void>> reportPrice({
    required String stationId,
    required FuelGrade grade,
    required double price,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('priceHistory')
          .doc(stationId)
          .collection('entries')
          .add({
        'grade': grade.name,
        'price': price,
        'reportedBy': userId,
        'reportedAt': FieldValue.serverTimestamp(),
      });
      return const Right(null);
    } on FirebaseException catch (e) {
      return Left(FirestoreFailure(e.message ?? 'Could not submit price report.'));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }
}
