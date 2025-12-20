import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
import '../../data/api_service.dart';
import '../../data/auth_controller.dart';
import '../../data/models/place.dart';
import '../../data/models/trainer.dart';
import '../../widgets/matrix_button.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';
import 'admin_trainers_screen.dart';

final adminTrainerDetailProvider =
    FutureProvider.autoDispose.family<Trainer, int>((ref, id) {
  return ref.read(apiServiceProvider).fetchTrainerDetail(id);
});

final adminPlacesForTrainerProvider =
    FutureProvider.autoDispose<List<Place>>((ref) {
  return ref.read(apiServiceProvider).fetchPlaces();
});

class AdminTrainerFormScreen extends ConsumerStatefulWidget {
  const AdminTrainerFormScreen({super.key, this.id, this.initial});

  final int? id;
  final Trainer? initial;

  bool get isEditing => id != null && id! > 0;

  @override
  ConsumerState<AdminTrainerFormScreen> createState() => _AdminTrainerFormScreenState();
}

class _AdminTrainerFormScreenState extends ConsumerState<AdminTrainerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _specialties = TextEditingController();
  final _bio = TextEditingController();
  final _price = TextEditingController();
  bool _isActive = true;
  bool _saving = false;
  bool _initialized = false;

  // New scheduling fields
  int? _selectedPlaceId;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _name.dispose();
    _specialties.dispose();
    _bio.dispose();
    _price.dispose();
    super.dispose();
  }

  void _seedFromTrainer(Trainer trainer) {
    _name.text = trainer.name;
    _specialties.text = trainer.specialties;
    _bio.text = trainer.bio ?? '';
    _price.text = trainer.pricePerSession.toString();
    _isActive = trainer.isActive;
    _selectedPlaceId = trainer.place?.id;
    _startDate = trainer.startDate;
    _endDate = trainer.endDate;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    if (!(auth.state.user?.isAdmin ?? false)) {
      return const MatrixScaffold(body: Center(child: Text('Admin access only')));
    }

    final initial = widget.initial;
    final id = widget.id;

    if (widget.isEditing && initial == null) {
      final trainerAsync = ref.watch(adminTrainerDetailProvider(id!));
      return trainerAsync.when(
        loading: () => const MatrixScaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, _) => MatrixScaffold(body: Center(child: Text('Failed to load trainer: $err'))),
        data: (trainer) {
          if (!_initialized) _seedFromTrainer(trainer);
          return MatrixScaffold(body: _buildForm(context, id: id));
        },
      );
    }

    if (initial != null && !_initialized) _seedFromTrainer(initial);
    return MatrixScaffold(body: _buildForm(context, id: id));
  }

  Widget _buildForm(BuildContext context, {int? id}) {
    final placesAsync = ref.watch(adminPlacesForTrainerProvider);
    final dateFormat = DateFormat('yyyy-MM-dd');

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
                onPressed: () => context.go('/admin/trainers'),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.isEditing ? 'Edit trainer' : 'Create trainer',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              MatrixButton(
                label: _saving ? 'Saving' : 'Save',
                onPressed: _saving ? null : () => _save(context, id: id),
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
                  controller: _specialties,
                  decoration: const InputDecoration(labelText: 'Specialties'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Specialties is required'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _bio,
                  decoration: const InputDecoration(labelText: 'Bio (optional)'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          MatrixCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pricing & Status', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _price,
                  decoration: const InputDecoration(labelText: 'Price per session (Rp)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          const SizedBox(height: 12),
          MatrixCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scheduling', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                placesAsync.when(
                  loading: () => const CircularProgressIndicator(),
                  error: (err, _) => Text('Failed to load places: $err'),
                  data: (places) => DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(labelText: 'Assigned Place'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('No place assigned'),
                      ),
                      ...places.map((p) => DropdownMenuItem<int?>(
                            value: p.id,
                            child: Text(
                              '${p.name} - ${p.city}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          )),
                    ],
                    onChanged: (value) => setState(() => _selectedPlaceId = value),
                    value: _selectedPlaceId,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _startDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Start Date'),
                          child: Text(
                            _startDate != null ? dateFormat.format(_startDate!) : 'Not set',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (_startDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _startDate = null),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => _endDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'End Date'),
                          child: Text(
                            _endDate != null ? dateFormat.format(_endDate!) : 'Not set',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (_endDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _endDate = null),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Trainer will be hidden from users after the end date.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MatrixColors.muted,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _parseDouble(String raw, {double fallback = 0}) {
    final v = raw.trim();
    if (v.isEmpty) return fallback;
    return double.tryParse(v) ?? fallback;
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _save(BuildContext context, {int? id}) async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'name': _name.text.trim(),
      'specialties': _specialties.text.trim(),
      'bio': _bio.text.trim(),
      'price_per_session': _parseDouble(_price.text, fallback: 0),
      'is_active': _isActive,
      'place_id': _selectedPlaceId,
      'start_date': _formatDate(_startDate),
      'end_date': _formatDate(_endDate),
    };

    try {
      final api = ref.read(apiServiceProvider);
      if (widget.isEditing) {
        await api.updateTrainer(id!, payload);
      } else {
        await api.createTrainer(payload);
      }
      ref.invalidate(adminTrainersProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEditing ? 'Trainer updated' : 'Trainer created')),
      );
      context.go('/admin/trainers');
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save trainer: $err')),
        );
      }
      if (mounted) setState(() => _saving = false);
    }
  }
}
