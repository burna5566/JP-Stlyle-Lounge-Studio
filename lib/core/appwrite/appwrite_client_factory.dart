import 'package:appwrite/appwrite.dart';

import 'appwrite_config.dart';

class AppwriteClientFactory {
  AppwriteClientFactory(this.config);

  final AppwriteConfig config;

  Client createClient() {
    final client = Client();

    client
        .setEndpoint(config.endpoint)
        .setProject(config.projectId)
        .setSelfSigned(status: false);

    return client;
  }

  Account createAccount() => Account(createClient());

  Databases createDatabases() => Databases(createClient());

  TablesDB createTablesDb() => TablesDB(createClient());

  Functions createFunctions() => Functions(createClient());

  Storage createStorage() => Storage(createClient());
}
