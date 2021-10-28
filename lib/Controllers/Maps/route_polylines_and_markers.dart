import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_config/flutter_config.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:get/get.dart';
import 'package:get/utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:nowly/Controllers/controller_exporter.dart';
import 'package:nowly/Models/models_exporter.dart';
import 'package:nowly/Services/Net/net.dart';
import 'package:nowly/Utils/logger.dart';
import 'package:sizer/sizer.dart';

extension RoutePolyLinesAndMarkers on MapController {
  Future<void> addLocationDetailsToMap(
      List<TrainerSessionController> controllers) async {
    //add session location details
    //clear existing markers of list
    clearExistingDestinationMarkers();
    //add markers to map
    final allMarkers = <Marker>[];
    for (var controller in controllers) {
      Marker? marker = await getDestinationMarkers(controller);
      if (marker != null) allMarkers.add(marker);
    }
    destinationMarkers.addAll(allMarkers);
  }

  void clearExistingDestinationMarkers() {
    destinationMarkers.clear();
  }

  Future<Marker?> getDestinationMarkers(
      TrainerSessionController trainerSessionController,
      {VoidCallback? tapEvent}) async {
    ///// get lati ang latitude
    final LocationDetailsModel? locationDetails =
        trainerSessionController.trainerSession.locationDetailsModel;
    if (locationDetails == null) {
      clearPolyLinePath();
      return null;
    }
    final location =
        LatLng(locationDetails.latitude, locationDetails.longitude);

    return Marker(
        markerId: MarkerId(locationDetails.id),
        infoWindow: InfoWindow(title: locationDetails.locationDescription),
        onTap: () {
          trainerSessionController.openSessionDetailsBottomSheet();
          addOriginMarkers(location, tsController: trainerSessionController);
        },
        position: location,
        icon: BitmapDescriptor.fromBytes(await getBytesFromAsset(
            'assets/images/map/session_location.png', 85.sp.toInt())));
  }

  //add my location marker and draw poly line to destination
  Future<void> addOriginMarkers(LatLng destinationCordinates,
      {VoidCallback? tapEvent, TrainerSessionController? tsController}) async {
    LocationData? myLocation = getOriginLocation;

    if (myLocation == null) {
      await getMyLocation();
      myLocation = getOriginLocation;
    }

    if (myLocation != null) {
      originMarker.value = Marker(
          markerId: const MarkerId('Me'),
          infoWindow: const InfoWindow(title: 'Me'),
          position: LatLng(myLocation.latitude!, myLocation.longitude!),
          onTap: tapEvent,
          icon: BitmapDescriptor.fromBytes(await getBytesFromAsset(
              'assets/images/map/my_location.png', 40.sp.toInt())));
    }

    if (myLocation != null) {
      await getDirectionDetails(
          destination: destinationCordinates,
          origin: LatLng(myLocation.latitude!, myLocation.longitude!),
          onComplete: (direction) {
            if (direction == null || direction.routes.isEmpty) return;
            getPolyLinePoints(direction);
            if (tsController == null) return;
            tsController.changeDistanceAndDuraion(direction.routes[0].legs[0]);
          });
    }
    focusMe();
  }

  //////
  Future<void> getDirectionDetails(
      {required LatLng origin,
      required LatLng destination,
      required Function(Direction? direction) onComplete}) async {
    final uri = Uri(
        scheme: 'https',
        host: 'maps.googleapis.com',
        path: '/maps/api/directions/json',
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'key': GetPlatform.isIOS ? FlutterConfig.get('IOSMAPSKEY') : FlutterConfig.get('ANDROIDMAPSKEY'),
          'mode': describeEnum(selectedTravelMode)
        });

    final net = Net.init('', uri: uri);
    net.onComplete = (http.Response response) {
      direction = directionFromJson(response.body);
      onComplete(direction);
    };
    net.onError = (Exception e) {
      AppLogger.e(e);
    };
    await net.execute();
  }

  //////
  void getPolyLinePoints(Direction direction) {
    final PolylinePoints _polyLine = PolylinePoints();
    final List<PointLatLng> _decodedPolyLines =
        _polyLine.decodePolyline(direction.routes[0].overviewPolyline.points);

    final points =
        _decodedPolyLines.map((e) => LatLng(e.latitude, e.longitude)).toList();

    polylinesPoints.value = points;
  }

  void clearPolyLinePath() {
    polylinesPoints.clear();
  }
}
