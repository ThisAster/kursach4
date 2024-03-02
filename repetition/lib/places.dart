import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:repetition/profile.dart';
import 'package:repetition/rooms.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<dynamic> request(String req) async {
    final conn = await Connection.open(
      Endpoint(
        host: '10.0.2.2',
        port: 5432,
        database: 'postgres',
        username: 'postgres',
        password: 'postgres',
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );
    final result = await conn.execute(req);
    await conn.close();
    return result;
  
}

class PlaceList extends StatelessWidget {
  const PlaceList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Репетиции',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 73, 142, 197),
          primary: const Color.fromARGB(255, 91, 161, 219),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Репетиции'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<dynamic>? listOfPlaces;
  bool isLoading = false;
  String userImageUrl = "";
  
  @override
  void initState() {
    super.initState();
    fetchDataFromPostgres();
    getUserPhoto();
  }

  Future<void> getUserPhoto() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userImageUrl = prefs.getString('user_image_url') ?? 'https://icons.veryicon.com/png/o/miscellaneous/two-color-icon-library/user-286.png';
    });
  }

  Future<void> fetchDataFromPostgres() async {
    final results =
        await request("SELECT id, image, name, address, price FROM place");
    setState(() {
      listOfPlaces = results
          .map((row) => {
                "id": row[0] as int,
                "image": row[1] as String,
                "name": row[2] as String,
                "address": row[3] as String,
                "price": row[4] as String,
              })
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Row(
      
          children: [
            const SizedBox(width: 20, height: 20), Center(
            child: Text(
              widget.title,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const Spacer(),
          Center(
            child: InkWell(
                  onTap: () {Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Profile(),
                            ),
                          );},
                  child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    image: NetworkImage(userImageUrl),
                  ),
                ),
              ),),
          ),
          ],
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!isLoading &&
              scrollInfo.metrics.pixels ==
                  scrollInfo.metrics.maxScrollExtent) {
            setState(() {
              isLoading = true;
              getUserPhoto();
            });
            fetchDataFromPostgres().then((_) {
              setState(() {
                isLoading = false;
              });
            });
            return true;
          }
          return false;
        },
        child: Center(
          child: listOfPlaces == null
              ? const CircularProgressIndicator()
              : ListView.builder(
                  itemCount: listOfPlaces!.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: CustomImageListItem(
                        imageUrl: listOfPlaces![index]['image'],
                        title: listOfPlaces![index]['name'],
                        subtitle:
                            '${listOfPlaces![index]['address']}, ${listOfPlaces![index]['price']}',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoomsChoosePage(
                                placeId: listOfPlaces![index]['id'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class CustomImageListItem extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const CustomImageListItem({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    this.onTap,
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
                      title ,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
