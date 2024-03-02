import 'package:flutter/material.dart';
import 'package:repetition/places.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  ProfileState createState() => ProfileState();
}

class ProfileState extends State<Profile> {
  late String _firstName = '';
  late String _lastName = '';
  late String _profileImageUrl = '';
  late int _userId = 0;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getUserInfo();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('user_id') ?? 0;
      _firstName = prefs.getString('user_name') ?? '';
      _lastName = prefs.getString('user_surname') ?? '';
      _profileImageUrl = prefs.getString('user_image_url') ?? 'https://icons.veryicon.com/png/o/miscellaneous/two-color-icon-library/user-286.png';
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Профиль",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircleAvatar(
                backgroundImage: _profileImageUrl.isNotEmpty
                    ? NetworkImage(_profileImageUrl)
                    : null,
                child: _profileImageUrl.isEmpty
                    ? const Icon(Icons.person, size: 80)
                    : null,
              ),
            ),
            TextFormField(
              controller: _lastNameController,
              decoration:  InputDecoration(labelText: _lastName),
              onChanged: (value) {
                setState(() {
                  _lastName = value;
                });
              },
            ),
            TextFormField(
              controller: _firstNameController,
              decoration:  InputDecoration(labelText: _firstName),
              onChanged: (value) {
                setState(() {
                  _firstName = value;
                });
              },
            ),
            TextFormField(
              controller: _imageUrlController,
              decoration:  InputDecoration(labelText: _profileImageUrl),
              onChanged: (value) {
                setState(() {
                  _profileImageUrl = value;
                });
              },
              
            ),
            const SizedBox(width: 20, height: 20,),
            ElevatedButton(
              onPressed: () async {
                request("UPDATE users SET name = '$_firstName', surname = '$_lastName', image_url = '$_profileImageUrl' WHERE id = $_userId");
                SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                setState(() {
                      prefs.setString('user_name', _firstName);
                      prefs.setString('user_surname', _lastName);
                      prefs.setString('user_image_url', _profileImageUrl);
                });
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
