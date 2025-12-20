import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/api_service.dart';
import '../../data/auth_controller.dart';
import '../../data/models/place.dart';
import '../../widgets/matrix_button.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';
import 'admin_places_screen.dart';

final adminPlaceDetailProvider = FutureProvider.autoDispose.family<Place, String>((ref, slug) {
  return ref.read(apiServiceProvider).fetchPlaceDetail(slug);
});

class AdminPlaceFormScreen extends ConsumerStatefulWidget {
  const AdminPlaceFormScreen({super.key, this.slug, this.initial});

  final String? slug;
  final Place? initial;

  bool get isEditing => slug != null && slug!.isNotEmpty;

  @override
  ConsumerState<AdminPlaceFormScreen> createState() => _AdminPlaceFormScreenState();
}

class _AdminPlaceFormScreenState extends ConsumerState<AdminPlaceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _tagline = TextEditingController();
  final _summary = TextEditingController();
  final _tags = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _amenities = TextEditingController();
  final _highlightScore = TextEditingController();
  final _accentColor = TextEditingController();
  final _heroImage = TextEditingController();
  final _gallery = TextEditingController();
  final _price = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();

  String _facilityType = 'GYM';
  bool _isFree = false;
  bool _isActive = true;
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    _summary.dispose();
    _tags.dispose();
    _address.dispose();
    _city.dispose();
    _amenities.dispose();
    _highlightScore.dispose();
    _accentColor.dispose();
    _heroImage.dispose();
    _gallery.dispose();
    _price.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  void _seedFromPlace(Place place) {
    _name.text = place.name;
    _tagline.text = place.tagline ?? '';
    _summary.text = place.summary ?? '';
    _tags.text = place.tags ?? '';
    _address.text = place.address ?? '';
    _city.text = place.city;
    _amenities.text = place.amenities.join(', ');
    _highlightScore.text = '${place.highlightScore}';
    _accentColor.text = place.accentColor ?? '';
    _heroImage.text = place.heroImage ?? '';
    _gallery.text = place.gallery.join(', ');
    _isFree = place.isFree;
    _price.text = place.price?.toString() ?? '';
    _isActive = place.isActive;
    _facilityType = place.facilityType.isNotEmpty ? place.facilityType : 'GYM';
    _latitude.text = place.latitude?.toString() ?? '';
    _longitude.text = place.longitude?.toString() ?? '';
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    if (!(auth.state.user?.isAdmin ?? false)) {
      return const MatrixScaffold(body: Center(child: Text('Admin access only')));
    }

    final initial = widget.initial;
    final slug = widget.slug;

    if (widget.isEditing && initial == null) {
      final placeAsync = ref.watch(adminPlaceDetailProvider(slug!));
      return placeAsync.when(
        loading: () => const MatrixScaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, _) => MatrixScaffold(body: Center(child: Text('Failed to load place: $err'))),
        data: (place) {
          if (!_initialized) _seedFromPlace(place);
          return MatrixScaffold(body: _buildForm(context, slug: slug));
        },
      );
    }

    if (initial != null && !_initialized) _seedFromPlace(initial);
    return MatrixScaffold(body: _buildForm(context, slug: slug));
  }

  Widget _buildForm(BuildContext context, {String? slug}) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.only(top: 14, bottom: 20),
        children: [
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                color: MatrixColors.ink,
                onPressed: () => context.go('/admin/places'),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.isEditing ? 'Edit place' : 'Create place',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              MatrixButton(
                label: _saving ? 'Saving' : 'Save',
                onPressed: _saving ? null : () => _save(context, slug: slug),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MatrixCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Basics', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _address,
                  decoration: const InputDecoration(labelText: 'Address'),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Address is required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _city,
                  decoration: const InputDecoration(labelText: 'City'),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'City is required' : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _facilityType,
                  decoration: const InputDecoration(labelText: 'Facility type'),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'GYM', child: Text('Gym')),
                    DropdownMenuItem(value: 'STUDIO', child: Text('Studio')),
                    DropdownMenuItem(value: 'SWIM', child: Text('Swimming Pool')),
                    DropdownMenuItem(value: 'OUTDOOR', child: Text('Outdoor')),
                    DropdownMenuItem(value: 'WELLNESS', child: Text('Wellness')),
                    DropdownMenuItem(value: 'COURT', child: Text('Court')),
                  ],
                  onChanged: (value) => setState(() => _facilityType = value ?? 'GYM'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _tagline,
                  decoration: const InputDecoration(labelText: 'Tagline'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _summary,
                  decoration: const InputDecoration(labelText: 'Summary'),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _tags,
                  decoration: const InputDecoration(labelText: 'Tags (comma-separated)'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          MatrixCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Details', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _amenities,
                  decoration: const InputDecoration(labelText: 'Amenities (comma-separated)'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _heroImage,
                  decoration: const InputDecoration(labelText: 'Hero image URL/path'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _gallery,
                  decoration: const InputDecoration(labelText: 'Gallery URLs/paths (comma-separated)'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _accentColor,
                  decoration: const InputDecoration(labelText: 'Accent color (e.g. #03B863)'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _highlightScore,
                  decoration: const InputDecoration(labelText: 'Highlight score'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitude,
                        decoration: const InputDecoration(labelText: 'Latitude (optional)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _longitude,
                        decoration: const InputDecoration(labelText: 'Longitude (optional)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          MatrixCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pricing & status', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: _isFree,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Free access'),
                  onChanged: (value) => setState(() => _isFree = value),
                ),
                TextFormField(
                  controller: _price,
                  decoration: const InputDecoration(labelText: 'Price (Rp)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  enabled: !_isFree,
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: _isActive,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _splitList(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  double? _parseDoubleOrNull(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    return double.tryParse(v);
  }

  int _parseIntOrDefault(String raw, int fallback) {
    final v = raw.trim();
    if (v.isEmpty) return fallback;
    return int.tryParse(v) ?? fallback;
  }

  Future<void> _save(BuildContext context, {String? slug}) async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'tagline': _tagline.text.trim(),
      'summary': _summary.text.trim(),
      'tags': _tags.text.trim(),
      'address': _address.text.trim(),
      'city': _city.text.trim(),
      'facility_type': _facilityType,
      'amenities': _splitList(_amenities.text),
      'highlight_score': _parseIntOrDefault(_highlightScore.text, 0),
      'accent_color': _accentColor.text.trim(),
      'hero_image': _heroImage.text.trim(),
      'gallery': _splitList(_gallery.text),
      'is_free': _isFree,
      'price': _isFree ? null : _parseDoubleOrNull(_price.text),
      'is_active': _isActive,
      'latitude': _parseDoubleOrNull(_latitude.text),
      'longitude': _parseDoubleOrNull(_longitude.text),
    };

    try {
      final api = ref.read(apiServiceProvider);
      if (widget.isEditing) {
        await api.updatePlace(slug!, payload);
      } else {
        await api.createPlace(payload);
      }
      ref.invalidate(adminPlacesProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEditing ? 'Place updated' : 'Place created')),
      );
      context.go('/admin/places');
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save place: $err')),
        );
      }
      if (mounted) setState(() => _saving = false);
    }
  }
}
