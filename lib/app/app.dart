import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import '../features/map/data/repositories/station_repository.dart';
import '../features/map/presentation/bloc/map_bloc.dart';

final getIt = GetIt.instance;

class GasGojoApp extends StatelessWidget {
  const GasGojoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => MapBloc(
            stationRepository: getIt<StationRepository>(),
          ),
        ),
        // Additional BLoCs/Cubits added here as features grow:
        // BlocProvider(create: (_) => FavoritesCubit(getIt<FavoritesRepository>())),
        // BlocProvider(create: (_) => AlertsCubit(getIt<AlertsRepository>())),
        // BlocProvider(create: (_) => AuthCubit(getIt<AuthRepository>())),
      ],
      child: MaterialApp.router(
        title: 'GasGojo',
        theme: AppTheme.light,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          // Enforce accessibility text scale limits
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 2.0),
              ),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
