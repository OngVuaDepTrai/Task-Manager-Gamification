import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/app_colors.dart';
import '../../services/location_service.dart';

// Kết quả chọn vị trí trả về cho form công việc
class PickedLocation {
  final String name;
  final double lat;
  final double lng;
  final int radius;

  PickedLocation({
    required this.name,
    required this.lat,
    required this.lng,
    required this.radius,
  });
}

// Màn chọn vị trí nhắc nhở trên Google Maps:
// - Chạm vào bản đồ để chọn điểm (hoặc dùng vị trí hiện tại)
// - Chọn bán kính nhắc (vòng tròn hiển thị trên bản đồ)
// - Đặt tên địa điểm
class LocationPickerView extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialName;
  final int initialRadius;

  const LocationPickerView({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialName,
    this.initialRadius = 300,
  });

  @override
  State<LocationPickerView> createState() => _LocationPickerViewState();
}

class _LocationPickerViewState extends State<LocationPickerView> {
  // Mặc định: trung tâm TP.HCM
  static const LatLng _defaultCenter = LatLng(10.7769, 106.7009);
  static const List<int> _radiusOptions = [100, 200, 300, 500, 1000];

  GoogleMapController? _mapController;
  final TextEditingController _nameController = TextEditingController();

  LatLng? _picked;
  late int _radius;
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
    _radius = widget.initialRadius;
    if (widget.initialLat != null && widget.initialLng != null) {
      _picked = LatLng(widget.initialLat!, widget.initialLng!);
      _nameController.text = widget.initialName ?? '';
    }
    _initLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final error = await LocationService().ensurePermission();
    if (!mounted) return;
    setState(() => _hasLocationPermission = error == null);
    if (error != null) {
      _showMsg(error);
      return;
    }
    // Chưa chọn điểm nào -> đưa bản đồ về vị trí hiện tại
    if (_picked == null) {
      final pos = await LocationService().getCurrentPosition();
      if (pos != null && mounted) {
        _moveCamera(LatLng(pos.latitude, pos.longitude), zoom: 16);
      }
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _moveCamera(LatLng target, {double zoom = 16}) {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, zoom));
  }

  // Chọn 1 điểm: đặt marker + vòng tròn bán kính
  void _selectPoint(LatLng point) {
    setState(() => _picked = point);
  }

  Future<void> _useCurrentLocation() async {
    final pos = await LocationService().getCurrentPosition();
    if (!mounted) return;
    if (pos == null) {
      _showMsg('Không lấy được vị trí hiện tại.');
      return;
    }
    final point = LatLng(pos.latitude, pos.longitude);
    _moveCamera(point, zoom: 17);
    _selectPoint(point);
  }

  void _confirm() {
    final point = _picked;
    if (point == null) {
      _showMsg('Hãy chạm vào bản đồ để chọn địa điểm.');
      return;
    }
    final name = _nameController.text.trim();
    Navigator.pop(
      context,
      PickedLocation(
        name: name.isEmpty
            ? '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}'
            : name,
        lat: point.latitude,
        lng: point.longitude,
        radius: _radius,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final point = _picked;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Chọn vị trí nhắc nhở',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Bản đồ
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: point ?? _defaultCenter,
                    zoom: point != null ? 16 : 13,
                  ),
                  onMapCreated: (c) => _mapController = c,
                  onTap: (p) => _selectPoint(p),
                  myLocationEnabled: _hasLocationPermission,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  markers: {
                    if (point != null)
                      Marker(
                        markerId: const MarkerId('picked'),
                        position: point,
                      ),
                  },
                  circles: {
                    if (point != null)
                      Circle(
                        circleId: const CircleId('radius'),
                        center: point,
                        radius: _radius.toDouble(),
                        fillColor: AppColors.primary.withAlpha(50),
                        strokeColor: AppColors.primary,
                        strokeWidth: 2,
                      ),
                  },
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'my_location',
                    backgroundColor: AppColors.card,
                    onPressed: _useCurrentLocation,
                    child: const Icon(
                      Icons.my_location,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (point == null)
                  Positioned(
                    left: 12,
                    right: 70,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.card.withAlpha(230),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Chạm vào bản đồ để chọn địa điểm',
                        style: TextStyle(color: AppColors.textMain),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Tên địa điểm + bán kính + xác nhận
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            color: AppColors.card,
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.textMain),
                    decoration: const InputDecoration(
                      labelText: 'Tên địa điểm',
                      labelStyle: TextStyle(color: AppColors.textSub),
                      hintText: 'VD: Sân cầu lông, Cửa hàng thể thao...',
                      hintStyle: TextStyle(color: AppColors.textSub),
                      prefixIcon: Icon(
                        Icons.place_outlined,
                        color: AppColors.textSub,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nhắc khi đến gần trong bán kính:',
                    style: TextStyle(color: AppColors.textSub),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _radiusOptions.map((r) {
                      final selected = r == _radius;
                      return ChoiceChip(
                        label: Text(r >= 1000 ? '${r ~/ 1000} km' : '$r m'),
                        selected: selected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selected ? Colors.black : AppColors.textMain,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) => setState(() => _radius = r),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _confirm,
                      icon: const Icon(Icons.check, color: Colors.black),
                      label: const Text(
                        'DÙNG VỊ TRÍ NÀY',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
