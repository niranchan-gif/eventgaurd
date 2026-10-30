import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../mock/mock_state.dart';
import '../theme/app_theme.dart';

class GraRiskGridWidget extends StatelessWidget {
  const GraRiskGridWidget({super.key});

  Color _getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFFEF4444);
      case 'HIGH_WARNING':
        return const Color(0xFFF97316);
      case 'LOW_WARNING':
        return const Color(0xFFEAB308);
      default:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MockState>();
    final gridData = state.graGridData;
    final highestZone = state.highestRiskZone;
    final highestScore = state.highestRiskScore;
    final highestSeverity = state.highestRiskSeverity;

    final rows = [
      ['A1', 'A2', 'A3'],
      ['B1', 'B2', 'B3'],
      ['C1', 'C2', 'C3'],
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.charcoalSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highestSeverity == 'CRITICAL'
              ? const Color(0xFFEF4444).withValues(alpha: 0.6)
              : AppTheme.hairlineBorder,
          width: highestSeverity == 'CRITICAL' ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (highestSeverity == 'CRITICAL')
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              blurRadius: 18,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getSeverityColor(highestSeverity),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'GRA CROWD-RISK MAP (3×3 SPATIAL GRID)',
                    style: GoogleFonts.inter(
                      color: AppTheme.titaniumWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSeverityColor(highestSeverity).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _getSeverityColor(highestSeverity), width: 1),
                ),
                child: Text(
                  'PEAK: $highestZone (${highestScore.toStringAsFixed(1)} $highestSeverity)',
                  style: GoogleFonts.inter(
                    color: _getSeverityColor(highestSeverity),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              return Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: rows.map((rowCells) {
                  return TableRow(
                    children: rowCells.map((cellName) {
                      final info = gridData[cellName];
                      final score = (info?['risk_score'] as num?)?.toDouble() ?? 0.0;
                      final severity = (info?['severity'] as String?) ?? 'SAFE';
                      final people = (info?['people_count'] as num?)?.toInt() ?? 0;
                      final color = _getSeverityColor(severity);

                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: severity == 'SAFE' ? 0.08 : 0.20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: color.withValues(alpha: severity == 'SAFE' ? 0.35 : 0.9),
                              width: severity == 'CRITICAL' ? 1.8 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    cellName,
                                    style: GoogleFonts.inter(
                                      color: color,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    'P: $people',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.mutedSilver,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                score.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                  color: AppTheme.titaniumWhite,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                severity.replaceAll('_WARNING', '-WARN'),
                                style: GoogleFonts.inter(
                                  color: color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
