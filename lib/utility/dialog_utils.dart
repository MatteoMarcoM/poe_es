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
              Text('PoE Rifiutata',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'La PoE è stata rifiutata per la seguente chiave pubblica:',
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
    required TextEditingController matricolaController,
    required TextEditingController nomeController,
    required TextEditingController cognomeController,
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
                "Inserisci i dati",
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
                              controller: matricolaController,
                              label: "Matricola",
                              icon: Icons.badge,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Inserisci la matricola';
                                }
                                if (!RegExp(r'^\d+$').hasMatch(value)) {
                                  return 'La matricola deve essere un numero';
                                }
                                return null;
                              },
                            ),
                            CommonWidgets.buildTextField(
                              controller: nomeController,
                              label: "Nome",
                              icon: Icons.person,
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Inserisci il nome';
                                }
                                return null;
                              },
                            ),
                            CommonWidgets.buildTextField(
                              controller: cognomeController,
                              label: "Cognome",
                              icon: Icons.person_outline,
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Inserisci il cognome';
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
                                  return 'Inserisci l\'email';
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                    .hasMatch(value)) {
                                  return 'Inserisci un\'email valida';
                                }
                                return null;
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: TextFormField(
                                controller: engagementDataController,
                                decoration: const InputDecoration(
                                  labelText: "Dati di Engagement",
                                  icon: Icon(Icons.dataset),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.multiline,
                                maxLines: 5,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Inserisci i dati di engagement';
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
                  child: const Text("Annulla",
                      style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      onSubmit(
                        matricolaController.text,
                        nomeController.text,
                        cognomeController.text,
                        emailController.text,
                        engagementDataController.text,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.send),
                  label: const Text("Invia"),
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
