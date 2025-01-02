import 'dart:developer';

import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jiffy/jiffy.dart';
import 'package:my_activities/providers/providers.dart';
import 'package:my_activities/screens/active_activities.dart';

class AddActivityScreen extends StatefulWidget {
  final String? groupTitle;
  const AddActivityScreen({super.key, this.groupTitle});
  //there should be an optional param to indicate that i am adding a new activity from a group page this way the group title will be prefilled

  @override
  _AddActivityScreenState createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _groupTitleController = TextEditingController();
  final descriptionController = TextEditingController();
  final DateTime _startTime = DateTime.now();
  DateTime _estimatedEndTime = DateTime.now().add(const Duration(hours: 1));
  Category _selectedCategory = Category.s;
  final activeGroups = sharedPrefActivitiesProvider.activities.map((e) => e.groupTitle).toSet();
  final doneGroups = databaseActivitiesProvider.activities.map((e) => e.groupTitle).toSet();
  String _description = '';

  // Add this helper method in the class
  String _formatTimeRemaining(DateTime endTime) {
    final now = DateTime.now();
    final difference = endTime.difference(now);

    final hours = difference.inHours.abs();
    final minutes = (difference.inMinutes % 60).abs();
    if (hours == 0 && minutes == 0) {
      return 'Due now';
    }
    if (hours == 0) {
      return '$minutes mins ';
    }

    if (difference.isNegative) {
      return 'Overdue by $hours hrs $minutes mins';
    } else {
      return '$hours hr $minutes mins ';
    }
  }

  @override
  Widget build(BuildContext context) {
    // final colorScheme = themeProvider.themeData.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Activity'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
                  ],
                  onChanged: (value) {
                    final cleanedText = value.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
                    if (value != cleanedText) {
                      _titleController.text = cleanedText;
                      _titleController.selection = TextSelection.fromPosition(
                        TextPosition(offset: cleanedText.length),
                      );
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final allGroups = activeGroups.union(doneGroups);
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return allGroups.where(
                      (group) => group.toLowerCase().contains(textEditingValue.text.toLowerCase()),
                    );
                  },
                  onSelected: (String selection) {
                    setState(() {
                      _groupTitleController.text = selection; // Synchronize controller manually here
                    });
                  },
                  fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                    // Synchronize the controllers
                    final preFilledGroupTitle = widget.groupTitle;
                    textEditingController.text = _groupTitleController.text;

                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: preFilledGroupTitle ?? 'Group Title',
                        border: const OutlineInputBorder(),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]+')),
                      ],
                      onChanged: (value) {
                        final cleanedText = value.replaceAll(RegExp(r'[^a-zA-Z0-9\s]+'), '');
                        if (value != cleanedText) {
                          textEditingController.text = cleanedText;
                          textEditingController.selection = TextSelection.fromPosition(
                            TextPosition(offset: cleanedText.length),
                          );
                        }
                        setState(() {
                          _groupTitleController.text = cleanedText; // Update the controller's value here
                        });
                      },
                      enabled: widget.groupTitle == null, // Disable if groupTitle is prefilled
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        margin: const EdgeInsets.only(top: 15, right: 30),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(color: Theme.of(context).colorScheme.primary),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                title: Text(option),
                                onTap: () {
                                  onSelected(option);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16.0),
                ListTile(
                  //dd-MM-yyyy hh:mm a lets use jiffy to format the date
                  //show (timeago from now using jiffy)
                  title: Text('Estimated End Time (${_formatTimeRemaining(_estimatedEndTime)})'),
                  subtitle: Text(Jiffy.parse(_estimatedEndTime.toString()).yMMMMdjm),
                ),
                const SizedBox(height: 16.0),
                Container(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.timer),
                    label: const Text('Set Time'),
                    onPressed: () async {
                      final picked = await showDurationPicker(
                        context: context,
                        initialTime: const Duration(hours: 0, minutes: 30),
                      );
                      if (picked != null && picked != _estimatedEndTime) {
                        setState(() {
                          _estimatedEndTime = DateTime.now().add(picked);
                        });
                      }
                    },
                  ),
                ),

                const SizedBox(height: 16.0),
                SizedBox(
                  width: 400,
                  child: SegmentedButton<Category>(
                    segments: <ButtonSegment<Category>>[
                      ButtonSegment<Category>(
                        value: Category.w,
                        icon: _selectedCategory == Category.w ? const Icon(Icons.work) : null,
                        label: const Text('W'),
                      ),
                      ButtonSegment<Category>(
                        value: Category.s,
                        icon: _selectedCategory == Category.s ? const Icon(Icons.person) : null,
                        label: const Text('S'),
                      ),
                      ButtonSegment<Category>(
                        value: Category.m,
                        icon: _selectedCategory == Category.m ? const Icon(Icons.medical_services) : null,
                        label: const Text('M'),
                      ),

                      //one for l
                      ButtonSegment<Category>(
                        value: Category.l,
                        icon: _selectedCategory == Category.l ? const Icon(Icons.local_activity) : null,
                        label: const Text('L'),
                      ),
                    ],
                    selected: <Category>{_selectedCategory},
                    onSelectionChanged: (Set<Category> newSelection) {
                      setState(() {
                        _selectedCategory = newSelection.first;
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return Theme.of(context).colorScheme.primaryContainer;
                          }
                          return Theme.of(context).colorScheme.surface;
                        },
                      ),
                    ),
                  ),
                ),
                //to add an optional description lets use a expansion tile with a textformfield

                //here should be an expansion tile for the description
                const SizedBox(height: 16.0),
                ExpansionTile(
                  title: const Text('Description'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
                        ],
                        onChanged: (value) {
                          final cleanedText = value.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
                          if (value != cleanedText) {
                            descriptionController.text = cleanedText;
                            descriptionController.selection = TextSelection.fromPosition(
                              TextPosition(offset: cleanedText.length),
                            );
                          }
                          setState(() {
                            log('description: $cleanedText');
                            _description = cleanedText;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 70.0),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    log('description: $_description');
                    if (_formKey.currentState!.validate()) {
                      final newActivity = ActiveActivity(
                        title: _titleController.text,
                        groupTitle: widget.groupTitle ?? _groupTitleController.text,
                        startTime: _startTime,
                        estimatedEndTime: _estimatedEndTime,
                        category: _selectedCategory,
                        description: _description,
                      );
                      sharedPrefActivitiesProvider.addActivity(newActivity);
                      Navigator.pop(context);
                    }
                  },
                  label: const Text('Add Activity'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
