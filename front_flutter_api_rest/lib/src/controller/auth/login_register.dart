import 'dart:convert';

import 'package:front_flutter_api_rest/src/controller/auth/ShareApiTokenController.dart';
import 'package:front_flutter_api_rest/src/model/auth/AuthRequestModel.dart';
import 'package:front_flutter_api_rest/src/model/auth/AuthResponseModel.dart';
import 'package:front_flutter_api_rest/src/model/auth/RegisterRequestModel.dart';
import 'package:front_flutter_api_rest/src/model/auth/RegisterResponseModel.dart';
import 'package:front_flutter_api_rest/src/providers/provider.dart';

import 'package:http/http.dart' as http;

class LoginRegisterController {
  static var client = http.Client();

  static Future<bool> login(AuthRequestModel model) async {
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
    };
    var urls = Providers.provider();
    var urlString = urls['loginProvider']!;
    var url = Uri.parse(urlString);
    //var url = Uri.http(ConfigApi.apiURL, ConfigApi.loginAPI);

    var response = await client.post(
      url,
      headers: requestHeaders,
      body: jsonEncode(model.toJson()),
    );
    if (response.statusCode == 200) {
      final authResponse = authResponseJson(response.body);

      // Agrega esta línea para imprimir el token en la consola
      print('Token obtenido en el inicio de sesión: ${authResponse.token}');
      // Convierte el objeto del usuario en una representación de cadena y luego imprímelo
      final userAsString = authResponse.user != null
          ? authResponse.user!.toJson().toString()
          : "Usuario no disponible";
      print('Usuario obtenido en el inicio de sesión: $userAsString');
      await ShareApiTokenController.setLoginDetails(authResponse);

      return true;
    } else {
      return false;
    }
  }

  static Future<RegisterResponseModel> register(
      RegisterRequestModel model) async {
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
    };
    var urls = Providers.provider();
    var urlString = urls['registerProvider']!;
    var url = Uri.parse(urlString);
   // var url = Uri.http(ConfigApi.apiURL, ConfigApi.registerAPI);

    try {
      var response = await client.post(
        url,
        headers: requestHeaders,
        body: jsonEncode(model.toJson()),
      );

      return registerResponseModel(response.body);
    } catch (error) {
      // En caso de error, lanzar una excepción con el mensaje de error.
      throw Exception("Error en el registro: $error");
    }
  }

  static Future<List<String>> getUserProfile() async {
    var loginDetails = await ShareApiTokenController.loginDetails();
    Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'Authorization': 'Basic ${loginDetails!.token}',
    };
    var urls = Providers.provider();
    var urlString = urls['userListProvider']!;
    var url = Uri.parse(urlString);


    var response = await client.get(
      url,
      headers: requestHeaders,
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final List<String> emails = jsonData.map((dynamic item) {
        return item["email"]
            .toString();
      }).toList();

      return emails;
    } else {
      return [];
    }
  }
}
