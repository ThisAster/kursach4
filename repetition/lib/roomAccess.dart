
import 'package:flutter/material.dart';
import 'package:repetition/places.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoomAccess extends StatefulWidget {
  const RoomAccess({Key? key}) : super(key: key);

  @override
  RoomAccessState createState() => RoomAccessState();
}

class RoomAccessState extends State<RoomAccess> {
  List<dynamic>? listOfReq;

  String roomName = 'Unknown Room';
  int roomId = 0;

  @override
  void initState() {
    super.initState();
    fetchRoomName();
    fetchDataFromPostgres();
    
    
  }

  Future<void> fetchRoomName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      roomName = prefs.getString('roomName') ?? 'Unknown Room';
      roomId = prefs.getInt('roomId') ?? 0;
    });
  }

  Future<void> fetchDataFromPostgres() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    roomId = prefs.getInt('roomId') ?? 0;
    final results = await request(
        "SELECT requests.user_id, requests.room_id, users.name, users.surname, users.balance, requests.id FROM requests JOIN users ON (requests.user_id = users.id) WHERE room_id = $roomId AND requests.status = 'req';");
    setState(() {
      listOfReq = results
          .map((row) => {
                "user_id": row[0] as int,
                "room_id": row[1] as int,
                "user_name": row[2] as String,
                "user_surname": row[3] as String,
                "user_balance": row[4] as int,
                "req_id": row[5] as int
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
        title: Text(
          roomName,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: (listOfReq == null || listOfReq!.isEmpty)
          ? const Center(child: Text("Запросов на аренду нет"))
          : ListView.builder(
              itemCount: listOfReq!.length,
              itemBuilder: (BuildContext context, int index) {
                final req = listOfReq![index];
                return CustomRoomRequestItem(
                  userName: '${req["user_name"]} ${req["user_surname"]}',
                  userBalance: req["user_balance"],
                  onApprove: () {
                    request("UPDATE requests SET status = 'accept' WHERE id = ${req['req_id']}");
                   showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Пользователь допущен'),
                              content: const Text('Пользователь начал аренду зала'),
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
                  },
                  onReject: () {
                    request("UPDATE requests SET status = 'deny' WHERE id = ${req['req_id']}");
                   showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Отклонено'),
                              content: const Text('Запрос на аренду зала отклонен'),
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
                      
                  },
                  onBan: (){
                    request("UPDATE users SET banned = true WHERE id = ${req['user_id']}");
                    request("UPDATE requests SET status = 'end' WHERE id = ${req['req_id']}");
                    showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Бан'),
                              content: const Text('Пользователь забанен.'),
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
                  },
                );
              },
            ),
    );
  }
}

class CustomRoomRequestItem extends StatelessWidget {
  final String userName;
  final int userBalance;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onBan;


  const CustomRoomRequestItem({
    Key? key,
    required this.userName,
    required this.userBalance,
    required this.onApprove,
    required this.onReject,
    required this.onBan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.block),
            onPressed: onBan,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 20, width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Баланс: $userBalance₽'),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: onApprove,
            color: Colors.green,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: const Color.fromARGB(255, 235, 106, 97),
            onPressed: onReject,
          ),
          
        ],
      ),
    );
  }
}
