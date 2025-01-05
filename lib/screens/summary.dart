/*
    
     final sortedActivities = List<DoneActivity>.from(databaseActivitiesProvider.activities)..sort((a, b) => b.finishTime.compareTo(a.finishTime));


          // Step 2: Group activities by groupTitle
          final groupedActivities = <String, List<DoneActivity>>{};
          for (final activity in sortedActivities) {
            groupedActivities.putIfAbsent(activity.groupTitle, () => []).add(activity);
          }

          // Step 3: Build cards for each group
          final groupCards = groupedActivities.entries.map((entry) {
            final groupTitle = entry.key.isEmpty ? 'Extra' : entry.key;
            final activities = entry.value;


    on this screen we are going to use the fl charts extensively to show the user the data in a graphical way

    //there is gonna be a row of input chips that will allow the user to view the data for today, this week, this month, this year, and all time


    alright the first chart is gonna be a bar chart that will show the minutes spent on each activity for the day [only the top 7 most recent activities will be shown]
    
    the second chart is gonna be a pie chart that will show the percentage of time spent on each group for the day [only the top 7 most recent activities will be shown]

    the third chart is gonna be a line chart that will show the number of minutes for each group that we have saved or over-spent for the day [only the top 7 most recent activities will be shown]



 */

import 'dart:developer';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:my_activities/providers/providers.dart';
import 'package:my_activities/screens/homepage.dart';
import 'package:provider/provider.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  String selectedTimeRange = 'Today';

  // Helper method to filter activities based on time range
  List<DoneActivity> filterActivities(List<DoneActivity> activities, String timeRange) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return activities.where((activity) {
      switch (timeRange) {
        case 'Today':
          return activity.finishTime.isAfter(startOfDay);
        case 'Week':
          final startOfWeek = startOfDay.subtract(Duration(days: startOfDay.weekday - 1));
          return activity.finishTime.isAfter(startOfWeek);
        case 'Month':
          final startOfMonth = DateTime(now.year, now.month, 1);
          return activity.finishTime.isAfter(startOfMonth);
        case 'Year':
          final startOfYear = DateTime(now.year, 1, 1);
          return activity.finishTime.isAfter(startOfYear);
        case 'All Time':
          return true;
        default:
          return true;
      }
    }).toList();
  }

  // Helper method to get activity duration in minutes
  double getActivityDuration(DoneActivity activity) {
    return activity.finishTime.difference(activity.startTime).inMinutes.toDouble();
  }

  // Helper method to get time variance (positive means saved time, negative means over-spent)
  double getTimeVariance(DoneActivity activity) {
    final estimatedDuration = activity.estimatedEndTime.difference(activity.startTime).inMinutes.toDouble();
    final actualDuration = getActivityDuration(activity);
    return estimatedDuration - actualDuration;
  }

  Widget buildBarChart(List<DoneActivity> activities) {
    // Get top 7 most recent activities
    final topActivities = activities.take(7).toList();

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false), // Remove left labels
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false), // Remove top labels
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,

                reservedSize: 40, // Increased reserved size for labels
                getTitlesWidget: (value, meta) {
                  if (value >= 0 && value < topActivities.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: SizedBox(
                        width: 60, // Adjusted to fit labels within limited space
                        child: Text(
                          topActivities[value.toInt()].title.length > 10 ? "${topActivities[value.toInt()].title.substring(0, 7)}..." : topActivities[value.toInt()].title,
                          style: const TextStyle(fontSize: 8), // Reduced font size
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
            //customize the left labels to be smaller
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 30,
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: themeProvider.themeData.colorScheme.onSurface.withOpacity(0.8),
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),

          //dont show top labels

          barGroups: List.generate(
            topActivities.length,
            (index) => BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: getActivityDuration(topActivities[index]),
                  color: themeProvider.themeData.colorScheme.primary,
                  width: 20,
                ),
              ],
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (spot) => themeProvider.themeData.colorScheme.inversePrimary.withOpacity(0.8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final activity = topActivities[group.x.toInt()];
                return BarTooltipItem(
                  '${activity.title}\n${getActivityDuration(activity).toStringAsFixed(0)}m',
                  const TextStyle(),
                );
              },
              tooltipRoundedRadius: 8,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPieChart(List<DoneActivity> activities) {
    // Group activities by groupTitle and calculate total duration
    final groupDurations = <String, double>{};
    for (final activity in activities) {
      final group = activity.groupTitle.isEmpty ? 'Extra' : activity.groupTitle;
      groupDurations[group] = (groupDurations[group] ?? 0) + getActivityDuration(activity);
    }

    // Convert to list and sort by duration
    final sortedGroups = groupDurations.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // Take top 7 groups
    final topGroups = sortedGroups.take(7).toList();
    log('BUIDLING THE CHART');

    // Generate colors
    final colorScheme = themeProvider.themeData.colorScheme;
    final colors = [
      colorScheme.primary.withOpacity(0.5),
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.error,
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
    ];

    return Container(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: AspectRatio(
        aspectRatio: 1.5,
        child: PieChart(
          PieChartData(
            sections: List.generate(
              topGroups.length,
              (index) => PieChartSectionData(
                value: topGroups[index].value,
                title: '${topGroups[index].key}\n${topGroups[index].value.toStringAsFixed(0)}m',
                color: colors[index % colors.length],
                radius: 100,
                titleStyle: TextStyle(
                  fontSize: 7,
                  // color: //on surface color
                  color: themeProvider.themeData.colorScheme.surface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLineChart(List<DoneActivity> activities) {
    final groupVariances = <String, List<double>>{};
    final timePoints = List.generate(7, (index) => index.toDouble());

    for (final activity in activities.take(7)) {
      final group = activity.groupTitle.isEmpty ? 'Extra' : activity.groupTitle;
      groupVariances.putIfAbsent(group, () => []).add(getTimeVariance(activity));
    }

    final colorScheme = themeProvider.themeData.colorScheme;
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      colorScheme.error,
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.tertiaryContainer,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: AspectRatio(
        aspectRatio: 1.5,
        child: LineChart(
          LineChartData(
            lineBarsData: groupVariances.entries.map((entry) {
              final groupIndex = groupVariances.keys.toList().indexOf(entry.key);
              final color = colors[groupIndex % colors.length];
              return LineChartBarData(
                spots: List.generate(
                  entry.value.length,
                  (index) => FlSpot(timePoints[index], entry.value[index]),
                ),
                color: color,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 4,
                    color: color,
                    strokeWidth: 2,
                    strokeColor: colorScheme.surface,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withOpacity(0.1),
                ),
              );
            }).toList(),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  reservedSize: 50,
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value >= 0 && value < activities.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: SizedBox(
                          child: RotatedBox(
                            quarterTurns: -1,
                            child: Text(
                              activities[value.toInt()].title.length > 10 ? "${activities[value.toInt()].title.substring(0, 7)}..." : activities[value.toInt()].title,
                              style: TextStyle(
                                fontSize: 8,
                                color: colorScheme.onSurface.withOpacity(0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.8),
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              drawVerticalLine: false,
              drawHorizontalLine: true,
              horizontalInterval: 5, // Increased interval for less cluttered grid
              checkToShowHorizontalLine: (value) => value % 5 == 0, // Only show lines at intervals of 5
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: value == 0 ? colorScheme.outline : colorScheme.outline.withOpacity(0.2),
                  strokeWidth: value == 0 ? 1.5 : 0.5,
                  dashArray: value == 0 ? null : [5, 5],
                );
              },
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (spot) => colorScheme.inversePrimary.withOpacity(0.8),
                tooltipRoundedRadius: 8,
                tooltipBorder: BorderSide(
                  color: colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
                tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final groupIndex = spot.barIndex;
                    final groupName = groupVariances.keys.toList()[groupIndex];
                    return LineTooltipItem(
                      '$groupName\n${spot.y.toStringAsFixed(1)} min',
                      TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    );
                  }).toList();
                },
              ),
              handleBuiltInTouches: true,
              touchSpotThreshold: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildStatisticsTable(List<DoneActivity> allActivities) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfDay.subtract(Duration(days: startOfDay.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    // Calculate statistics for different time periods
    Map<String, int> getActivityCounts(DateTime startDate) {
      final periodActivities = allActivities.where((a) => a.finishTime.isAfter(startDate)).toList();
      final delayedCount = periodActivities.where((a) => a.finishTime.isAfter(a.estimatedEndTime)).length;
      final aheadCount = periodActivities.where((a) => a.finishTime.isBefore(a.estimatedEndTime)).length;
      final onTimeCount = periodActivities.length - delayedCount - aheadCount;

      return {
        'total': periodActivities.length,
        'delayed': delayedCount,
        'ahead': aheadCount,
        'onTime': onTimeCount,
      };
    }

    final dayStats = getActivityCounts(startOfDay);
    final weekStats = getActivityCounts(startOfWeek);
    final monthStats = getActivityCounts(startOfMonth);

    // Calculate schedule adherence for today
    double calculateDayScheduleAdherence() {
      final todayActivities = allActivities.where((a) => a.finishTime.isAfter(startOfDay)).toList();

      if (todayActivities.isEmpty) return 0.0;

      int totalMinutesOnSchedule = 0;
      final totalMinutes = todayActivities.fold<int>(0, (sum, activity) {
        final duration = activity.finishTime.difference(activity.startTime).inMinutes;

        totalMinutesOnSchedule += duration;
        return sum + duration;
      });

      log('Total minutes: $totalMinutes, On schedule: $totalMinutesOnSchedule');

      return totalMinutes.toDouble();
    }

    Widget buildHeaderCell(String text) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          color: themeProvider.themeData.colorScheme.primary.withOpacity(0.1),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: themeProvider.themeData.colorScheme.primary,
          ),
        ),
      );
    }

    Widget buildDataCell(String text, {bool isHighlight = false}) {
      return SizedBox(
        width: double.infinity, // Ensures the container takes full width
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: BorderSide(
          color: themeProvider.themeData.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      elevation: 0,
      margin: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          DataTable(
            headingRowHeight: 40,
            dataRowMaxHeight: 56,
            columnSpacing: 16, // Reduced spacing between columns
            horizontalMargin: 16, // Reduced horizontal margin
            columns: [
              DataColumn(
                label: buildHeaderCell('Period'),
              ),
              DataColumn(
                label: buildHeaderCell('Tasks'),
              ),
              DataColumn(
                label: buildHeaderCell('Delayed'),
              ),
              DataColumn(
                label: buildHeaderCell('Nailed'),
              ),
            ],
            rows: [
              DataRow(cells: [
                DataCell(buildDataCell('Today', isHighlight: true)),
                DataCell(buildDataCell(dayStats['total'].toString(), isHighlight: true)),
                DataCell(buildDataCell(dayStats['delayed'].toString(), isHighlight: true)),
                DataCell(buildDataCell(dayStats['ahead'].toString(), isHighlight: true)),
              ]),
              DataRow(cells: [
                DataCell(buildDataCell('Week')),
                DataCell(buildDataCell(weekStats['total'].toString())),
                DataCell(buildDataCell(weekStats['delayed'].toString())),
                DataCell(buildDataCell(weekStats['ahead'].toString())),
              ]),
              DataRow(cells: [
                DataCell(buildDataCell('Month')),
                DataCell(buildDataCell(monthStats['total'].toString())),
                DataCell(buildDataCell(monthStats['delayed'].toString())),
                DataCell(buildDataCell(monthStats['ahead'].toString())),
              ]),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Today: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${calculateDayScheduleAdherence().toStringAsFixed(0)} mins (${(calculateDayScheduleAdherence() / 60).toStringAsFixed(1)} hours)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                //add a progress bar to show the schedule adherence out of the total time
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Stack(
                    children: [
                      Container(
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: themeProvider.themeData.colorScheme.primary.withOpacity(0.1),
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            height: 20,
                            width: constraints.maxWidth * (calculateDayScheduleAdherence() / 1440),
                            decoration: BoxDecoration(
                              //add an outline
                              border: Border.all(
                                color: themeProvider.themeData.colorScheme.primary.withOpacity(0.3),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                colors: [
                                  themeProvider.themeData.colorScheme.primary,
                                  themeProvider.themeData.colorScheme.primaryContainer,
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Text(
                            '${(calculateDayScheduleAdherence() / 1440 * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: themeProvider.themeData.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //! chart for schedule adherence
  Widget buildLineChartForGivenDuration(List<DoneActivity> allActivities) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    log('selected time period is $selectedTimeRange');

    // Calculate start date based on selected range
    DateTime startDate;
    switch (selectedTimeRange) {
      case 'Today':
        startDate = startOfDay;
        break;
      case 'Week':
        startDate = startOfDay.subtract(Duration(days: startOfDay.weekday - 1));
        break;
      case 'Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = startOfDay;
    }

    log('Start date: $startDate');

    // Create map to store minutes per day
    final Map<DateTime, double> dailyMinutes = {};

    // Initialize all dates in the range with 0 minutes
    DateTime currentDate = startDate;
    while (currentDate.isBefore(now) || currentDate.isAtSameMomentAs(now)) {
      dailyMinutes[DateTime(currentDate.year, currentDate.month, currentDate.day)] = 0;
      currentDate = currentDate.add(const Duration(days: 1));
    }

    // Calculate minutes for each activity
    for (final activity in allActivities) {
      if (activity.finishTime.isAfter(startDate)) {
        final activityDate = DateTime(
          activity.finishTime.year,
          activity.finishTime.month,
          activity.finishTime.day,
        );
        final duration = activity.finishTime.difference(activity.startTime).inMinutes.toDouble();
        dailyMinutes[activityDate] = (dailyMinutes[activityDate] ?? 0) + duration;
      }
    }

    // Convert map to sorted list of FlSpot
    final spots = dailyMinutes.entries
        .map((entry) => FlSpot(
              entry.key.difference(startDate).inDays.toDouble(),
              entry.value / 60, // Convert minutes to hours
            ))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    final colorScheme = themeProvider.themeData.colorScheme;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.3),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final date = startDate.add(Duration(days: value.toInt()));
                  // Customize date format based on selected range
                  String? text;
                  switch (selectedTimeRange) {
                    case 'Today':
                      text = '${date.hour}:00';
                      break;
                    case 'This Week':
                      text = date.weekday == 1
                          ? 'Mon'
                          : date.weekday == 7
                              ? 'Sun'
                              : '';

                      break;
                    case 'This Month':
                      text = date.day.toString();
                      break;
                    case 'This Year':
                      text = Jiffy.parse(date.toString()).format(pattern: 'MM');
                      break;
                    default:
                  }
                  return Text(
                    text ?? '',
                    style: const TextStyle(fontSize: 12),
                  );
                },
                interval: selectedTimeRange == 'This Year' ? 30 : 1,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toStringAsFixed(1)}h',
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          minX: 0,
          maxX: spots.isEmpty ? 0 : spots.last.x,
          minY: 0,
          maxY: spots.isEmpty ? 10 : spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) + 2,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: colorScheme.primary,
              barWidth: 3,
              dotData: FlDotData(show: spots.length < 15),
              belowBarData: BarAreaData(
                show: true,
                // color: Colors.blue.withOpacity(0.2),
                gradient: LinearGradient(
                  colors: [colorScheme.primary.withOpacity(0.01), colorScheme.primary.withOpacity(0.5)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => colorScheme.primary.withOpacity(0.8),
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = startDate.add(Duration(days: spot.x.toInt()));
                  final hours = spot.y;
                  return LineTooltipItem(
                    // '${date.day}/${date.month}/${date.year}\n${hours.toStringAsFixed(1)} hours',
                    '${Jiffy.parse(date.toString()).format(pattern: 'd/M/yyyy')}\n${hours.toStringAsFixed(1)} hours',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get activities from provider
    final activities = databaseActivitiesProvider.activities;
    final filteredActivities = filterActivities(activities, selectedTimeRange);

    return Consumer(builder: (context, ThemeProvider themeProvider, child) {
      log('rebuilding');
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: ListView(
            children: [
              const SizedBox(height: 16.0),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Wrap(
                  spacing: 8.0,
                  children: [
                    'Now',
                    'Week',
                    'Month',
                    'Year',
                    'All Time',
                  ]
                      .map((range) => InputChip(
                            label: Text(range),
                            selected: selectedTimeRange == range,
                            onPressed: () => setState(() => selectedTimeRange = range),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 10.0),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                  side: BorderSide(
                    color: themeProvider.themeData.colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                elevation: 0,
                margin: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Time Spent per Activity',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    buildBarChart(filteredActivities),
                  ],
                ),
              ),
              const SizedBox(height: 10.0),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                  side: BorderSide(
                    color: themeProvider.themeData.colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                elevation: 0,
                margin: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Time Distribution by Group',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    buildPieChart(filteredActivities),
                  ],
                ),
              ),
              const SizedBox(height: 10.0),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                  side: BorderSide(
                    color: themeProvider.themeData.colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                elevation: 0,
                margin: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Time Variance by Group',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    buildLineChart(filteredActivities),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              buildStatisticsTable(activities),
              const SizedBox(height: 10.0),
              //built a line chart for schedule adherence
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                  side: BorderSide(
                    color: themeProvider.themeData.colorScheme.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                elevation: 0,
                margin: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Schedule Adherence',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text('for $selectedTimeRange'),
                        ],
                      ),
                    ),
                    buildLineChartForGivenDuration(activities),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
