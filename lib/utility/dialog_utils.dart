import 'package:flutter/material.dart';
import 'dart:convert';
import 'common_widgets.dart';

class DialogUtils {
  static void showRejectionDialog(BuildContext context, String publicKey) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('PoE Rejected',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'The PoE has been rejected for the following public key:',
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              SelectableText(
                publicKey,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  static void showFormDialog(
    BuildContext context, {
    required TextEditingController idNumberController,
    required TextEditingController nameController,
    required TextEditingController surnameController,
    required TextEditingController emailController,
    required TextEditingController engagementDataController,
    required Function(String, String, String, String, String) onSubmit,
  }) {
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final scrollController = ScrollController();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                "Enter Data",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CommonWidgets.buildTextField(
                              controller: idNumberController,
                              label: "ID Number",
                              icon: Icons.badge,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter ID number';
                                }
                                if (!RegExp(r'^\d+$').hasMatch(value)) {
                                  return 'ID must be a number';
                                }
                                return null;
                              },
                            ),
                            CommonWidgets.buildTextField(
                              controller: nameController,
                              label: "First Name",
                              icon: Icons.person,
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter first name';
                                }
                                return null;
                              },
                            ),
                            CommonWidgets.buildTextField(
                              controller: surnameController,
                              label: "Last Name",
                              icon: Icons.person_outline,
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter last name';
                                }
                                return null;
                              },
                            ),
                            CommonWidgets.buildTextField(
                              controller: emailController,
                              label: "Email",
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter email';
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                    .hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: TextFormField(
                                controller: engagementDataController,
                                decoration: const InputDecoration(
                                  labelText: "Engagement Data",
                                  icon: Icon(Icons.dataset),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.multiline,
                                maxLines: 5,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter engagement data';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child:
                      const Text("Cancel", style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      onSubmit(
                        idNumberController.text,
                        nameController.text,
                        surnameController.text,
                        emailController.text,
                        engagementDataController.text,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text("Submit"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static bool isJson(String str) {
    try {
      jsonDecode(str);
      return true;
    } catch (_) {
      return false;
    }
  }
}
