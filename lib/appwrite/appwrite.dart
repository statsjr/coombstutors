import 'package:appwrite/appwrite.dart';

class Appwrite {
  Client client = Client().setProject("6717d750002f252ef2a4");
  Appwrite() {
      client
            .setEndpoint('https://cloud.appwrite.io.v1')
            .setProject('coombstutors');
  }
}
