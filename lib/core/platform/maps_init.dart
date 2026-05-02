// Conditional import: uses web implementation on web, stub everywhere else.
export 'maps_init_stub.dart'
    if (dart.library.html) 'maps_init_web.dart';
