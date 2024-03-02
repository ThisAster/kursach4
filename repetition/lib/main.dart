import 'package:flutter/material.dart';
import 'package:repetition/places.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Авторизация',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 73, 142, 197),
          primary: const Color.fromARGB(255, 91, 161, 219),
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Авторизация')),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  String username = _usernameController.text;
                  String password = _passwordController.text;

                  final result = await request(
                      "SELECT user_id, user_name, user_surname, user_banned, user_role, user_balance, user_image_url  FROM user_login('$username', '$password');");
                  if (result.isNotEmpty) {
                    if (result[0][3] == true) {
                      // ignore: use_build_context_synchronously
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Бан'), // Заголовок уведомления
                            content: const Text(
                                'Ваш аккаунт был заблокирован.'), // Текст уведомления
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Закрыть'),
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      prefs.setInt('user_id', result[0][0]);
                      prefs.setString('user_name', result[0][1]);
                      prefs.setString('user_surname', result[0][2]);
                      prefs.setBool('user_banned', result[0][3]);
                      prefs.setString('user_role', result[0][4]);
                      prefs.setInt('user_balance', result[0][5]);
                      prefs.setString('user_image_url', result[0][6]);
                      // ignore: use_build_context_synchronously
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PlaceList(),
                        ),
                      );
                    }
                  } else {
                    // ignore: use_build_context_synchronously
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title:
                              const Text('Внимание'), // Заголовок уведомления
                          content: const Text(
                              'Был введен неверный логин и/или пароль'), // Текст уведомления
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Закрыть'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: const SizedBox(
                    width: 300,
                    height: 80,
                    child: Center(child: Text('Login'))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
