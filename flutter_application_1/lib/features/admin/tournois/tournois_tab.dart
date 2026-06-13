import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../data/services/services.dart';
import '../../../domain/domain.dart';

// ── Color palette (navy + gold — matches Excel example) ────────────────────
const _navy    = Color(0xFF1B3168);
const _gold    = Color(0xFFFFB800);
const _bg      = Color(0xFFF0F4FA);
const _cardBg  = Color(0xFFFFFFFF);
const _border  = Color(0xFFD0D8E8);
const _textDk  = Color(0xFF0A1128);

// ───────────────────────────────────────────────────────────────────────────
class TournoisTab extends StatefulWidget {
  const TournoisTab({super.key});
  @override
  State<TournoisTab> createState() => _TournoisTabState();
}

class _TournoisTabState extends State<TournoisTab> {
  final TournamentsServiceMock _svc   = TournamentsServiceMock();
  final PlayersServiceMock     _plSvc = PlayersServiceMock();
  final TeamsServiceMock       _tmSvc = TeamsServiceMock();

  static const List<String> _complexes = [
    'Vamos Sport', 'La Casa del Padel', 'Le Padel Sfax', 'Just Padel',
  ];

  List<Tournament> _tournaments = [];
  List<AppUser>    _players     = [];
  List<Team>       _teams       = [];
  bool  _loading       = true;
  bool  _actionLoading = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await Future.wait([
        _svc.getAllTournaments(),
        _plSvc.getAllPlayers(),
        _tmSvc.getAllTeams(),
      ]);
      if (!mounted) return;
      setState(() {
        _tournaments = res[0] as List<Tournament>;
        _players     = (res[1] as List<AppUser>)
            .where((p) => p.status == UserStatus.actif).toList();
        _teams       = res[2] as List<Team>;
        _loading     = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _runAction(Future<void> Function() fn, String msg) async {
    setState(() => _actionLoading = true);
    try {
      await fn();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  // ── Name helpers ──────────────────────────────────────────────────────────
  String _participantName(Tournament t, int id) {
    if (id <= 0) return 'À définir';
    if (t.isTeamMode) {
      return _teams.firstWhere((e) => e.id == id,
          orElse: () => Team(id: id, nom: 'Équipe #$id', playerIds: [])).nom;
    }
    return _players.firstWhere((p) => p.id == id,
        orElse: () => AppUser(
              id: id, nom: 'Joueur #$id',
              email: '', password: '', niveau: 0, role: UserRole.joueur,
              status: UserStatus.actif,
            )).nom;
  }

  // ── Bracket data helpers ──────────────────────────────────────────────────
  int _roundOrder(TournamentRound r) {
    switch (r) {
      case TournamentRound.seizieme: return 0;
      case TournamentRound.huitieme: return 1;
      case TournamentRound.quart:    return 2;
      case TournamentRound.demi:     return 3;
      case TournamentRound.finale:   return 4;
    }
  }

  int _firstRoundOrder(int size) {
    if (size >= 32) return 0;
    if (size >= 16) return 1;
    if (size >= 8)  return 2;
    return 3;
  }

  List<List<TournamentMatch?>> _buildRounds(Tournament t) {
    final first  = _firstRoundOrder(t.maxParticipants);
    final last   = _roundOrder(TournamentRound.finale);
    final rounds = <List<TournamentMatch?>>[];

    for (var ro = first; ro <= last; ro++) {
      final matchesInRound = t.matches
          .where((m) => _roundOrder(m.round) == ro)
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      final expectedCount = 1 << (last - ro);
      final padded = List<TournamentMatch?>.generate(
        expectedCount,
        (i) => i < matchesInRound.length ? matchesInRound[i] : null,
      );
      rounds.add(padded);
    }
    return rounds;
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  Future<void> _showCreateDialog() async {
    final formKey = GlobalKey<FormState>();
    String nom = '';
    String type = 'joueurs';          // 'joueurs' | 'equipes'
    int maxP = 8;
    String complexe = _complexes.first;
    int terrain = 1;
    DateTime date = DateTime.now().add(const Duration(days: 7));
    final selectedIds = <int>{};
    String search = '';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        final playerOptions = _players
            .where((p) => p.nom.toLowerCase().contains(search.toLowerCase()))
            .toList();
        final teamOptions = _teams
            .where((t) => t.nom.toLowerCase().contains(search.toLowerCase()))
            .toList();
        final options = type == 'joueurs'
            ? playerOptions.map((p) => (id: p.id, label: '${p.nom} (niv.${p.niveau})'))
            : teamOptions.map((t) => (id: t.id, label: t.nom));

        return AlertDialog(
          backgroundColor: _cardBg,
          title: Row(children: [
            Container(width: 4, height: 24, color: _gold, margin: const EdgeInsets.only(right: 10)),
            const Text('Créer un tournoi', style: TextStyle(color: _textDk, fontWeight: FontWeight.w800)),
          ]),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field(label: 'Nom du tournoi', onChanged: (v) => nom = v,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null),
                  const SizedBox(height: 12),
                  // Type choice
                  _label('Type de participants'),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(child: _typeBtn('joueurs', 'Joueurs', Icons.person, type, () => setS(() { type = 'joueurs'; selectedIds.clear(); }))),
                    const SizedBox(width: 10),
                    Expanded(child: _typeBtn('equipes', 'Équipes', Icons.groups, type, () => setS(() { type = 'equipes'; selectedIds.clear(); }))),
                  ]),
                  const SizedBox(height: 12),
                  _dropdownInt('Format', [4, 8, 16, 32], maxP, (v) => setS(() { maxP = v!; selectedIds.clear(); })),
                  const SizedBox(height: 12),
                  _dropdownStr('Complexe sportif', _complexes, complexe, (v) => setS(() => complexe = v!)),
                  const SizedBox(height: 12),
                  _dropdownInt('Terrain', List.generate(6, (i) => i + 1), terrain, (v) => setS(() => terrain = v!),
                    labels: List.generate(6, (i) => 'Terrain ${i + 1}')),
                  const SizedBox(height: 12),
                  _label('Date du tournoi'),
                  const SizedBox(height: 6),
                  _dateBanner(date, () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setS(() => date = picked);
                  }),
                  const SizedBox(height: 12),
                  _label('Rechercher ${type == "joueurs" ? "joueurs" : "équipes"}'),
                  const SizedBox(height: 6),
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'Nom...', prefixIcon: Icon(Icons.search),
                      isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    onChanged: (v) => setS(() => search = v),
                  ),
                  const SizedBox(height: 8),
                  Text('Sélectionner $maxP participants (${selectedIds.length}/$maxP)',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: _navy)),
                  const SizedBox(height: 6),
                  ...options.map((opt) => CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: _navy,
                    title: Text(opt.label, style: const TextStyle(color: _textDk)),
                    value: selectedIds.contains(opt.id),
                    onChanged: (v) => setS(() {
                      if (v == true) {
                        if (selectedIds.length < maxP) selectedIds.add(opt.id);
                      } else {
                        selectedIds.remove(opt.id);
                      }
                    }),
                  )),
                ],
              )),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _navy, foregroundColor: Colors.white),
              onPressed: _actionLoading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                if (selectedIds.length != maxP) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text('Sélectionnez exactement $maxP participants'),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                final nav = Navigator.of(ctx);
                nav.pop();
                await _runAction(
                  () => _svc.createTournament(
                    nom: nom.trim(), date: date, type: type,
                    participantIds: selectedIds.toList(),
                    maxParticipants: maxP, complexeSportif: complexe, terrainNumero: terrain,
                  ),
                  'Tournoi créé avec succès',
                );
              },
              child: const Text('Créer'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _showMatchParamsDialog(Tournament t, TournamentMatch match) async {
    String complexe = match.complexeSportif;
    int terrain = match.terrainNumero;
    TimeOfDay time = _parseTime(match.heureDebut);
    DateTime date = match.dateMatch ?? t.date;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        backgroundColor: _cardBg,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Paramètres du match', style: TextStyle(color: _textDk, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            '${_participantName(t, match.joueur1)} vs ${_participantName(t, match.joueur2)}',
            style: const TextStyle(fontSize: 13, color: _navy, fontWeight: FontWeight.w600),
          ),
        ]),
        content: SizedBox(
          width: 360,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _dropdownStr('Complexe sportif', _complexes, complexe, (v) => setS(() => complexe = v!)),
            const SizedBox(height: 12),
            _dropdownInt('Terrain', List.generate(4, (i) => i + 1), terrain,
              (v) => setS(() => terrain = v!),
              labels: List.generate(4, (i) => 'Terrain ${i + 1}')),
            const SizedBox(height: 12),
            // Date picker
            _label('Date du match'),
            const SizedBox(height: 6),
            _dateBanner(date, () async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: date,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 730)),
              );
              if (picked != null) setS(() => date = picked);
            }),
            const SizedBox(height: 12),
            // Time picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule, color: _navy),
              title: Text('Heure: ${_fmtTime(time)}',
                style: const TextStyle(fontWeight: FontWeight.w700, color: _textDk)),
              trailing: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: _navy),
                onPressed: () async {
                  final picked = await showTimePicker(context: ctx, initialTime: time);
                  if (picked != null) setS(() => time = picked);
                },
                child: const Text('Changer'),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _navy, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Enregistrer'),
          ),
        ],
      )),
    );

    if (confirmed != true) return;
    await _runAction(
      () => _svc.updateMatchSchedule(
        tournamentId: t.id, matchId: match.id,
        complexeSportif: complexe, terrainNumero: terrain,
        heureDebut: _fmtTime(time), matchDate: date,
      ),
      'Planning mis à jour',
    );
  }

  Future<void> _showWinnerDialog(Tournament t, TournamentMatch match) async {
    if (match.joueur1 <= 0 || match.joueur2 <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Les deux participants doivent être définis'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final p1Name = _participantName(t, match.joueur1);
    final p2Name = _participantName(t, match.joueur2);

    // Int state for set 1 & 2 (picker 0-7); text for set 3 (no max)
    int s1j1 = int.tryParse(match.scoreSet1?.split('-').firstOrNull ?? '') ?? 0;
    int s1j2 = int.tryParse(match.scoreSet1?.split('-').lastOrNull  ?? '') ?? 0;
    int s2j1 = int.tryParse(match.scoreSet2?.split('-').firstOrNull ?? '') ?? 0;
    int s2j2 = int.tryParse(match.scoreSet2?.split('-').lastOrNull  ?? '') ?? 0;
    final s3j1Ctrl = TextEditingController(text: match.scoreSet3?.split('-').firstOrNull ?? '');
    final s3j2Ctrl = TextEditingController(text: match.scoreSet3?.split('-').lastOrNull  ?? '');

    // Determines winner from current scores (null if still undecided)
    int? autoWinner(int v1j1, int v1j2, int v2j1, int v2j2) {
      int wins1 = 0, wins2 = 0;
      if (v1j1 > v1j2) wins1++; else if (v1j2 > v1j1) wins2++;
      if (v2j1 > v2j2) wins1++; else if (v2j2 > v2j1) wins2++;
      if (wins1 == 2) return match.joueur1;
      if (wins2 == 2) return match.joueur2;
      // Tiebreak set 3
      final v3j1 = int.tryParse(s3j1Ctrl.text) ?? -1;
      final v3j2 = int.tryParse(s3j2Ctrl.text) ?? -1;
      if (v3j1 < 0 || v3j2 < 0) return null;
      // Must reach ≥ 10 with difference ≥ 2
      final maxS = v3j1 > v3j2 ? v3j1 : v3j2;
      final diff = (v3j1 - v3j2).abs();
      if (maxS < 10 || diff < 2) return null;
      return v3j1 > v3j2 ? match.joueur1 : match.joueur2;
    }

    bool needsSet3(int v1j1, int v1j2, int v2j1, int v2j2) {
      int w1 = 0, w2 = 0;
      if (v1j1 > v1j2) w1++; else if (v1j2 > v1j1) w2++;
      if (v2j1 > v2j2) w1++; else if (v2j2 > v2j1) w2++;
      return w1 == 1 && w2 == 1;
    }

    final result = await showDialog<({int winnerId, String s1, String s2, String? s3})>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        final needs3 = needsSet3(s1j1, s1j2, s2j1, s2j2);
        final winner = autoWinner(s1j1, s1j2, s2j1, s2j2);

        void rebuild() => setS(() {});

        return AlertDialog(
          backgroundColor: _cardBg,
          title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Saisir les scores', style: TextStyle(color: _textDk, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('$p1Name  vs  $p2Name',
                style: const TextStyle(fontSize: 12, color: _navy, fontWeight: FontWeight.w600)),
          ]),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Column headers
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    const SizedBox(width: 70),
                    Expanded(child: Text(p1Name, textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: _navy),
                        overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p2Name, textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: _navy),
                        overflow: TextOverflow.ellipsis)),
                  ]),
                ),
                // Manche 1 picker (0-7)
                _pickerRow('Manche 1', s1j1, s1j2, 7,
                  (v) => setS(() => s1j1 = v),
                  (v) => setS(() => s1j2 = v),
                ),
                const SizedBox(height: 10),
                // Manche 2 picker (0-7)
                _pickerRow('Manche 2', s2j1, s2j2, 7,
                  (v) => setS(() => s2j1 = v),
                  (v) => setS(() => s2j2 = v),
                ),
                // Manche 3 text input (no max) — only if 1-1
                if (needs3) ...[
                  const SizedBox(height: 10),
                  _scoreRow('Manche 3', s3j1Ctrl, s3j2Ctrl, rebuild),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Super tie-break · premier à 10 · différence ≥ 2 (ex: 10-8, 11-9, 12-10…)',
                      style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.4)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                // Auto winner banner
                if (winner != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _gold.withValues(alpha: 0.35)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.emoji_events, color: _gold, size: 16),
                      const SizedBox(width: 6),
                      Flexible(child: Text('Vainqueur : ${_participantName(t, winner)}',
                          style: const TextStyle(color: _gold, fontWeight: FontWeight.w800, fontSize: 13))),
                    ]),
                  ),
                ],
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: _textDk),
              onPressed: winner == null ? null : () {
                Navigator.pop(ctx, (
                  winnerId: winner,
                  s1: '$s1j1-$s1j2',
                  s2: '$s2j1-$s2j2',
                  s3: needs3 ? '${s3j1Ctrl.text}-${s3j2Ctrl.text}' : null,
                ));
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      }),
    );

    if (result == null) return;
    await _runAction(
      () => _svc.setMatchWinner(
        tournamentId: t.id,
        matchId: match.id,
        winnerId: result.winnerId,
        scoreSet1: result.s1,
        scoreSet2: result.s2,
        scoreSet3: result.s3,
      ),
      'Résultat enregistré — ${_participantName(t, result.winnerId)} avance au tour suivant',
    );
  }

  // Number picker row (0..max) for sets 1 & 2
  Widget _pickerRow(
    String label,
    int valJ1, int valJ2, int max,
    ValueChanged<int> onJ1,
    ValueChanged<int> onJ2,
  ) {
    Widget numBtn(int n, int current, ValueChanged<int> onTap) {
      final sel = n == current;
      return GestureDetector(
        onTap: () => onTap(n),
        child: Container(
          width: 28, height: 28,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: sel ? _gold : _navy.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: sel ? _gold : _border),
          ),
          child: Center(child: Text('$n',
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w800,
              color: sel ? _textDk : _navy,
            ))),
        ),
      );
    }

    final nums = List.generate(max + 1, (i) => i);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textDk)),
      const SizedBox(height: 6),
      Row(children: [
        const SizedBox(width: 70),
        Expanded(child: Wrap(spacing: 0, children: nums.map((n) => numBtn(n, valJ1, onJ1)).toList())),
        const SizedBox(width: 8),
        Expanded(child: Wrap(spacing: 0, children: nums.map((n) => numBtn(n, valJ2, onJ2)).toList())),
      ]),
    ]);
  }

  // Text field row for set 3 only (no max)
  Widget _scoreRow(
    String label,
    TextEditingController ctrlJ1,
    TextEditingController ctrlJ2,
    VoidCallback onChanged,
  ) {
    return Row(children: [
      SizedBox(
        width: 70,
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textDk)),
      ),
      Expanded(
        child: TextFormField(
          controller: ctrlJ1,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          decoration: const InputDecoration(
            hintText: '0', hintStyle: TextStyle(fontSize: 11),
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            isDense: true,
          ),
          validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null) ? 'Nombre' : null,
          onChanged: (_) => onChanged(),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text('-', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.5))),
      ),
      Expanded(
        child: TextFormField(
          controller: ctrlJ2,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          decoration: const InputDecoration(
            hintText: '0', hintStyle: TextStyle(fontSize: 11),
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            isDense: true,
          ),
          validator: (v) => (v == null || v.isEmpty || int.tryParse(v) == null) ? 'Nombre' : null,
          onChanged: (_) => onChanged(),
        ),
      ),
    ]);
  }


  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _navy));

    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: _navy, foregroundColor: Colors.white),
          onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Réessayer'),
        ),
      ]));
    }

    return Container(
      color: _bg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Header bar ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Icon(Icons.emoji_events, color: _gold, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Tournois', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                Text('${_tournaments.length} tournoi(s)', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
              ])),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: _textDk,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                onPressed: _actionLoading ? null : _showCreateDialog,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Créer', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Tournament list ──────────────────────────────────────────────
          if (_tournaments.isEmpty)
            _emptyState()
          else
            ..._tournaments.map((t) => _buildTournamentCard(t)),
        ],
      ),
    );
  }

  // ── Tournament card ───────────────────────────────────────────────────────

  Widget _buildTournamentCard(Tournament t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Card header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _gold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.emoji_events, color: _gold, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.nom, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
              const SizedBox(height: 3),
              Wrap(spacing: 8, children: [
                _chip(t.isTeamMode ? 'Équipes' : 'Joueurs', t.isTeamMode ? Icons.groups : Icons.person),
                _chip('${t.maxParticipants} participants', Icons.people_outline),
                _chip(_fmtDate(t.date), Icons.calendar_today_outlined),
              ]),
            ])),
          ]),
        ),

        // Bracket
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildBracket(t),
        ),
      ]),
    );
  }

  // ── BRACKET ───────────────────────────────────────────────────────────────

  Widget _buildBracket(Tournament t) {
    final rounds = _buildRounds(t);
    if (rounds.isEmpty) return const Text('Aucun match à afficher.');

    // Split first round into left half and right half
    final firstRound = rounds.first;
    final matchCount = firstRound.length; // 4 for 8p, 8 for 16p
    final leftMatches  = firstRound.sublist(0, matchCount ~/ 2);
    final rightMatches = firstRound.sublist(matchCount ~/ 2);

    // Natural canvas size
    const pBoxW  = _BracketCanvas.pBoxW;
    const rBoxW  = _BracketCanvas.rBoxW;
    const colGap = _BracketCanvas.colGap;
    const centerW = _BracketCanvas.centerW;
    const pBoxH  = _BracketCanvas.pBoxH;
    const pGap   = _BracketCanvas.pGap;
    const mGap   = _BracketCanvas.mGap;

    final roundCount = rounds.length;
    final leftCount  = rounds.first.length ~/ 2;
    final halfWidth  = pBoxW + colGap + (roundCount - 1) * (rBoxW + colGap);
    final naturalW   = halfWidth * 2 + centerW;
    final matchH     = 2 * pBoxH + pGap;
    final naturalH   = math.max(320.0, 40 + leftCount * matchH + math.max(0, leftCount - 1) * mGap + 180);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Legend
      Wrap(spacing: 12, runSpacing: 6, children: [
        _legendDot(_gold, 'Vainqueur'),
        _legendDot(_navy, 'En cours'),
        _legendDot(_border, 'À définir'),
      ]),
      const SizedBox(height: 16),

      // Bracket canvas — scales down to fit screen, pinch-to-zoom to inspect details
      LayoutBuilder(builder: (ctx, cst) {
        final availW = cst.maxWidth > 0 ? cst.maxWidth : naturalW;
        final scale  = math.min(1.0, availW / naturalW);
        final scaledH = naturalH * scale;

        return SizedBox(
          width: availW,
          height: scaledH,
          child: InteractiveViewer(
            constrained: false,
            minScale: scale * 0.5,
            maxScale: 2.5,
            boundaryMargin: const EdgeInsets.all(32),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: naturalW,
                height: naturalH,
                child: _BracketCanvas(
                  tournament: t,
                  rounds: rounds,
                  leftMatches: leftMatches,
                  rightMatches: rightMatches,
                  getName: (id) => _participantName(t, id),
                  onMatchTap: (m) => _showMatchParamsDialog(t, m),
                  onWinnerTap: (m) => _showWinnerDialog(t, m),
                  actionLoading: _actionLoading,
                ),
              ),
            ),
          ),
        );
      }),
    ]);
  }

  // ── Small helpers ─────────────────────────────────────────────────────────

  Widget _chip(String label, IconData icon) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: Colors.white60),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
  ]);

  Widget _legendDot(Color c, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(color: _textDk, fontSize: 12)),
  ]);

  Widget _emptyState() => Center(child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Column(children: [
      Icon(Icons.emoji_events_outlined, size: 64, color: _navy.withValues(alpha: 0.3)),
      const SizedBox(height: 12),
      const Text('Aucun tournoi', style: TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 6),
      const Text('Créez votre premier tournoi avec le bouton ci-dessus.', textAlign: TextAlign.center,
        style: TextStyle(color: Colors.black54)),
    ]),
  ));



  // ── Form helpers ──────────────────────────────────────────────────────────

  Widget _label(String text) => Text(text,
    style: const TextStyle(fontWeight: FontWeight.w700, color: _navy, fontSize: 13));

  Widget _field({required String label, required void Function(String) onChanged, String? Function(String?)? validator}) {
    return TextFormField(
      decoration: InputDecoration(labelText: label, isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12)),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _typeBtn(String value, String label, IconData icon, String current, VoidCallback onTap) {
    final sel = current == value;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: sel ? _navy : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sel ? _navy : _border, width: sel ? 2 : 1),
        ),
        child: Column(children: [
          Icon(icon, color: sel ? _gold : Colors.grey, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: sel ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _dropdownStr(String label, List<String> items, String val, ValueChanged<String?> onChange) {
    return DropdownButtonFormField<String>(
      initialValue: val,
      decoration: InputDecoration(labelText: label, isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12)),
      items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: onChange,
    );
  }

  Widget _dropdownInt(String label, List<int> items, int val, ValueChanged<int?> onChange, {List<String>? labels}) {
    return DropdownButtonFormField<int>(
      initialValue: val,
      decoration: InputDecoration(labelText: label, isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12)),
      items: items.asMap().entries.map((e) =>
        DropdownMenuItem(value: e.value, child: Text(labels != null ? labels[e.key] : '${e.value}'))
      ).toList(),
      onChanged: onChange,
    );
  }

  Widget _dateBanner(DateTime date, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _navy.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _navy.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.calendar_month, color: _navy),
        const SizedBox(width: 10),
        Text(_fmtDate(date), style: const TextStyle(color: _navy, fontWeight: FontWeight.w700)),
        const Spacer(),
        const Icon(Icons.edit, color: _navy, size: 16),
      ]),
    ),
  );

  // ── Date / time helpers ───────────────────────────────────────────────────

  String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  String _fmtTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

  TimeOfDay _parseTime(String s) {
    final parts = s.split(':');
    if (parts.length != 2) return const TimeOfDay(hour: 18, minute: 0);
    return TimeOfDay(
      hour: (int.tryParse(parts[0]) ?? 18).clamp(0, 23),
      minute: (int.tryParse(parts[1]) ?? 0).clamp(0, 59),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Bracket Canvas Widget
// ═══════════════════════════════════════════════════════════════════════════

class _BracketCanvas extends StatelessWidget {
  const _BracketCanvas({
    required this.tournament,
    required this.rounds,
    required this.leftMatches,
    required this.rightMatches,
    required this.getName,
    required this.onMatchTap,
    required this.onWinnerTap,
    required this.actionLoading,
  });
  // ignore leftMatches / rightMatches — kept for API compat but unused here

  final Tournament tournament;
  final List<List<TournamentMatch?>> rounds;
  final List<TournamentMatch?> leftMatches;
  final List<TournamentMatch?> rightMatches;
  final String Function(int) getName;
  final void Function(TournamentMatch) onMatchTap;
  final void Function(TournamentMatch) onWinnerTap;
  final bool actionLoading;

  // Layout constants — exposed as static so _buildBracket can compute natural size
  static const double pBoxW   = 130;
  static const double pBoxH   = 38;
  static const double pGap    = 6;    // gap between 2 participants of same match
  static const double mGap    = 24;   // gap between matches in same round
  static const double colGap  = 56;   // horizontal gap between rounds
  static const double rBoxW   = 130;  // result box width
  static const double rBoxH   = 62;   // result box height
  static const double centerW = 180;  // finale center column

  // ── Layout ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final roundCount = rounds.length;
    if (roundCount == 0 || rounds.first.isEmpty) {
      return const Text('Aucun match à afficher.');
    }
    final leftCount = rounds.first.length ~/ 2;
    if (leftCount == 0) return const Text('Format non supporté (min 4 participants).');

    final yCenters  = _computeYCenters(leftCount);
    final halfWidth = pBoxW + colGap + (roundCount - 1) * (rBoxW + colGap);
    final totalWidth = halfWidth * 2 + centerW;

    final matchH   = 2 * pBoxH + pGap;
    final totalMatchH = leftCount * matchH + math.max(0, leftCount - 1) * mGap;
    final canvasH  = 40 + totalMatchH + 180;

    return SizedBox(
      width: totalWidth,
      height: math.max(canvasH, 320),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: CustomPaint(
            painter: _BracketLinesPainter(
              yCenters: yCenters, leftCount: leftCount,
              pBoxW: pBoxW, pBoxH: pBoxH, pGap: pGap, mGap: mGap,
              colGap: colGap, rBoxW: rBoxW, centerW: centerW,
              totalWidth: totalWidth, roundCount: roundCount,
            ),
          )),
          ..._buildAllBoxes(yCenters, leftCount, totalWidth, roundCount),
        ],
      ),
    );
  }

  /// Recursive: yCenters[r] = list of Y-centers for round r on each side.
  List<List<double>> _computeYCenters(int leftCount) {
    var cur = List.generate(leftCount, (i) => _matchCenterY(i, leftCount));
    final all = [List<double>.from(cur)];
    while (cur.length > 1) {
      final nxt = <double>[];
      for (var i = 0; i + 1 < cur.length; i += 2) {
        nxt.add((cur[i] + cur[i + 1]) / 2);
      }
      all.add(List<double>.from(nxt));
      cur = nxt;
    }
    return all;
  }

  double _matchCenterY(int mi, int leftCount) {
    final matchH = 2 * pBoxH + pGap;
    return 40 + mi * (matchH + mGap) + matchH / 2;
  }

  List<Widget> _buildAllBoxes(
    List<List<double>> yCenters, int leftCount,
    double totalWidth, int roundCount,
  ) {
    final widgets = <Widget>[];

    // ── LEFT: participant boxes (first round only) ────────────────────────
    for (var mi = 0; mi < leftCount; mi++) {
      final match = (rounds[0].length > mi) ? rounds[0][mi] : null;
      final cy = yCenters[0][mi];
      widgets.add(_pos(0, cy - pBoxH - pGap / 2, pBoxW, pBoxH,
        _pBox(match?.joueur1 ?? 0, match?.vainqueur)));
      widgets.add(_pos(0, cy + pGap / 2, pBoxW, pBoxH,
        _pBox(match?.joueur2 ?? 0, match?.vainqueur)));
    }

    // ── LEFT: result boxes (rounds 0…roundCount-2) ────────────────────────
    for (var r = 0; r < roundCount - 1; r++) {
      final half    = rounds[r].sublist(0, rounds[r].length ~/ 2);
      final cens    = r < yCenters.length ? yCenters[r] : <double>[];
      final rx      = pBoxW + colGap + r * (rBoxW + colGap);
      for (var mi = 0; mi < half.length && mi < cens.length; mi++) {
        final m  = half[mi];
        final cy = cens[mi];
        widgets.add(_pos(rx, cy - rBoxH / 2, rBoxW, rBoxH, _rBox(m)));
        if (m != null) widgets.add(_pos(rx, cy + rBoxH / 2 + 2, rBoxW, 28, _actionRow(m)));
      }
    }

    // ── RIGHT: participant boxes (first round, mirrored) ─────────────────
    for (var mi = 0; mi < leftCount; mi++) {
      final rIdx = leftCount + mi;
      final match = (rounds[0].length > rIdx) ? rounds[0][rIdx] : null;
      final cy    = yCenters[0][mi];
      final px    = totalWidth - pBoxW;
      widgets.add(_pos(px, cy - pBoxH - pGap / 2, pBoxW, pBoxH,
        _pBox(match?.joueur1 ?? 0, match?.vainqueur)));
      widgets.add(_pos(px, cy + pGap / 2, pBoxW, pBoxH,
        _pBox(match?.joueur2 ?? 0, match?.vainqueur)));
    }

    // ── RIGHT: result boxes (rounds 0…roundCount-2, mirrored) ────────────
    for (var r = 0; r < roundCount - 1; r++) {
      final half = rounds[r].sublist(rounds[r].length ~/ 2);
      final cens = r < yCenters.length ? yCenters[r] : <double>[];
      final rx   = totalWidth - pBoxW - colGap - rBoxW - r * (rBoxW + colGap);
      for (var mi = 0; mi < half.length && mi < cens.length; mi++) {
        final m  = half[mi];
        final cy = cens[mi];
        widgets.add(_pos(rx, cy - rBoxH / 2, rBoxW, rBoxH, _rBox(m)));
        if (m != null) widgets.add(_pos(rx, cy + rBoxH / 2 + 2, rBoxW, 28, _actionRow(m)));
      }
    }

    // ── CENTER: Finale ────────────────────────────────────────────────────
    final finale  = rounds.last.isNotEmpty ? rounds.last.first : null;
    final cx      = totalWidth / 2 - centerW / 2;
    final finaleY = yCenters.last.isNotEmpty ? yCenters.last[0] : 100.0;

    // Trophy icon
    widgets.add(Positioned(
      left: cx + centerW / 2 - 20,
      top:  finaleY - 80,
      child: const Icon(Icons.emoji_events, color: _gold, size: 40),
    ));

    // Finale block
    widgets.add(Positioned(
      left: cx, top: finaleY - 36,
      child: _finaleBlock(finale),
    ));

    return widgets;
  }

  // ── Widget builders ───────────────────────────────────────────────────────

  Positioned _pos(double l, double t, double w, double h, Widget c) =>
    Positioned(left: l, top: t, width: w, height: h, child: c);

  Widget _pBox(int id, int? winnerId) {
    final isWinner = winnerId != null && winnerId == id && id > 0;
    final empty    = id <= 0;
    return Container(
      decoration: BoxDecoration(
        color: isWinner ? _gold : (empty ? Colors.grey.shade100 : _navy),
        border: Border.all(color: isWinner ? _gold : (empty ? _border : _navy)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerLeft,
      child: Row(children: [
        if (isWinner) const Icon(Icons.star, color: _textDk, size: 12),
        if (isWinner) const SizedBox(width: 3),
        Expanded(child: Text(
          empty ? 'À définir' : getName(id),
          style: TextStyle(
            color: isWinner ? _textDk : (empty ? Colors.grey : Colors.white),
            fontWeight: FontWeight.w700, fontSize: 12,
          ),
          overflow: TextOverflow.ellipsis,
        )),
      ]),
    );
  }

  Widget _rBox(TournamentMatch? match) {
    final wId      = match?.vainqueur;
    final hasWin   = wId != null && wId > 0;
    final canClick = match != null && (match.joueur1 > 0 || match.joueur2 > 0);

    String? scoreStr;
    if (match != null) {
      final parts = [match.scoreSet1, match.scoreSet2, match.scoreSet3]
          .whereType<String>()
          .toList();
      if (parts.isNotEmpty) scoreStr = parts.join(' / ');
    }

    return GestureDetector(
      onTap: canClick ? () => onWinnerTap(match) : null,
      child: Container(
        decoration: BoxDecoration(
          color: hasWin ? _gold.withValues(alpha: 0.15) : Colors.grey.shade50,
          border: Border.all(color: hasWin ? _gold : _border, width: hasWin ? 2 : 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Schedule info row
            if (match != null) ...[
              if (match.dateMatch != null)
                Text(
                  '${match.dateMatch!.day.toString().padLeft(2,'0')}/${match.dateMatch!.month.toString().padLeft(2,'0')}/${match.dateMatch!.year}',
                  style: const TextStyle(fontSize: 7, color: Colors.blueGrey, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              Text(
                '${match.heureDebut}  T${match.terrainNumero}  ${match.complexeSportif}',
                style: const TextStyle(fontSize: 7.5, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 2),
            // Winner / tap label
            Row(children: [
              if (hasWin) const Icon(Icons.emoji_events, color: _gold, size: 11),
              if (hasWin) const SizedBox(width: 3),
              Expanded(child: Text(
                hasWin ? getName(wId) : (canClick ? '→ toucher' : '—'),
                style: TextStyle(
                  color: hasWin ? _textDk : (canClick ? _navy : Colors.grey),
                  fontWeight: hasWin ? FontWeight.w800 : FontWeight.w400,
                  fontSize: 11,
                  fontStyle: !hasWin && canClick ? FontStyle.italic : FontStyle.normal,
                ),
                overflow: TextOverflow.ellipsis,
              )),
            ]),
            if (scoreStr != null)
              Text(scoreStr,
                  style: const TextStyle(fontSize: 9, color: Colors.black54, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // Two separate buttons: Params | Résultat
  Widget _actionRow(TournamentMatch match) => Row(children: [
    Expanded(child: GestureDetector(
      onTap: () => onMatchTap(match),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(5)),
        child: Container(
          height: 26,
          decoration: BoxDecoration(
            color: _navy.withValues(alpha: 0.07),
            border: Border.all(color: _border),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.settings, size: 11, color: _navy),
            SizedBox(width: 2),
            Text('Params', style: TextStyle(fontSize: 9, color: _navy, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    )),
    Expanded(child: GestureDetector(
      onTap: () => onWinnerTap(match),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(5)),
        child: Container(
          height: 26,
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.12),
            border: Border.all(color: _gold.withValues(alpha: 0.5)),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.emoji_events, size: 11, color: _gold),
            SizedBox(width: 2),
            Text('Résultat', style: TextStyle(fontSize: 9, color: _navy, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    )),
  ]);

  Widget _finaleBlock(TournamentMatch? f) {
    final hasWin   = f?.vainqueur != null && (f?.vainqueur ?? 0) > 0;
    final champName = hasWin ? getName(f!.vainqueur!) : 'CHAMPION';
    final viceId   = hasWin
      ? (f!.vainqueur == f.joueur1 ? f.joueur2 : f.joueur1) : 0;
    final viceName = viceId > 0 ? getName(viceId) : 'VICE-CHAMPION';

    return SizedBox(
      width: centerW,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: centerW,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            color: _navy,
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: const Text('FINALE', textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900,
              letterSpacing: 2, fontSize: 12)),
        ),
        if (f != null)
          Container(
            width: centerW,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            color: _navy.withValues(alpha: 0.08),
            child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              if (f.dateMatch != null)
                Text(
                  '${f.dateMatch!.day.toString().padLeft(2,'0')}/${f.dateMatch!.month.toString().padLeft(2,'0')}/${f.dateMatch!.year}',
                  style: const TextStyle(fontSize: 9, color: _navy, fontWeight: FontWeight.w800),
                ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.schedule, size: 9, color: _navy),
                const SizedBox(width: 3),
                Text('${f.heureDebut}  T${f.terrainNumero}',
                  style: const TextStyle(fontSize: 9, color: _navy, fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                const Icon(Icons.location_on_outlined, size: 9, color: _navy),
                const SizedBox(width: 2),
                Flexible(child: Text(f.complexeSportif,
                  style: const TextStyle(fontSize: 9, color: _navy, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis)),
              ]),
            ]),
          ),
        Container(
          width: centerW,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          color: _gold,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.military_tech, color: _textDk, size: 14),
            const SizedBox(width: 4),
            Flexible(child: Text(champName,
              style: const TextStyle(color: _textDk, fontWeight: FontWeight.w900, fontSize: 12),
              overflow: TextOverflow.ellipsis)),
          ]),
        ),
        Container(
          width: centerW,
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
          decoration: BoxDecoration(
            color: _gold.withValues(alpha: 0.08),
            border: Border.all(color: _gold),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(child: Text(viceName,
              style: const TextStyle(color: _navy, fontWeight: FontWeight.w700, fontSize: 11),
              overflow: TextOverflow.ellipsis)),
          ]),
        ),
        if (f != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => onMatchTap(f),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: _navy.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.settings, size: 12, color: _navy),
                  SizedBox(width: 3),
                  Text('Params', style: TextStyle(color: _navy, fontSize: 10, fontWeight: FontWeight.w700)),
                ]),
              ),
            )),
            const SizedBox(width: 6),
            Expanded(child: GestureDetector(
              onTap: () => onWinnerTap(f),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.15),
                  border: Border.all(color: _gold),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.emoji_events, size: 12, color: _gold),
                  SizedBox(width: 3),
                  Text('Résultat', style: TextStyle(color: _navy, fontSize: 10, fontWeight: FontWeight.w700)),
                ]),
              ),
            )),
          ]),
        ],
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Lines Painter  — uses precomputed yCenters
// ═══════════════════════════════════════════════════════════════════════════

class _BracketLinesPainter extends CustomPainter {
  const _BracketLinesPainter({
    required this.yCenters,
    required this.leftCount,
    required this.pBoxW,
    required this.pBoxH,
    required this.pGap,
    required this.mGap,
    required this.colGap,
    required this.rBoxW,
    required this.centerW,
    required this.totalWidth,
    required this.roundCount,
  });

  final List<List<double>> yCenters;
  final int leftCount;
  final double pBoxW, pBoxH, pGap, mGap, colGap, rBoxW, centerW, totalWidth;
  final int roundCount;

  Paint get _paint => Paint()
    ..color = _border
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final p    = Path();
    final cx   = totalWidth / 2 - centerW / 2;
    final finY = yCenters.last.isNotEmpty ? yCenters.last[0] : size.height / 2;

    // ── Left side ─────────────────────────────────────────────────────────
    for (var r = 0; r < roundCount - 1; r++) {
      final cens  = r < yCenters.length ? yCenters[r] : <double>[];
      final curX  = pBoxW + colGap + r * (rBoxW + colGap);
      final midX  = pBoxW + colGap / 2;

      if (r == 0) {
        for (final cy in cens) {
          final p1y = cy - pBoxH / 2 - pGap / 2;
          final p2y = cy + pBoxH / 2 + pGap / 2;
          p.moveTo(pBoxW, p1y); p.lineTo(midX, p1y); p.lineTo(midX, cy); p.lineTo(curX, cy);
          p.moveTo(pBoxW, p2y); p.lineTo(midX, p2y); p.lineTo(midX, cy);
        }
      }

      if (r + 1 < yCenters.length) {
        final nextX  = pBoxW + colGap + (r + 1) * (rBoxW + colGap);
        final nCens  = yCenters[r + 1];
        final branchX = curX + rBoxW + colGap / 2;
        for (var mi = 0; mi < nCens.length; mi++) {
          final cyA = (mi * 2)     < cens.length ? cens[mi * 2]     : finY;
          final cyB = (mi * 2 + 1) < cens.length ? cens[mi * 2 + 1] : finY;
          final pY  = nCens[mi];
          p.moveTo(curX + rBoxW, cyA); p.lineTo(branchX, cyA); p.lineTo(branchX, pY); p.lineTo(nextX, pY);
          p.moveTo(curX + rBoxW, cyB); p.lineTo(branchX, cyB); p.lineTo(branchX, pY);
        }
      } else {
        // Last left round → finale center
        for (final cy in cens) { p.moveTo(curX + rBoxW, cy); p.lineTo(cx, cy); }
      }
    }

    // ── Right side (mirrored) ──────────────────────────────────────────────
    for (var r = 0; r < roundCount - 1; r++) {
      final cens  = r < yCenters.length ? yCenters[r] : <double>[];
      final curRx = totalWidth - pBoxW - colGap - rBoxW - r * (rBoxW + colGap);
      final midX  = totalWidth - pBoxW - colGap / 2;

      if (r == 0) {
        for (final cy in cens) {
          final p1y = cy - pBoxH / 2 - pGap / 2;
          final p2y = cy + pBoxH / 2 + pGap / 2;
          final px  = totalWidth - pBoxW;
          p.moveTo(px, p1y); p.lineTo(midX, p1y); p.lineTo(midX, cy); p.lineTo(curRx + rBoxW, cy);
          p.moveTo(px, p2y); p.lineTo(midX, p2y); p.lineTo(midX, cy);
        }
      }

      if (r + 1 < yCenters.length) {
        final nRx    = totalWidth - pBoxW - colGap - rBoxW - (r + 1) * (rBoxW + colGap);
        final nCens  = yCenters[r + 1];
        final branchX = curRx - colGap / 2;
        for (var mi = 0; mi < nCens.length; mi++) {
          final cyA = (mi * 2)     < cens.length ? cens[mi * 2]     : finY;
          final cyB = (mi * 2 + 1) < cens.length ? cens[mi * 2 + 1] : finY;
          final pY  = nCens[mi];
          p.moveTo(curRx, cyA); p.lineTo(branchX, cyA); p.lineTo(branchX, pY); p.lineTo(nRx + rBoxW, pY);
          p.moveTo(curRx, cyB); p.lineTo(branchX, cyB); p.lineTo(branchX, pY);
        }
      } else {
        // Last right round → finale right edge
        for (final cy in cens) { p.moveTo(curRx, cy); p.lineTo(cx + centerW, cy); }
      }
    }

    canvas.drawPath(p, _paint);
  }

  @override
  bool shouldRepaint(covariant _BracketLinesPainter old) => true;
}
