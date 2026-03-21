import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/models.dart';
import '../utils/themes.dart';

// ── Status Badge ──────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    Color c;
    switch (status) {
      case 'pending': c = SRColors.warning; break;
      case 'verified': c = SRColors.success; break;
      case 'investigating': c = SRColors.publicAccent; break;
      case 'resolved': c = SRColors.govAccent; break;
      case 'rejected': c = SRColors.danger; break;
      default: c = SRColors.textMuted;
    }
    final labels = {'pending': 'Menunggu', 'verified': 'Terverifikasi', 'investigating': 'Ditindaklanjuti', 'resolved': 'Selesai', 'rejected': 'Ditolak'};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(99), border: Border.all(color: c.withOpacity(0.4))),
      child: Text(labels[status] ?? status, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Report Card ───────────────────────────────────────────────
class ReportCard extends StatelessWidget {
  final Report r;
  final String routePrefix;
  const ReportCard({super.key, required this.r, required this.routePrefix});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('$routePrefix/detail/${r.id}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: SRColors.border))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (r.categoryName != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: hexColor(r.categoryColor ?? '#1D9BF0', opacity: 0.15), borderRadius: BorderRadius.circular(99)),
                child: Text(r.categoryName!, style: TextStyle(color: hexColor(r.categoryColor ?? '#1D9BF0'), fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
            ],
            StatusBadge(r.status),
            const Spacer(),
            Text(timeago.format(r.createdAt, locale: 'id'), style: const TextStyle(color: SRColors.textMuted, fontSize: 11)),
          ]),
          const SizedBox(height: 8),
          Text(r.title, style: const TextStyle(color: SRColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(r.content, style: const TextStyle(color: SRColors.textSecond, fontSize: 13, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(children: [
            _stat(Icons.thumb_up_outlined, r.supportCount.toString()),
            const SizedBox(width: 12),
            _stat(Icons.remove_red_eye_outlined, r.viewCount.toString()),
            const SizedBox(width: 12),
            _stat(Icons.chat_bubble_outline, r.commentCount.toString()),
            if (r.locationProvince != null) ...[
              const Spacer(),
              const Icon(Icons.location_on_outlined, size: 11, color: SRColors.textMuted),
              const SizedBox(width: 2),
              Text(r.locationProvince!, style: const TextStyle(color: SRColors.textMuted, fontSize: 11)),
            ],
          ]),
        ]),
      ),
    );
  }

  Widget _stat(IconData icon, String val) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 12, color: SRColors.textMuted),
    const SizedBox(width: 3),
    Text(val, style: const TextStyle(color: SRColors.textMuted, fontSize: 12)),
  ]);
}

// ── Error Box ─────────────────────────────────────────────────
class ErrorBox extends StatelessWidget {
  final String message;
  const ErrorBox(this.message, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: SRColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: SRColors.danger.withOpacity(0.3))),
    child: Text(message, style: const TextStyle(color: SRColors.danger, fontSize: 13)),
  );
}

// ── Loading Button ────────────────────────────────────────────
class LoadingButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;
  final String label;
  final Color? color;
  const LoadingButton({super.key, required this.loading, required this.onPressed, required this.label, this.color});
  @override
  Widget build(BuildContext context) => SizedBox(width: double.infinity, height: 50,
    child: ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: color != null ? ElevatedButton.styleFrom(backgroundColor: color) : null,
      child: loading
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : Text(label),
    ));
}
