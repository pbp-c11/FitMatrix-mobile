import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/api_service.dart';
import '../../data/auth_controller.dart';
import '../../data/models/place.dart';
import '../../data/models/session_slot.dart';
import '../../data/models/trainer.dart';
import '../../widgets/matrix_button.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';
import 'admin_sessions_screen.dart';

final adminAllPlacesProvider = FutureProvider.autoDispose<List<Place>>((ref) async {
  final places = await ref.read(apiServiceProvider).fetchPlaces();
  places.sort((a, b) => a.name.compareTo(b.name));
  return places;
});

final adminAllTrainersProvider = FutureProvider.autoDispose<List<Trainer>>((ref) async {
  final trainers = await ref.read(apiServiceProvider).fetchTrainers();
  trainers.sort((a, b) => a.name.compareTo(b.name));
  return trainers;
});

final adminSessionDetailProvider =
    FutureProvider.autoDispose.family<SessionSlot, int>((ref, id) {
  return ref.read(apiServiceProvider).fetchSessionSlot(id);
});

class AdminSessionFormScreen extends ConsumerStatefulWidget {
  const AdminSessionFormScreen({super.key, this.id, this.initial});

  final int? id;
  final SessionSlot? initial;

  bool get isEditing => id != null && id! > 0;

  @override
  ConsumerState<AdminSessionFormScreen> createState() => _AdminSessionFormScreenState();
}

class _AdminSessionFormScreenState extends ConsumerState<AdminSessionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _capacity = TextEditingController();

  int? _trainerId;
  int? _placeId;
  DateTime _start = DateTime.now().add(const Duration(hours: 1));
  DateTime _end = DateTime.now().add(const Duration(hours: 2));
  bool _isActive = true;
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _capacity.dispose();
    super.dispose();
  }

  void _seedFromSlot(SessionSlot slot) {
    _trainerId = slot.trainer?.id;
    _placeId = slot.place?.id;
    _start = slot.start;
    _end = slot.end;
    _capacity.text = '${slot.capacity}';
    _isActive = slot.isActive;
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
      final slotAsync = ref.watch(adminSessionDetailProvider(id!));
      return slotAsync.when(
        loading: () => const MatrixScaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, _) => MatrixScaffold(body: Center(child: Text('Failed to load slot: $err'))),
        data: (slot) {
          if (!_initialized) _seedFromSlot(slot);
          return _buildWithRefs(context, id: id);
        },
      );
    }

    if (initial != null && !_initialized) _seedFromSlot(initial);
    return _buildWithRefs(context, id: id);
  }

  Widget _buildWithRefs(BuildContext context, {int? id}) {
    final trainersAsync = ref.watch(adminAllTrainersProvider);
    final placesAsync = ref.watch(adminAllPlacesProvider);

    if (trainersAsync.isLoading || placesAsync.isLoading) {
      return const MatrixScaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (trainersAsync.hasError) {
      return MatrixScaffold(body: Center(child: Text('Failed to load trainers: ${trainersAsync.error}')));
    }
    if (placesAsync.hasError) {
      return MatrixScaffold(body: Center(child: Text('Failed to load places: ${placesAsync.error}')));
    }

    final trainers = trainersAsync.value ?? const <Trainer>[];
    final places = placesAsync.value ?? const <Place>[];

    final trainerIds = trainers.map((e) => e.id).toSet();
    final placeIds = places.map((e) => e.id).toSet();

    final trainerValue = (_trainerId != null && trainerIds.contains(_trainerId)) ? _trainerId : null;
    final placeValue = (_placeId != null && placeIds.contains(_placeId)) ? _placeId : null;

    return MatrixScaffold(
      body: Form(
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
                  onPressed: () => context.go('/admin/sessions'),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.isEditing ? 'Edit session slot' : 'Create session slot',
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
                  Text('Assignment', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: trainerValue,
                    decoration: const InputDecoration(labelText: 'Trainer'),
                    items: [
                      for (final trainer in trainers)
                        DropdownMenuItem(
                          value: trainer.id,
                          child: Text(trainer.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _trainerId = value),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: placeValue,
                    decoration: const InputDecoration(labelText: 'Place'),
                    items: [
                      for (final place in places)
                        DropdownMenuItem(
                          value: place.id,
                          child: Text('${place.name} • ${place.city}'),
                        ),
                    ],
                    onChanged: (value) => setState(() => _placeId = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            MatrixCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Schedule', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start'),
                    subtitle: Text(_formatDateTime(_start)),
                    trailing: const Icon(Icons.schedule),
                    onTap: () => _pickDateTime(context, initial: _start, onPicked: (value) {
                      setState(() {
                        _start = value;
                        if (!_end.isAfter(_start)) {
                          _end = _start.add(const Duration(hours: 1));
                        }
                      });
                    }),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('End'),
                    subtitle: Text(_formatDateTime(_end)),
                    trailing: const Icon(Icons.schedule),
                    onTap: () => _pickDateTime(context, initial: _end, onPicked: (value) {
                      setState(() => _end = value);
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            MatrixCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Capacity & status', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _capacity,
                    decoration: const InputDecoration(labelText: 'Capacity'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final cap = int.tryParse((value ?? '').trim()) ?? 0;
                      if (cap < 1) return 'Capacity must be at least 1';
                      return null;
                    },
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
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    return value.toLocal().toString().substring(0, 16);
  }

  Future<void> _pickDateTime(
    BuildContext context, {
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial.toLocal(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial.toLocal()),
    );
    if (time == null) return;
    onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save(BuildContext context, {int? id}) async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    if (_trainerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a trainer')));
      return;
    }
    if (_placeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a place')));
      return;
    }
    if (!_end.isAfter(_start)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('End must be after start')));
      return;
    }

    setState(() => _saving = true);

    final cap = int.tryParse(_capacity.text.trim()) ?? 0;

    final payload = <String, dynamic>{
      'trainer_id': _trainerId,
      'place_id': _placeId,
      'start': _start.toUtc().toIso8601String(),
      'end': _end.toUtc().toIso8601String(),
      'capacity': cap,
      'is_active': _isActive,
    };

    try {
      final api = ref.read(apiServiceProvider);
      if (widget.isEditing) {
        await api.updateSessionSlot(id!, payload);
      } else {
        await api.createSessionSlot(payload);
      }
      ref.invalidate(adminSessionsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEditing ? 'Session slot updated' : 'Session slot created')),
      );
      context.go('/admin/sessions');
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save slot: $err')),
        );
      }
      if (mounted) setState(() => _saving = false);
    }
  }
}
