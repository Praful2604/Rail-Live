import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rail_live/app_constant.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({
    super.key,
    required this.userData,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {

  late TextEditingController nameController;
  late TextEditingController phoneController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    nameController =
        TextEditingController(text: widget.userData['name'] ?? '');

    phoneController =
        TextEditingController(text: widget.userData['phone'] ?? '');
  }

  Future<void> updateProfile() async {
    try {
      setState(() {
        isLoading = true;
      });

      await FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        "name": nameController.text.trim(),
        "phone": phoneController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile Updated"),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RailLiveColors.background,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: RailLiveColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone",
                prefixIcon: Icon(Icons.phone),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : updateProfile,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}