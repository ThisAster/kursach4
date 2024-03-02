import 'package:flutter/material.dart';
import 'package:repetition/main.dart';
import 'package:repetition/places.dart';
import 'package:repetition/roomAccess.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoomsChoosePage extends StatefulWidget {
  final int placeId;
  const RoomsChoosePage({Key? key, required this.placeId}) : super(key: key);

  @override
  RoomsChoosePageState createState() => RoomsChoosePageState();
}

class RoomsChoosePageState extends State<RoomsChoosePage> {
  List<dynamic>? listOfRooms;
  @override
  void initState() {
    super.initState();
    fetchDataFromPostgres();
  }

  Future<void> fetchDataFromPostgres() async {
    final results = await request(
        "SELECT id, name, price, open, image FROM room WHERE place_id = ${widget.placeId} ORDER BY open DESC");
    setState(() {
      listOfRooms = results
          .map((row) => {
                "id": row[0] as int,
                "name": row[1] as String,
                "price": row[2] as String,
                "open": row[3] as bool,
                "image": row[4] as String
              })
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Center(
          child: Text(
            "Комнаты",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
      body: Center(
        child: listOfRooms == null
            ? const CircularProgressIndicator() // Show loading indicator while fetching data
            : ListView.builder(
                itemCount: listOfRooms!.length,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 8.0), // Устанавливаем отступы вокруг ListTile
                    child: CustomRoomListItem(
                      roomId:  listOfRooms![index]['id'],
                      roomName: listOfRooms![index]['name'],
                      price: listOfRooms![index]['price'],
                      isOpen: listOfRooms![index]['open'], 
                      imageUrl: listOfRooms![index]['image'],
                   
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class CustomRoomListItem extends StatelessWidget {
  final int roomId;
  final String roomName;
  final String price;
  final bool isOpen;
  final String imageUrl;
  final VoidCallback? onTap;
  final VoidCallback? onRequestEntry;

  const CustomRoomListItem({
    Key? key,
    required this.roomId, 
    required this.roomName,
    required this.price,
    required this.isOpen,
    required this.imageUrl,
    this.onTap,
    this.onRequestEntry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        fit: BoxFit.fill,
                        image: NetworkImage(imageUrl),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            roomName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$price\n''Доступно: $isOpen',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 0,30,0),
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!isOpen) {
                        // Кнопка серая и открывает уведомление при нажатии
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Уведомление'),
                              content: const Text('Комната недоступна.'),
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
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        bool userBanned = prefs.getBool('user_banned') ?? false;
                        String userRole = prefs.getString('user_role') ?? '';
                        int userId = prefs.getInt('user_id') ?? 0;
                        prefs.setString('roomName', roomName);
                        prefs.setInt('roomId', roomId);
                        if (userBanned == true) {
                          // ignore: use_build_context_synchronously
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Бан'),
                                content: const Text('Аккаунт заблокирован.'),
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
                            // ignore: use_build_context_synchronously
                            Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),);
                        }        
                        else if (userRole == 'admin' || userRole == 'owner') {
                          // ignore: use_build_context_synchronously
                          Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RoomAccess(),
                        ),
                      );
                
                        } else {

                          request("INSERT INTO requests(user_id, room_id, status) VALUES ($userId, $roomId, 'req')");

                          // ignore: use_build_context_synchronously
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Уведомление'),
                                content: const Text('Запрос на вход был отправлен.'),
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
                      }
                    },
                    // ignore: sort_child_properties_last
                    child: const Icon(Icons.arrow_forward),
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      // Если комната недоступна, кнопка серая
                      // ignore: deprecated_member_use
                      primary: isOpen ? null : Colors.blueGrey,
                      
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
