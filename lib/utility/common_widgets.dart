import 'package:flutter/material.dart';

class CommonWidgets {
  static Widget buildMessageList(List<String> messages) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: const Icon(Icons.message, color: Colors.deepPurple),
              title: Text(messages[index]),
              tileColor: Colors.grey[200],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    required String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        validator: validator,
      ),
    );
  }

  static Widget buildPoeCard({
    required List<dynamic> poEs,
    required Function(dynamic poe, int index) onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: poEs.length,
          itemBuilder: (context, index) {
            final poe = poEs[index];
            return ListTile(
              leading: const Icon(Icons.verified, color: Colors.green),
              title: Text(
                'PoE #${index + 1} - ${poe.proofType}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Timestamp: ${poe.timestampTime}'),
              tileColor: Colors.grey[200],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              trailing: const Icon(Icons.arrow_forward, color: Colors.blue),
              onTap: () => onTap(poe, index),
            );
          },
        ),
      ),
    );
  }
}
