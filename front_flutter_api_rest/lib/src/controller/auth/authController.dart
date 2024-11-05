// ignore: file_names
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:front_flutter_api_rest/src/model/auth/AuthModel.dart';

import 'package:http/http.dart' as http;
import 'package:front_flutter_api_rest/src/providers/provider.dart';

class UsuarioController {

  Future<List<dynamic>> getDataUsuario({String? name}) async {
    try {
      final urls = Providers.provider();
      String urlString = urls['userListProvider']!;

      if (name != null && name.isNotEmpty) {
        urlString += '/buscar?name=$name';
      }

      final url = Uri.parse(urlString);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  Future<http.Response> crearUsuario(UsuarioModel nuevoUsuario) async {
    final urls = Providers.provider();
    final urlString = urls['registerProvider']!;
    final url = Uri.parse(urlString);

    final body = jsonEncode(nuevoUsuario.toJson());

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Usuario creado: ${response.body}');
    } else {
      print(
          'Error al crear Usuario: ${response.statusCode} - ${response.body}');
    }
    return response;
  }

  Future<http.Response> editarUsuario(UsuarioModel usuarioEditado) async {
    final urls = Providers.provider();
    final urlString = urls['authUserListProvider']!;
    final url = Uri.parse(urlString);

    final body = jsonEncode(usuarioEditado.toJson());

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      print('usuario editado: ${response.body}');
    } else {
      print(
          'Error al editar usuario: ${response.statusCode} - ${response.body}');
    }

    return response;
  }

  Future<http.Response> removeUsuario(int id, String fotoURL) async {
    final urls = Providers.provider();
    final urlString = urls['authUserListProvider']!;
    final url = Uri.parse('$urlString/delete/$id');

    var response = await http.delete(
      url,
      headers: {"Content-Type": "application/json"},
    );
   
    if (fotoURL.isNotEmpty &&
        (fotoURL.startsWith('gs://') || fotoURL.startsWith('https://'))) {
   
      try {
        await FirebaseStorage.instance.refFromURL(fotoURL).delete();
        print("Imagen eliminada de Firebase Storage");
      } catch (e) {
        print("Error al eliminar la imagen: $e");
      }
    }

    print("Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    return response;
  }
}
